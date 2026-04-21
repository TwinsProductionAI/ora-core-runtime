# Migration frontend vers ORA Core Backend

Objectif : retirer progressivement la logique metier de `App.tsx` sans casser le prototype React/Vite.

## Ce qui doit sortir de App.tsx

Constantes et blocs a migrer :

- `MODULE_DETAILS`
- `GITHUB_REPOS`
- `fetchModuleDetailsAsync`
- logique de recommandation commerciale/modules
- logique de compilation Grenaprompt/GPV2
- generation Gemini cote client
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
```

Garder un fallback local si le backend est indisponible pendant la transition.

## Phase 2 : analyse, selection, estimation

Remplacer la logique de recommandation frontend par :

```text
POST /needs/analyze
POST /selection/resolve
POST /estimate/tokens
```

## Phase 3 : compilation backend

Remplacer la compilation locale par :

```text
POST /compile/direct
POST /compile/md
POST /compile/master
```

Le backend renvoie `content`, `tokenEstimate` et `selection`. Le frontend affiche, copie ou telecharge le contenu recu.

## Phase 4 : Gemini cote backend

Supprimer toute cle Gemini du frontend. Aucune cle LLM dans `App.tsx`, `.env` Vite ou bundle client.

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
10. Brancher `/compile/direct`.
11. Brancher `/compile/md` pour le telechargement.
12. Brancher `/compile/master`.
13. Retirer les constantes locales devenues inutiles.
14. Deplacer Gemini cote backend.

## Contrat de telechargement `.md`

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
