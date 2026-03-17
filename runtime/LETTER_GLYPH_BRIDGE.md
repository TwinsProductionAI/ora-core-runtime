# LETTER_GLYPH_BRIDGE

## Objet

Ce fichier formalise le pont `GL-A..GL-Z <-> GL-01..GL-13` comme un registre backend exploitable.

## Principe cle

Ce bridge n'est pas une equivalence ontologique stricte.
C'est une resolution semantique controlee.

Autrement dit:

- `GL-A..GL-Z` porte une couche conceptuelle et operationnelle
- `GL-01..GL-13` porte une couche phonique et glyphique backend-safe
- le bridge choisit un meilleur fit primaire pour transporter le sens de facon stable

## Pourquoi ce choix est sain

Sans ce cadrage, le systeme risquait de confondre:

- alphabet conceptuel
- unites phonetiques
- symboles visuels

Le bridge impose une mediation explicite entre ces couches.

## Statut actuel

- statut: `PROVISIONAL`
- usage backend: autorise
- condition: toujours passer par la registry
- nature: semantic fit, pas identite exacte

## Effet runtime

Le backend peut maintenant:

- accepter une sequence `GL-A..GL-Z`
- la resoudre en sequence glyphique ASCII stable
- la propager en `GL` et `GL_G`
- verifier sa coherence avec un `GLYPH_UI` explicite

## Exemple

`GL-M | GL-Q | GL-D`

se resout en:

`AON^ | TRIA | NOVEN`

## Point important

Le champ `confidence` d'une entree du bridge exprime la force d'ajustement semantique du pont.
Il n'exprime pas une certitude de verite sur un fait du monde.
