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

$samplePath = Join-Path $PSScriptRoot '..\sample_payload.json'
$packet = Invoke-Gpv2Compile -Path $samplePath

Assert-True ($packet.HGOV.RiskLevel -eq 'MID') 'Expected HGOV risk level MID for sample payload.'
Assert-True ($packet.LETTER_BRIDGE.Status -eq 'VALID') 'Expected LETTER_BRIDGE status VALID.'
Assert-True ($packet.LETTER_BRIDGE.CanonicalLetters -eq 'GL-M|GL-Q|GL-D') 'Expected canonical letter bridge sequence.'
Assert-True ($packet.LETTER_BRIDGE.DerivedGlyphSequence -eq 'AON^|TRIA|NOVEN') 'Expected derived glyph sequence from letter bridge.'
Assert-True ($packet.GLYPH_UI.CanonicalSequence -eq 'AON^|TRIA|NOVEN') 'Expected GLYPH_UI canonical sequence to match letter bridge.'
Assert-True (($packet.GL | Where-Object { $_ -like 'UNSURE(key="glyph_registry_complete"*' }).Count -eq 1) 'Expected UNSURE for glyph_registry_complete.'
Assert-True (($packet.GL | Where-Object { $_ -eq 'STATE(name="LETTER_BRIDGE_STATUS",val="VALID")' }).Count -eq 1) 'Expected valid LETTER_BRIDGE state.'
Assert-True (($packet.GL_G | Where-Object { $_ -eq 'TAG(ns="BRIDGE",name="LETTER_PRESENT")' }).Count -eq 1) 'Expected GL_G letter bridge presence tag.'
Assert-True (($packet.GL_G | Where-Object { $_ -eq 'PACK(name="letter_tokens",val="GL-M|GL-Q|GL-D")' }).Count -eq 1) 'Expected letter token pack in GL_G.'
Assert-True (($packet.GL_G | Where-Object { $_ -eq 'PACK(name="letter_glyph_ascii",val="AON^|TRIA|NOVEN")' }).Count -eq 1) 'Expected letter bridge glyph pack in GL_G.'
Assert-True (($packet.GL_G | Where-Object { $_ -eq 'PACK(name="glyph_ascii",val="AON^|TRIA|NOVEN")' }).Count -eq 1) 'Expected glyph ASCII pack in GL_G.'
Assert-True ($packet.VALIDATION.Pass) ('Packet validation failed: ' + (($packet.VALIDATION.Issues -join '; ')))

$parsed = Parse-Gpv2Primitive 'FACT(key="alpha",val="beta",conf=1)'
Assert-True ($parsed.Name -eq 'FACT') 'Primitive parser failed on FACT name.'
Assert-True ($parsed.Arguments.key -eq 'alpha') 'Primitive parser failed on FACT key.'
Assert-True ($parsed.Arguments.val -eq 'beta') 'Primitive parser failed on FACT value.'

$expanded = Expand-Gpv2Packet -GlgLines $packet.GL_G
Assert-True (($expanded.GL -join "`n") -eq ($packet.GL -join "`n")) 'Roundtrip expansion from GL_G failed.'
Assert-True ($expanded.GlyphAscii -eq 'AON^|TRIA|NOVEN') 'Expanded packet lost glyph ASCII sequence.'
Assert-True ($expanded.LetterTokens -eq 'GL-M|GL-Q|GL-D') 'Expanded packet lost letter bridge tokens.'
Assert-True ($expanded.LetterGlyphAscii -eq 'AON^|TRIA|NOVEN') 'Expanded packet lost letter bridge glyph sequence.'

Write-Output 'TEST_PASS'
