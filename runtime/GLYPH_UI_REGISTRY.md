# GLYPH_UI_REGISTRY

## Objet

Ce fichier formalise `GLYPH_UI` comme un sous-systeme relie a `GPV2`, mais distinct du noyau backend.

## Regle d'architecture

Le backend ne depend jamais d'un glyphe visuel brut.

Il depend seulement de:

- `glyph_registry.json`
- un `ASCII_ALIAS`
- un statut `BACKEND_SAFE=true`

## Champs de registre

Chaque entree porte:

- `GLYPH_ID`
- `ASCII_ALIAS`
- `DISPLAY_NAME`
- `PHON`
- `SEMANTIC_ROLE`
- `CATEGORY`
- `ALLOWED_MODIFIERS`
- `BACKEND_SAFE`
- `UI_ONLY`
- `NORMATIVE_STATUS`

## Politique actuelle

- `GL-01` a `GL-05`, `GL-09` et `GL-13` sont traites comme coeur canonique.
- `GL-06`, `GL-07`, `GL-08` sont presents mais encore marques `PROVISIONAL`.
- `ACOUE`, `GRIGUVE`, `CONTINU`, `SOURCE_NODE`, `CENTRE` restent `UI_ONLY`.

## Pourquoi cette separation est bonne

Elle permet:

- de garder la richesse visuelle
- de ne pas laisser le backend dependre d'une ambiguite graphique
- d'ajouter progressivement des glyphes au runtime une fois leurs regles stabilisees

## Effet runtime

Si `required_for_backend=true` et qu'un glyphe `UI_ONLY` apparait, la compilation echoue.

Si `required_for_backend=false`, le systeme peut garder la sequence comme couche visuelle optionnelle, mais elle ne gouverne pas le backend.
