# ORA Core Backend

Backend Node.js/TypeScript V1 pour sortir la logique metier ORA du frontend React/Vite.

Cette V1 est volontairement progressive. Elle pose d'abord l'arborescence, les contrats API, les seeds, les schemas Zod, les services mockables et les endpoints REST. Elle ne cherche pas a construire toute la logique metier finale d'un coup.

## Objectif

Le frontend devient une couche UI :

- chat et formulaires ;
- cases a cocher de capacites visibles ;
- affichage des resultats ;
- copie et telechargements ;
- navigation et etats de chargement.

Le backend devient le cerveau metier :

- registry modules ORA ;
- registry essences operationnelles ;
- registry capacites visibles ;
- GitHub canon service prepare ;
- mapping capacites -> modules internes -> essences compilables ;
- orchestration besoin, plan, droits et dependances ;
- compilation direct prompt, markdown projet, master preferences ;
- estimation token explicite basee sur les essences ;
- centralisation future des providers LLM si le produit l'exige.

## Regle essence

Un module n'est pas compile comme un bloc brut.

- `module` = objet complet avec metadata, repo, compatibilites, dependances et documentation.
- `essence` = noyau fonctionnel minimal, compact, resolvable et injectable.
- Le compiler injecte les essences resolues, pas les descriptions longues des modules.
- Le frontend ne manipule jamais la logique brute des essences comme source business.

## Installation

```bash
npm install
cp .env.example .env
npm run dev
```

URL par defaut :

```text
http://localhost:3333
```

## Scripts

```bash
npm run dev        # serveur dev avec tsx
npm run build      # compilation TypeScript
npm run start      # execution dist/server.js
npm run typecheck  # verification TS sans emission
```

## Structure

```text
src/
  api/middleware/
  billing/
    plans.seed.json
    plan.registry.ts
  capabilities/
    capabilities.seed.json
    registry.ts
  config/
  essences/
    essences.seed.json
    registry.ts
  modules/
    manifests/modules.seed.json
    registry.ts
  routes/
  schemas/
  services/
  types/
  utils/
  app.ts
  server.ts
```

## Seeds V1

- `src/modules/manifests/modules.seed.json`
- `src/essences/essences.seed.json`
- `src/capabilities/capabilities.seed.json`
- `src/billing/plans.seed.json`

Ces fichiers remplacent progressivement les constantes hardcodees dans `App.tsx`.

## Contrats principaux

### Module

Chaque module contient :

- `id`
- `publicName`
- `internalName`
- `description`
- `fullDescription`
- `repoUrl`
- `category`
- `tier`
- `compatibleOutputs`
- `dependencies`
- `conflicts`
- `tokenCostWeight`
- `tags`
- `status`
- `validationState`
- `codeTemplate` optionnel

### Essence

Chaque essence contient :

- `essenceId`
- `moduleId`
- `essenceType`
- `targetOutputs`
- `priority`
- `compressionLevel`
- `injectableContent`
- `dependencies`
- `conflicts`
- `tokenWeight`

### Capability

Chaque capacite visible contient :

- `id`
- `label`
- `description`
- `mappedModules`
- `requiredPlan`
- `compatibleOutputs`
- `tags`
- `status`

La UI doit afficher les capacites, pas les noms internes des modules.

## Endpoints

### Phase 1

```http
GET /health
GET /repos
GET /modules
GET /modules/:id
GET /essences
GET /essences/:id
GET /essences/resolve/by-modules?moduleIds=rime,primordia&outputType=direct
GET /capabilities
GET /plans
```

### Phase 2

```http
POST /needs/analyze
POST /selection/resolve
POST /estimate/tokens
```

### Phase 3

```http
POST /compile/direct
POST /compile/md
POST /compile/master
```

### Endpoint prepare pour plus tard

```http
POST /repos/refresh
```

V1 renvoie un stub local. Le fetch GitHub distant sera branche ensuite.

## Sorties compilees

- `POST /compile/direct` renvoie `TOK_EST≈X`, Grenaprompt lisible, essences injectees et `GPV2_MIN`.
- `POST /compile/md` renvoie un markdown projet pret a telecharger cote frontend.
- `POST /compile/master` renvoie un bloc preferences compact avec `CORE=[essences minifiees]`.

`TOK_EST` est une estimation heuristique, pas une mesure absolue.

## Exemples

Analyse d'un besoin :

```bash
curl -X POST http://localhost:3333/needs/analyze \
  -H "Content-Type: application/json" \
  -d "{\"userRequest\":\"Cree un prompt ORA fiable avec export markdown pour une PME\"}"
```

Resolution de selection :

```bash
curl -X POST http://localhost:3333/selection/resolve \
  -H "Content-Type: application/json" \
  -d "{\"userRequest\":\"Mode consultant pour structurer une offre PME\",\"planId\":\"creator\",\"selectedCapabilityIds\":[\"consultant-mode\",\"sme-mode\"]}"
```

Compilation markdown :

```bash
curl -X POST http://localhost:3333/compile/md \
  -H "Content-Type: application/json" \
  -d "{\"userRequest\":\"Genere une config ORA projet\",\"planId\":\"creator\",\"selectedCapabilityIds\":[\"project-export\",\"strong-governance\"],\"title\":\"ORA Project\"}"
```

## GitHub canon service

`src/services/github.service.ts` prepare :

- liste des repos publics ORA ;
- lecture future des manifests publics ;
- projection registry locale ;
- refresh futur depuis GitHub public.

En V1, le mode reste `local-mock` pour eviter une dependance reseau dans le coeur.

## LLM provider

La V1 ne depend pas d'une IA generative native pour fonctionner. `llm.service.ts` est un stub serveur et ne fait aucun appel externe.

Configurer plus tard seulement si necessaire :

```env
LLM_PROVIDER=external
LLM_API_KEY=...
LLM_MODEL=...
```

Regle : aucune cle LLM dans le frontend, les `.env` Vite ou le bundle client.

## Regle de migration

Ne pas casser le prototype actuel. Le frontend peut continuer avec ses constantes pendant que les appels API sont branches route par route. Voir `MIGRATION.md`.