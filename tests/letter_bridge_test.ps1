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

$bridge = Import-LetterGlyphBridge
Assert-True ($bridge.Entries.Count -eq 26) 'Expected 26 GL-A..GL-Z bridge entries.'
Assert-True ([string]$bridge.META.STATUS -eq 'PROVISIONAL') 'Expected provisional bridge status.'

$resolved = Resolve-LetterBridgeSpec -LetterBridge ([pscustomobject]@{
    profile = 'LETTER_GLYPH_BRIDGE_V1'
    required_for_backend = $true
    sequence = @('GL-M','Q','D')
})
Assert-True ($resolved.Status -eq 'VALID') 'Expected valid letter bridge resolution.'
Assert-True ($resolved.CanonicalLetters -eq 'GL-M|GL-Q|GL-D') 'Expected canonical token normalization for bridge.'
Assert-True ($resolved.DerivedGlyphSequence -eq 'AON^|TRIA|NOVEN') 'Unexpected derived glyph sequence for bridge.'

$unknown = Resolve-LetterBridgeSpec -LetterBridge ([pscustomobject]@{
    profile = 'LETTER_GLYPH_BRIDGE_V1'
    required_for_backend = $true
    sequence = @('GL-UNKNOWN')
})
Assert-True ($unknown.Status -eq 'BLOCKED') 'Expected unknown letter bridge token to block backend-required resolution.'
Assert-True (($unknown.Issues | Where-Object { $_ -like 'unknown_letter_bridge:*' }).Count -eq 1) 'Expected unknown letter bridge issue.'

$payload = Get-Content (Join-Path $PSScriptRoot '..\sample_payload.json') -Raw | ConvertFrom-Json
$payload.GLYPH_UI.sequence = @([pscustomobject]@{ glyph_id = 'GL-05' })
$threw = $false
try {
    Invoke-Gpv2Compile -Payload $payload | Out-Null
}
catch {
    $threw = $true
    Assert-True ($_.Exception.Message -like 'LETTER_BRIDGE and GLYPH_UI mismatch*') 'Expected bridge mismatch failure.'
}
Assert-True $threw 'Expected compile to reject mismatched LETTER_BRIDGE and GLYPH_UI.'

Write-Output 'TEST_PASS'
