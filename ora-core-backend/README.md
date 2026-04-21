# ORA Core Backend

Backend Node.js/TypeScript V1 pour sortir la logique metier ORA du frontend React/Vite.

Cette V1 est volontairement mockee et progressive. Elle pose les contrats API, les seeds, les schemas Zod, les services et les endpoints. Elle ne deplace pas encore toute la logique Gemini ni tout le canon GitHub distant.

## Objectif

Le frontend doit devenir une couche UI :

- envoyer la demande utilisateur ;
- afficher modules et capacites ;
- afficher les sorties compilees ;
- declencher les telechargements ;
- ne plus porter la logique metier sensible.

Le backend devient le cerveau metier :

- registry modules ORA ;
- canon GitHub prepare ;
- mapping capacites -> modules internes ;
- orchestration par besoin, plan et dependances ;
- compilation direct prompt, markdown projet, master preferences ;
- estimation token explicite ;
- plans et droits ;
- centralisation future Gemini.

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
  capabilities/
  config/
  modules/
    manifests/
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
- `src/capabilities/capabilities.seed.json`
- `src/billing/plans.seed.json`

Ces fichiers remplacent progressivement les constantes hardcodees dans `App.tsx`.

## Endpoints

### Phase 1

```http
GET /health
GET /repos
GET /modules
GET /modules/:id
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

## Gemini cote backend

La cle Gemini ne doit plus etre exposee cote frontend.

Configurer plus tard :

```env
LLM_PROVIDER=gemini
GEMINI_API_KEY=...
GEMINI_MODEL=gemini-1.5-flash
```

Puis remplacer le stub dans `src/services/llm.service.ts` par l'appel SDK serveur.

## Regle de migration

Ne pas casser le prototype actuel. Le frontend peut continuer avec ses constantes pendant que les appels API sont branches route par route. Voir `MIGRATION.md`.
