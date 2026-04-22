# Migration frontend vers ORA Core Backend

Objectif : retirer progressivement la logique metier de `App.tsx` sans casser le prototype React/Vite.

## Ce qui doit sortir de App.tsx

Constantes et blocs a migrer :

- `MODULE_DETAILS`
- `GITHUB_REPOS`
- `fetchModuleDetailsAsync`
- logique de recommandation commerciale/modules
- logique de resolution des essences operationnelles
- logique de compilation Grenaprompt/GPV2
- generation LLM cote client si elle existe
- generation brute de fichiers `.md`
- logique de token/cout si elle existe cote UI

Le frontend doit garder :

- composants UI ;
- formulaires ;
- etats de chargement ;
- affichage des modules/capacites ;
- bouton de telechargement ;
- rendu des sorties compilees.

## Phase 1 : endpoints lecture seule

Brancher sans supprimer l'ancien code.

1. Ajouter une variable Vite :

```env
VITE_ORA_BACKEND_URL=http://localhost:3333
```

2. Creer un client API frontend :

```ts
const API_BASE = import.meta.env.VITE_ORA_BACKEND_URL ?? "http://localhost:3333";

export async function getModules() {
  const res = await fetch(`${API_BASE}/modules`);
  return res.json();
}
```

3. Remplacer progressivement :

```text
MODULE_DETAILS -> GET /modules
GITHUB_REPOS -> GET /repos
fetchModuleDetailsAsync -> GET /modules/:id
capacites UI -> GET /capabilities?planId=free
plans -> GET /plans
essence audit technique -> GET /essences ou selection.resolvedEssences
```

Garder un fallback local si le backend est indisponible pendant la transition.

## Phase 2 : analyse, selection, estimation

Remplacer la logique de recommandation frontend par :

```text
POST /needs/analyze
POST /selection/resolve
POST /estimate/tokens
```

Flux recommande :

1. L'utilisateur saisit sa demande.
2. Le frontend appelle `/needs/analyze`.
3. Le frontend affiche les capacites recommandees.
4. L'utilisateur ajuste ses choix.
5. Le frontend appelle `/selection/resolve`.
6. Le frontend affiche modules autorises, modules bloques, essences resolues et upgrades.
7. Le frontend appelle `/estimate/tokens` pour afficher `TOK_EST≈X`.

## Phase 3 : compilation backend

Remplacer la compilation locale par :

```text
POST /compile/direct
POST /compile/md
POST /compile/master
```

Le backend renvoie :

- `content` : contenu compile ;
- `tokenEstimate` : estimation V1 basee sur les essences ;
- `selection` : modules/capacites/plans utilises ;
- `essences` : noyaux operationnels injectes, jamais descriptions brutes de modules.

Le frontend ne fait plus que :

- afficher `content` ;
- proposer copie ;
- declencher le telechargement `.md` avec le contenu recu.

## Phase 4 : provider LLM serveur optionnel

Supprimer toute cle LLM du frontend.

Si un provider externe devient necessaire, l'appel doit rester cote backend, par exemple :

```text
POST /llm/generate
```

Ou integrer le provider dans :

```text
POST /compile/direct
POST /compile/md
POST /compile/master
```

Regle : aucune cle LLM dans `App.tsx`, `.env` Vite ou bundle client.

## Ordre anti-casse

1. Ajouter le backend et le demarrer separement.
2. Ajouter le client API frontend avec fallback local.
3. Brancher `/health`.
4. Brancher `/modules` et `/modules/:id`.
5. Brancher `/repos`.
6. Brancher `/capabilities` et `/plans`.
7. Brancher `/needs/analyze`.
8. Brancher `/selection/resolve`.
9. Brancher `/estimate/tokens`.
10. Brancher `/essences` si le frontend doit afficher un audit technique.
11. Brancher `/compile/direct`.
12. Brancher `/compile/md` pour le telechargement.
13. Brancher `/compile/master`.
14. Retirer les constantes locales devenues inutiles.
15. Ajouter un provider LLM serveur seulement si le produit l'exige.

## Contrat de telechargement `.md`

Ancien mode :

```text
App.tsx genere le markdown et lance le download.
```

Nouveau mode :

```text
Backend genere `content`.
Frontend cree un Blob et lance le download.
```

Exemple frontend :

```ts
function downloadMarkdown(filename: string, content: string) {
  const blob = new Blob([content], { type: "text/markdown;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}
```

## Donnees sensibles

- Ne jamais exposer de cle LLM cote Vite.
- Ne pas exposer de logique de licence fiable uniquement cote client.
- Le frontend peut afficher les droits, mais la decision doit venir du backend.
- Le frontend ne doit pas devenir la source business des essences modules.