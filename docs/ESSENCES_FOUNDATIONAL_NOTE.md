# ORA Essences - Foundational Note

## Compressed behavioral micro-modules for runtime routing and output shaping

**Version:** 0.1 - Foundational note  
**Author:** Xavier Fleriag / Twins Productions  
**Status:** Concept consolidation  
**Scope:** ORA Essences only

---

## 1. Executive summary

An **ORA Essence** is a compressed behavioral unit.

It is not a full module, not a prompt, and not a persona by itself.

It is a small injectable behavior that can influence routing, output shaping, compression, audit, truth discipline, creativity, profile framing or minimal action selection.

Core formula:

```text
Essence = compressed behavior + priority + dependencies + token weight
```

Short form:

```text
Essence = injectable behavioral micro-module
```

In the runtime, essences are seeded through:

```text
ora-core-backend/src/essences/essences.seed.json
```

---

## 2. Why essences exist

Full modules are useful for architecture.

Prompts are useful for immediate instructions.

Essences exist between both.

They provide reusable behavioral signals such as:

```text
clarify reasoning
protect truth
compress tokens
control creativity
score decisions
normalize contracts
frame profiles
compose visual layers
map business intent
compile artifacts
trace active behavior
stop reasoning loops
```

Essences make behavior more modular, compressible and auditable.

---

## 3. Essence vs GPV2 module

A GPV2 module defines architectural position.

An essence defines compressed behavior.

Example:

```text
M06_RIME = architectural module
rime-core-clarity = injectable essence associated with RIME behavior
```

Canonical distinction:

```text
GPV2 module = where the capability lives
Essence = how the behavior activates in compact form
```

---

## 4. Essence vs prompt

A prompt is usually a one-time instruction.

An essence is reusable behavioral logic.

```text
Prompt = do this now
Essence = apply this behavior when relevant
```

Essences are designed to be selected, weighted, combined and audited.

---

## 5. Essence structure

A runtime essence can include:

```text
essenceId
moduleId
essenceType
targetOutputs
priority
compressionLevel
injectableContent
dependencies
conflicts
tokenWeight
```

### essenceId

Unique identifier for the essence.

### moduleId

Associated module or behavior family.

### essenceType

Behavior category such as clarity, governance, compression, formatting, traceability or reasoning frame.

### targetOutputs

Output surfaces where the essence can be applied.

### priority

Selection weight. Higher priority means stronger activation preference.

### compressionLevel

How compact the essence should be when injected.

### injectableContent

Compact behavioral payload.

### dependencies

Other essences required or recommended before activation.

### conflicts

Essences that should not activate together, if any.

### tokenWeight

Approximate token cost or weight contribution.

---

## 6. Seed essences

The current seed registry includes:

```text
rime-core-clarity
primordia-truth-gate
ecotwin-token-sobriety
crea120-controlled-divergence
aura-mxb-decision-scorecard
gpl-exec-contract
arch-plus-profile-frame
vg-plus-visual-layers
soncas-business-tuning
ora-compiler-artifact-frame
halo-tracecore-ledger
essence-me-decision-compression
```

---

## 7. Core essence map

### RIME

```text
rime-core-clarity
```

Behavior:

```text
separate facts, hypotheses and suggestions
detect ambiguity
clarify constraints
downshift if uncertain
```

### PRIMORDIA

```text
primordia-truth-gate
```

Behavior:

```text
truth over comfort
no fake sources
mark uncertainty
block contradiction
safe redirect if needed
```

### ECOTWIN

```text
ecotwin-token-sobriety
```

Behavior:

```text
minimum sufficient output
avoid bloat
preserve task completion
qualitative energy discipline
```

### CREA120

```text
crea120-controlled-divergence
```

Behavior:

```text
generate variants under constraints
label hypotheses
novelty without overclaim
select actionable output
```

### AURA_MXB

```text
aura-mxb-decision-scorecard
```

Behavior:

