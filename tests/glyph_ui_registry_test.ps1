$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '..\gpv2_runtime.psm1') -Force

function Assert-True {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Condition,
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

$registry = Import-GlyphRegistry
Assert-True ($registry.Entries.Count -ge 15) 'Expected glyph registry to include the core phonetic units and UI operators.'
Assert-True ([string]$registry.META.STATUS -eq 'PARTIAL') 'Expected partial registry status.'

$safeSpec = Resolve-GlyphUiSpec -GlyphUi ([pscustomobject]@{
    profile = 'GLYPH_UI_V1'
    required_for_backend = $true
    sequence = @(
        [pscustomobject]@{ glyph_id = 'GL-01'; modifier = 'CIRCUMFLEX' },
        [pscustomobject]@{ glyph_id = 'GL-09' }
    )
})
Assert-True ($safeSpec.Status -eq 'VALID') 'Expected backend-safe glyph sequence to validate.'
Assert-True ($safeSpec.CanonicalSequence -eq 'AON^|NOVEN') 'Unexpected canonical glyph sequence.'

$blockedSpec = Resolve-GlyphUiSpec -GlyphUi ([pscustomobject]@{
    profile = 'GLYPH_UI_V1'
    required_for_backend = $true
    sequence = @('ACOUE')
})
Assert-True ($blockedSpec.Status -eq 'BLOCKED') 'Expected UI-only glyph to be blocked for backend-required usage.'
Assert-True (($blockedSpec.Issues | Where-Object { $_ -eq 'glyph_not_backend_safe:ACOUE' }).Count -eq 1) 'Expected backend-safe issue for ACOUE.'

$payload = Get-Content (Join-Path $PSScriptRoot '..\sample_payload.json') -Raw | ConvertFrom-Json
$payload.GLYPH_UI.sequence = @('ACOUE')
$payload.GLYPH_UI.required_for_backend = $true
$threw = $false
try {
    Invoke-Gpv2Compile -Payload $payload | Out-Null
}
catch {
    $threw = $true
    Assert-True ($_.Exception.Message -like 'GLYPH_UI backend validation failed*') 'Expected backend validation failure for UI-only glyph.'
}
Assert-True $threw 'Expected Invoke-Gpv2Compile to reject a UI-only glyph required by backend.'

Write-Output 'TEST_PASS'
