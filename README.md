# ora-core-runtime

Runnable bootstrap runtime for ORA Core OS.

This repository contains the public runtime bundle for ORA Core OS technical modules: GPV2 parsing, GL/GL_G primitive handling, backend registries and services, ESSENCE_ME decision-compression runtime, H-NERONS governance, runnable samples, and PowerShell tests.

## Repository Role

Read this after [ora-core-os](https://github.com/TwinsProductionAI/ora-core-os) when you want executable material instead of architecture documents.

| Public order | Repository role |
| ---: | --- |
| 2 | Runtime code, samples, registries, and tests. |

## Scope

This repository is the publication-ready public bundle for:

- HGOV-aware runtime bootstrap
- GPV2 parsing and compilation
- GL and GL_G primitives handling
- ESSENCE_ME decision-compression backend runtime
- H-NERONS pre-emission factual governance runtime
- glyph registry and letter bridge registry
- PowerShell tests and runnable samples

## Why This Repo Is Public

These files are technical assets that benefit from:

- versioning
- peer review
- reproducibility
- external implementation and integration

## Included Material

- `runtime/gpv2_runtime.psm1`
- `runtime/gpv2_letter_bridge.ps1`
- `runtime/glyph_registry.json`
- `runtime/letter_glyph_bridge.json`
- `runtime/GLYPH_UI_REGISTRY.md`
- `runtime/LETTER_GLYPH_BRIDGE.md`
- `runtime/run_sample.ps1`
- `runtime/sample_payload.json`
- `runtime/sample_output.json`
- `runtime/modules/essence-me/*`
- `runtime/modules/h-nerons/*`
- `ora-core-backend/*`
- `tests/*.ps1`

## ESSENCE_ME Module

The `runtime/modules/essence-me` bundle provides:

- deterministic loop detection across recent reasoning cycles
- residual uncertainty classification into `data_missing`, `context_missing`, `reasoning_block`, `conflict`, `overcomplexity` or `low_value_continuation`
- one minimal next action selection instead of open-ended continuation
- a compact `GOAL|KNOWN|UNKNOWN|BLOCKER|RISK|MIN_ACTION|STOP_RULE|CONFIDENCE` state for backend orchestration
- a hashable trace suitable for HALO-aligned auditing
## H-NERONS Module

The `runtime/modules/h-nerons` bundle provides:

- claim detection on the final draft
- evidence qualification into `VERIFIED`, `PARTIALLY_VERIFIED`, `CONFLICT_DETECTED`, `UNSURE_EXTERNAL`, `UNSURE_EXPLICIT`
- bounded regeneration with GL and GL_G audit trace
- local evidence bundle support without mandatory live web access

## Quick Start

```powershell
powershell -ExecutionPolicy Bypass -File .\runtime\run_sample.ps1
powershell -ExecutionPolicy Bypass -File .\runtime\modules\h-nerons\run_sample.ps1
powershell -ExecutionPolicy Bypass -File .\tests\smoke_test.ps1
powershell -ExecutionPolicy Bypass -File .\tests\glyph_ui_registry_test.ps1
powershell -ExecutionPolicy Bypass -File .\tests\letter_bridge_test.ps1
powershell -ExecutionPolicy Bypass -File .\tests\h_nerons_runtime_test.ps1
```

## Public Repository Map

| Order | Repository | Role |
| ---: | --- | --- |
| 1 | [ora-core-os](https://github.com/TwinsProductionAI/ora-core-os) | Architecture and canonical module order. |
| 2 | `ora-core-runtime` | Runnable runtime and tests. |
| 3 | [ora-core-rag](https://github.com/TwinsProductionAI/ora-core-rag) | Retrieval layer and RAG Governor. |
| 4 | [ora-core-specs](https://github.com/TwinsProductionAI/ora-core-specs) | Technical specifications. |

## Deliberately Excluded

This public repo does not include:

- client-specific PME playbooks
- ChatGPT Projects deployment packs
- private project instructions for client delivery
- commercial onboarding material
- brand-sensitive service collateral

## Current Status

This is still a bootstrap runtime. It is useful, testable and publishable, but not yet a fully industrialized product runtime.

## Next Steps

- add richer HGOV policies
- replace the canonical base64 snapshot with tighter semantic compression
- add persistent cache and memory policies
- port from bootstrap form to a versioned runtime package

## License

Code and technical runtime material in this repository are released under Apache 2.0. See `LICENSE` and `NOTICE`.

Trademark, branding and visual identity rights are not granted. See `TRADEMARKS.md`.
