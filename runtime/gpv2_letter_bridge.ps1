$script:LetterBridgeCache = $null

function Get-LetterGlyphBridgePath {
    return Join-Path $PSScriptRoot 'letter_glyph_bridge.json'
}

function Import-LetterGlyphBridge {
    param([switch]$Force)

    if ($script:LetterBridgeCache -and -not $Force) {
        return $script:LetterBridgeCache
    }

    $path = Get-LetterGlyphBridgePath
    if (-not (Test-Path $path)) {
        throw "Letter bridge file not found: $path"
    }

    $raw = Get-Content -Path $path -Raw | ConvertFrom-Json
    $entries = @(Get-Gpv2Collection (Get-Gpv2OptionalValue -Container $raw -PropertyName 'entries' -Default @()))
    $byToken = @{}
    $byAlias = @{}
    foreach ($entry in $entries) {
        $tokenKey = Normalize-GlyphRegistryKey ([string](Get-Gpv2RequiredValue -Container $entry -PropertyName 'LETTER_TOKEN'))
        $aliasKey = Normalize-GlyphRegistryKey ([string](Get-Gpv2RequiredValue -Container $entry -PropertyName 'ASCII_ALIAS'))
        $byToken[$tokenKey] = $entry
        $byAlias[$aliasKey] = $entry
    }

    $script:LetterBridgeCache = [pscustomobject]@{
        META    = Get-Gpv2OptionalValue -Container $raw -PropertyName 'META'
        Entries = $entries
        ByToken = $byToken
        ByAlias = $byAlias
    }

    return $script:LetterBridgeCache
}

