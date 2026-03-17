# ora-core-runtime

Public runtime bundle for the latest technical Ora_Core_Os modules.

## Scope

This repository is the publication-ready public bundle for:
- HGOV-aware runtime bootstrap
- GPV2 parsing and compilation
- GL and GL_G primitives handling
- glyph registry and letter bridge registry
- PowerShell tests and runnable samples

## Why this repo is public

These files are technical assets that benefit from:
- versioning
- peer review
- reproducibility
- external implementation and integration

## Included material

- `runtime/gpv2_runtime.psm1`
- `runtime/gpv2_letter_bridge.ps1`
- `runtime/glyph_registry.json`
- `runtime/letter_glyph_bridge.json`
- `runtime/GLYPH_UI_REGISTRY.md`
- `runtime/LETTER_GLYPH_BRIDGE.md`
- `runtime/run_sample.ps1`
- `runtime/sample_payload.json`
- `runtime/sample_output.json`
- `tests/*.ps1`

## Deliberately excluded

This public repo does not include:
- client-specific PME playbooks
- ChatGPT Projects deployment packs
- private project instructions for client delivery
- commercial onboarding material
- brand-sensitive service collateral

## License

Code and technical runtime material in this repository are released under Apache 2.0.
See `LICENSE` and `NOTICE`.

Trademark, branding and visual identity rights are not granted.
See `TRADEMARKS.md`.

## Current status

This is still a bootstrap runtime.
It is useful, testable and publishable, but not yet a fully industrialized product runtime.

## Quick start

```powershell
powershell -ExecutionPolicy Bypass -File .\runtime\run_sample.ps1
powershell -ExecutionPolicy Bypass -File .\tests\smoke_test.ps1
powershell -ExecutionPolicy Bypass -File .\tests\glyph_ui_registry_test.ps1
powershell -ExecutionPolicy Bypass -File .\tests\letter_bridge_test.ps1
```

## Next steps

- add richer HGOV policies
- replace the canonical base64 snapshot with tighter semantic compression
- add persistent cache and memory policies
- port from bootstrap form to a versioned runtime package