```text
score boldness, safety, truth, iteration and cost
recommend GO, TEST, WAIT or NO
state primary risk
```

### GPL

```text
gpl-exec-contract
```

Behavior:

```text
normalize intent, constraints, route and output
compile as contract
keep human-machine readability
```

### ARCH_PLUS

```text
arch-plus-profile-frame
```

Behavior:

```text
define role, goal, tone, limits and personae
warn on tone-risk mismatch
profile-bound, not free roleplay
```

### VG_PLUS

```text
vg-plus-visual-layers
```

Behavior:

```text
compose layers, intent, camera and readability
digital clean rendering
no oil or canvas texture
canon lock
```

### SONCAS

```text
soncas-business-tuning
```

Behavior:

```text
map security, pride, novelty, comfort, money and sympathy
prioritize evidence, ROI and trust for SME contexts
```

### ORA_COMPILER

```text
ora-compiler-artifact-frame
```

Behavior:

```text
emit direct prompt, project markdown, master preferences
include token estimate
avoid raw module dump
```

### HALO_TRACECORE

```text
halo-tracecore-ledger
```

Behavior:

```text
trace active essences
trace decision owner
hash references only
mark metrics as estimated unless measured
emit audit event
```

### ESSENCE_ME

```text
essence-me-decision-compression
```

Behavior:

```text
monitor repeated reasoning after two cycles
detect no new information or tool gain
classify residual uncertainty
compress state into GOAL|KNOWN|UNKNOWN|BLOCKER|RISK|MIN_ACTION|STOP_RULE|CONFIDENCE
route to the minimal useful next action
avoid new hypotheses without new data
```

---

## 8. Essence routing

Essences can be chained to create behavior routes.

Examples:

```text
Translation: GPL > RIME > PRIMORDIA > ORA_COMPILER > HALO_TRACECORE
Compression: GPL > ECOTWIN > ESSENCE_ME
Validation: RIME > PRIMORDIA > HALO_TRACECORE
Visual: RIME > CREA120 > VG_PLUS
Business: AURA_MXB > SONCAS > PRIMORDIA
Minimal action: RIME > PRIMORDIA > ECOTWIN > ESSENCE_ME
```

Routes should remain short and purposeful.

---

## 9. Selection rules

Essence selection should consider:

```text
user intent
risk level
output type
need for truth validation
need for compression
need for creativity
need for artifact export
need for traceability
available context
```

Selection should avoid activating every essence by default.

Canonical rule:

```text
Activate the minimum useful essence set.
```

---

## 10. Validation criteria

An entry can be considered a valid essence if it has:

```text
1. a unique essenceId
2. a moduleId
3. a behavior type
4. a target output scope
5. a priority
6. a compression level
7. compact injectable content
8. dependencies and conflicts fields
9. a token weight
```

A behavior is not a proper essence if it is only:

```text
a long prompt
a persona description
a module file
a vague style preference
a decorative label
a non-auditable instruction
```

---

## 11. Limits

Essences do not guarantee perfect output.

They do not replace:

```text
source verification
runtime validation
user intent clarification
policy checks
tool execution
audit logs
```

Essences shape behavior. They do not prove facts.

---

## 12. Public short definition

English:

```text
An ORA Essence is a compressed behavioral micro-module.

It carries a reusable behavior with priority, dependencies, compression level, token weight and injectable content for runtime routing and output shaping.
```

French:

```text
Une Essence ORA est un micro-module comportemental compresse.

Elle porte un comportement reutilisable avec priorite, dependances, niveau de compression, poids token et contenu injectable pour le routage runtime et la structuration de sortie.
```

---

## 13. Conclusion

Essences are the behavioral atoms of ORA runtime.

They allow the system to route and shape behavior without always expanding full modules or long prompts.

Final formula:

```text
Module = architecture
Prompt = immediate instruction
Essence = compressed reusable behavior
```

And:

```text
Essence = micro-behavior + priority + dependencies + token weight + injectable content
```
