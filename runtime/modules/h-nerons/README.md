# MODULE_H_NERONS_V1_0

Public runtime bundle for `H-NERONS`, the pre-emission factual governance module of `Ora_Core_Os`.

## Included material

- `MODULE_H_NERONS_MANIFEST_V1_0_0.json`
  Machine-readable runtime manifest.
- `h_nerons_runtime.psm1`
  PowerShell runtime for claim detection, qualification, regulation and GL / GL_G trace generation.
- `sample_payload.json`
  Demonstration payload with local evidence injection.
- `MODULE_H_NERONS_GPV2_v1.0.0.json`
  Local public spec copy used by the runtime for standalone loading.
- `../../../tests/h_nerons_runtime_test.ps1`
  Regression test covering `VERIFIED`, `CONFLICT_DETECTED`, `UNSURE_EXPLICIT`, `PARTIALLY_VERIFIED` and query-term redaction.

## What the runtime does

- segments a final draft into candidate claims
- detects verifiable factual assertions
- classifies claims by minimal type
- applies a weighted source policy
- qualifies each claim into `VERIFIED`, `PARTIALLY_VERIFIED`, `CONFLICT_DETECTED`, `UNSURE_EXTERNAL` or `UNSURE_EXPLICIT`
- downgrades the final formulation when verification is insufficient
- generates a backend `GL` and `GL_G` trace with GPV2 hash reuse

## Deliberate limit

This public runtime does not perform native live web lookup by itself.
It expects an `EXTERNAL_EVIDENCE` bundle injected by an orchestrator, connector or test harness.

## Usage

```powershell
powershell -ExecutionPolicy Bypass -NoProfile -File .\runtime\modules\h-nerons\run_sample.ps1
```

## Local test

```powershell
powershell -ExecutionPolicy Bypass -NoProfile -File .\tests\h_nerons_runtime_test.ps1
```