function Get-LetterGlyphBridgeEntry {
    param(
        [string]$LetterToken,
        [string]$AsciiAlias
    )

    $registry = Import-LetterGlyphBridge
    $tokenKey = Normalize-GlyphRegistryKey ([string]$LetterToken)
    $aliasKey = Normalize-GlyphRegistryKey ([string]$AsciiAlias)

    if (-not [string]::IsNullOrWhiteSpace($tokenKey)) {
        if ($registry.ByToken.ContainsKey($tokenKey)) {
            return $registry.ByToken[$tokenKey]
        }
        if (-not ($tokenKey -like 'GL-*') -and $registry.ByToken.ContainsKey(('GL-' + $tokenKey))) {
            return $registry.ByToken[('GL-' + $tokenKey)]
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($aliasKey) -and $registry.ByAlias.ContainsKey($aliasKey)) {
        return $registry.ByAlias[$aliasKey]
    }

    return $null
}

function Resolve-LetterBridgeSpec {
    param(
        $LetterBridge
    )

    if ($null -eq $LetterBridge) {
        return [pscustomobject]@{
            HasLetterBridge     = $false
            Profile             = $null
            RequiredForBackend  = $false
            Status              = 'ABSENT'
            CanonicalLetters    = ''
            DerivedGlyphSequence = ''
            DerivedGlyphTokens  = @()
            Issues              = @()
            Tokens              = @()
        }
    }

    $registry = Import-LetterGlyphBridge
    $profile = [string](Get-Gpv2OptionalValue -Container $LetterBridge -PropertyName 'profile' -Default 'LETTER_GLYPH_BRIDGE_V1')
    $requiredForBackend = [bool](Get-Gpv2OptionalValue -Container $LetterBridge -PropertyName 'required_for_backend' -Default $false)
    $sequence = @(Get-Gpv2Collection (Get-Gpv2OptionalValue -Container $LetterBridge -PropertyName 'sequence' -Default @()))
    $issues = New-Object System.Collections.Generic.List[string]
    $tokens = New-Object System.Collections.ArrayList
    $canonicalLetters = New-Object System.Collections.Generic.List[string]
    $derivedGlyphAliases = New-Object System.Collections.Generic.List[string]
    $derivedGlyphTokens = New-Object System.Collections.ArrayList

    foreach ($token in $sequence) {
        $letterToken = ''
        $asciiAlias = ''
        if ($token -is [string]) {
            $tokenText = [string]$token
            if ((Normalize-GlyphRegistryKey $tokenText) -like 'GL-*') {
                $letterToken = $tokenText
            }
            else {
                $asciiAlias = $tokenText
            }
        }
        else {
            $letterToken = [string](Get-Gpv2OptionalValue -Container $token -PropertyName 'letter_token' -Default '')
            $asciiAlias = [string](Get-Gpv2OptionalValue -Container $token -PropertyName 'ascii_alias' -Default '')
        }

        $entry = Get-LetterGlyphBridgeEntry -LetterToken $letterToken -AsciiAlias $asciiAlias
        if ($null -eq $entry) {
            $issues.Add(('unknown_letter_bridge:{0}{1}' -f $letterToken, $(if ($asciiAlias) { ':' + $asciiAlias } else { '' })))
            continue
        }

        $primary = Get-Gpv2RequiredValue -Container $entry -PropertyName 'PRIMARY_TARGET'
        $glyphId = [string](Get-Gpv2RequiredValue -Container $primary -PropertyName 'glyph_id')
        $glyphAlias = [string](Get-Gpv2RequiredValue -Container $primary -PropertyName 'ascii_alias')
        $defaultModifiers = @(Get-Gpv2Collection (Get-Gpv2OptionalValue -Container $primary -PropertyName 'default_modifiers' -Default @()))
        $glyphEntry = Get-GlyphRegistryEntry -GlyphId $glyphId -AsciiAlias $glyphAlias
        if ($null -eq $glyphEntry) {
            $issues.Add(('bridge_target_missing:{0}:{1}' -f [string]$entry.LETTER_TOKEN, $glyphId))
            continue
        }

        $backendSafe = [bool](Get-Gpv2OptionalValue -Container $glyphEntry -PropertyName 'BACKEND_SAFE' -Default $false)
        $uiOnly = [bool](Get-Gpv2OptionalValue -Container $glyphEntry -PropertyName 'UI_ONLY' -Default $true)
        if ($requiredForBackend -and ((-not $backendSafe) -or $uiOnly)) {
            $issues.Add(('letter_bridge_target_not_backend_safe:{0}:{1}' -f [string]$entry.LETTER_TOKEN, [string]$glyphEntry.ASCII_ALIAS))
        }

        $suffix = ConvertTo-GlyphModifierSuffix -Modifiers $defaultModifiers
        $canonicalLetters.Add([string]$entry.LETTER_TOKEN)
        $derivedGlyphAliases.Add(([string]$glyphEntry.ASCII_ALIAS + $suffix))
        [void]$derivedGlyphTokens.Add([pscustomobject]@{
                glyph_id = [string]$glyphEntry.GLYPH_ID
                modifiers = @($defaultModifiers)
            })
        [void]$tokens.Add([pscustomobject]@{
                LetterToken   = [string]$entry.LETTER_TOKEN
                AsciiAlias    = [string]$entry.ASCII_ALIAS
                SemanticRole  = [string](Get-Gpv2OptionalValue -Container $entry -PropertyName 'SEMANTIC_ROLE' -Default '')
                TargetGlyphId = [string]$glyphEntry.GLYPH_ID
                TargetAscii   = [string]$glyphEntry.ASCII_ALIAS
                Relation      = [string](Get-Gpv2OptionalValue -Container $primary -PropertyName 'relation' -Default '')
                Confidence    = [double](Get-Gpv2OptionalValue -Container $primary -PropertyName 'confidence' -Default 0.5)
                Modifiers     = @($defaultModifiers)
            })
    }

    $status = 'EMPTY'
    if ($sequence.Count -gt 0) {
        if ($issues.Count -eq 0) {
            $status = 'VALID'
        }
        elseif ($requiredForBackend) {
            $status = 'BLOCKED'
        }
        else {
            $status = 'WARN'
        }
    }

    return [pscustomobject]@{
        HasLetterBridge      = ($sequence.Count -gt 0)
        Profile              = $profile
        RequiredForBackend   = $requiredForBackend
        Status               = $status
        CanonicalLetters     = ($canonicalLetters -join '|')
        DerivedGlyphSequence = ($derivedGlyphAliases -join '|')
        DerivedGlyphTokens   = @($derivedGlyphTokens)
        Issues               = @($issues)
        Tokens               = @($tokens)
        BridgeVersion        = [string](Get-Gpv2OptionalValue -Container $registry.META -PropertyName 'VERSION' -Default '')
    }
}
