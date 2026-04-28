# MODULE_ESSENCE_ME_BACKEND_V1_0

Public runtime bundle for `ESSENCE_ME_BACKEND`, the decision-compression module of `Ora_Core_Os`.

## Included material

- `MODULE_ESSENCE_ME_MANIFEST_V1_0_0.json`
  Machine-readable runtime manifest.
- `MODULE_ESSENCE_ME_BACKEND_GPV2_v1.0.0.json`
  Local public spec copy for deterministic loop detection and minimal-action routing.
- `sample_payload.json`
  Demonstration payload for `/essence-me/analyze`.
- `../../../ora-core-backend/src/services/essence-me.service.ts`
  Backend deterministic runtime service.
- `../../../ora-core-backend/src/routes/essence-me.routes.ts`
  REST exposure for the runtime.

## What the runtime does

- reads the last reasoning cycles instead of hidden chain-of-thought
- detects repeated summaries, repeated questions and tool reuse without gain
- estimates whether recent analysis still produces new information
- classifies residual uncertainty into a bounded taxonomy
- selects exactly one minimal next action
- emits a compact state and a hashable trace

## Usage

```bash
curl -X POST http://localhost:3333/essence-me/analyze \
  -H "Content-Type: application/json" \
  -d @runtime/modules/essence-me/sample_payload.json
```