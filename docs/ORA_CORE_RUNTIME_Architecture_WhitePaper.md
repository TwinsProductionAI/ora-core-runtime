# WHITE PAPER - ORA CORE RUNTIME

Version 1.0 - Avril 2026  
Repository: `TwinsProductionAI/ora-core-runtime`  
Status: public runtime architecture white paper

## Resume executif

ORA Core Runtime est la couche executable de l'ecosysteme ORA Core OS. Elle transforme une architecture documentaire en composants testables: parsing GPV2, primitives GL/GL_G, registres, modules backend, exemples, tests et premieres formes de gouvernance operationnelle.

Le probleme central est le passage entre une architecture de prompts et un systeme qui peut etre execute, teste, versionne et inspecte. Une idee d'architecture peut sembler solide dans un document, mais elle devient defendable seulement lorsqu'elle possede des contrats, des exemples, des entrees, des sorties et des tests de regression.

ORA Core Runtime occupe donc la zone entre specification et produit: ce n'est pas encore un runtime industriel complet, mais c'est la premiere couche publique ou ORA devient manipulable par code.

## 1. Probleme vise

Les architectures LLM souffrent souvent d'un ecart entre intention et execution:

- les prompts promettent un comportement, mais aucun test ne le verifie;
- les modules sont nommes, mais leurs entrees et sorties restent floues;
- les traces sont demandees, mais aucun format stable n'existe;
- les fichiers de specification ne prouvent pas que le systeme peut tourner;
- les changements cassent la coherence sans detection.

ORA Core Runtime repond a cet ecart en introduisant des artefacts executables et des tests simples. Le but n'est pas d'industrialiser trop vite, mais de rendre les concepts falsifiables.

## 2. Definition

ORA Core Runtime est un bundle technique contenant des composants executables, des registres, des modules runtime et des tests pour les briques publiques d'ORA Core OS.

Il peut inclure:

- parsing et manipulation GPV2;
- primitives GL et GL_G;
- registres glyphiques et ponts lettres/glyphes;
- modules backend comme ESSENCE_ME;
- module runtime H-NERONS;
- exemples d'entree/sortie;
- tests PowerShell ou autres tests de smoke/regression;
- contrats de sortie minimaux.

Il ne doit pas etre confondu avec:

- le depot d'architecture principal;
- un produit SaaS complet;
- un orchestrateur multi-client;
- un moteur de verite autonome;
- une preuve definitive de performance.

## 3. Architecture conceptuelle

```text
Specification ORA
  -> fichiers GPV2 / GL / GL_G
  -> runtime parser / registry
  -> modules executables
  -> sample payload
  -> sample output
  -> tests
  -> audit minimal
```

Cette architecture oblige chaque module a declarer son comportement observable. Le runtime est le lieu ou les idees commencent a devoir survivre a l'execution.

## 4. GPV2 parsing

GPV2 sert de transport semantique. Dans le runtime, il doit devenir plus qu'un format visuel: il doit pouvoir etre lu, valide, transforme et teste.

Un parser GPV2 utile doit permettre:

- extraction de champs;
- validation minimale de structure;
- detection de champs manquants;
- preparation d'un payload pour modules;
- serialization stable;
- comparaison entre versions.

La rigueur du parser influence directement la maintenabilite du systeme. Si GPV2 reste seulement textuel, les modules aval peuvent deriver.

## 5. GL et GL_G

GL et GL_G sont traites comme des couches de transport symbolique et semantique. Le runtime doit distinguer:

- les representations destinees a l'humain;
- les formes plus compactes ou executables;
- les glyphes utiles comme interface ou trace;
- les donnees normatives qui influencent vraiment le systeme.

Cette distinction evite de faire porter a la couche visuelle une autorite qu'elle ne possede pas. Le runtime doit privilegier les champs structurants et les traces stables.

## 6. ESSENCE_ME

ESSENCE_ME est un module de compression decisionnelle. Sa fonction est de limiter les boucles d'incertitude et les depenses cognitives inutiles. Lorsqu'un systeme repete, hesite ou amplifie un raisonnement sans gain, ESSENCE_ME doit condenser l'etat:

```text
GOAL | KNOWN | UNKNOWN | BLOCKER | RISK | MIN_ACTION | STOP_RULE | CONFIDENCE
```

Ce format aide un orchestrateur a choisir la prochaine action minimale plutot que de continuer a produire du texte. Il sert autant l'efficience que la clarte.

## 7. H-NERONS runtime

La version runtime de H-NERONS transforme le whitepaper de gouvernance factuelle en logique operationnelle minimale:

- detection de claims;
- qualification;
- statut de verification;
- sortie bornee;
- trace.

Dans cette couche, l'objectif n'est pas encore de couvrir tous les cas du monde reel. L'objectif est de prouver que le pattern `detect -> qualify -> bound` peut etre execute avec des contrats simples.

## 8. Registres

Les registres sont essentiels pour eviter les conventions invisibles. Un registre peut documenter:

- glyphes autorises;
- correspondances lettres/glyphes;
- modules disponibles;
- versions;
- chemins d'appel;
- schemas;
- exemples.

Sans registre, chaque module risque d'inventer sa propre interpretation. Avec registre, l'ecosysteme devient plus auditable.

## 9. Tests et falsifiabilite

Un runtime public doit accepter d'etre teste. Les tests doivent couvrir au minimum:

- execution des samples;
- stabilite des sorties attendues;
- presence des champs critiques;
- non-regression des modules;
- erreurs propres lorsque les entrees sont invalides.

La qualite d'ORA Core Runtime ne doit pas etre jugee seulement par son ambition, mais par sa capacite a echouer clairement.

## 10. Cas d'usage

ORA Core Runtime peut servir a:

- demontrer les modules ORA dans un environnement local;
- tester des specs avant publication;
- fournir un socle a Codex ou a un developpeur humain;
- generer des outputs reproductibles;
- verifier qu'un changement ne casse pas les contrats;
- preparer l'integration avec ORA Core RAG ou ORA Companion Console.

## 11. Limites

Le runtime actuel doit etre presente avec prudence:

- il reste un bootstrap;
- il ne remplace pas une plateforme enterprise;
- il ne couvre pas encore toutes les politiques de securite;
- il ne garantit pas une gouvernance parfaite;
- il doit etre renforce par schemas, CI, logs et tests plus complets.

La valeur actuelle est la transition de l'idee vers l'executable.

## 12. Roadmap conseillee

1. Formaliser les schemas d'entree/sortie par module.
2. Ajouter tests unitaires et tests de regression cross-module.
3. Publier des exemples reproductibles par cas d'usage.
4. Ajouter CI GitHub Actions.
5. Introduire une interface d'appel stable.
6. Connecter le runtime au RAG Governor.
7. Preparer une version packagee et semver.

## Conclusion

ORA Core Runtime est le banc d'essai executable d'ORA Core OS. Il transforme une architecture cognitive en artefacts que l'on peut lancer, casser, corriger et versionner.

Sa valeur strategique est immense: sans runtime, ORA reste une architecture de documents; avec runtime, ORA commence a devenir une infrastructure testable.
