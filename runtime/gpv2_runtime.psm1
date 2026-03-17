Set-StrictMode -Version Latest

$script:GlyphRegistryCache = $null
. (Join-Path $PSScriptRoot 'gpv2_letter_bridge.ps1')

function Get-Gpv2OptionalValue {
    param(
        [Parameter(Mandatory = $true)]
        $Container,
        [Parameter(Mandatory = $true)]
        [string]$PropertyName,
        $Default = $null
    )

    if ($null -eq $Container) {
        return $Default
    }

    $prop = $Container.PSObject.Properties[$PropertyName]
    if ($null -eq $prop) {
        return $Default
    }

    return $prop.Value
}

function Get-Gpv2RequiredValue {
    param(
        [Parameter(Mandatory = $true)]
        $Container,
        [Parameter(Mandatory = $true)]
        [string]$PropertyName
    )

    $value = Get-Gpv2OptionalValue -Container $Container -PropertyName $PropertyName -Default $null
    if ($null -eq $value) {
        throw "Missing required property: $PropertyName"
    }

    return $value
}

function Get-Gpv2Collection {
    param($Value)

    if ($null -eq $Value) {
        return @()
    }

    if (($Value -is [System.Collections.IEnumerable]) -and -not ($Value -is [string])) {
        return @($Value)
    }

    return @($Value)
}

function ConvertTo-Gpv2CanonicalString {
    param(
        [Parameter(Mandatory = $true)]
        $Value
    )

    if ($null -eq $Value) {
        return 'null'
    }

    if ($Value -is [string]) {
        $escaped = $Value.Replace('\', '\\').Replace('"', '\"')
        return '"' + $escaped + '"'
    }

    if ($Value -is [bool]) {
        return $Value.ToString().ToLowerInvariant()
    }

    if ($Value -is [byte] -or $Value -is [int16] -or $Value -is [int32] -or $Value -is [int64]) {
        return $Value.ToString([System.Globalization.CultureInfo]::InvariantCulture)
    }

    if ($Value -is [single] -or $Value -is [double] -or $Value -is [decimal]) {
        return ([double]$Value).ToString('G', [System.Globalization.CultureInfo]::InvariantCulture)
    }

    if ($Value -is [System.Collections.IDictionary]) {
        $parts = New-Object System.Collections.Generic.List[string]
        foreach ($key in ($Value.Keys | Sort-Object)) {
            $parts.Add((ConvertTo-Gpv2CanonicalString ([string]$key)) + ':' + (ConvertTo-Gpv2CanonicalString $Value[$key]))
        }
        return '{' + ($parts -join ',') + '}'
    }

    if (($Value -is [System.Collections.IEnumerable]) -and -not ($Value -is [string])) {
        $parts = New-Object System.Collections.Generic.List[string]
        foreach ($item in $Value) {
            $parts.Add((ConvertTo-Gpv2CanonicalString $item))
        }
        return '[' + ($parts -join ',') + ']'
    }

    $propertyNames = @($Value.PSObject.Properties | Select-Object -ExpandProperty Name)
    if ($propertyNames.Count -gt 0) {
        $ordered = [ordered]@{}
        foreach ($prop in ($propertyNames | Sort-Object)) {
            $ordered[$prop] = Get-Gpv2OptionalValue -Container $Value -PropertyName $prop
        }
        return ConvertTo-Gpv2CanonicalString $ordered
    }

    return ConvertTo-Gpv2CanonicalString ([string]$Value)
}

function New-Gpv2Hash {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
        $hashBytes = $sha.ComputeHash($bytes)
        return ([System.BitConverter]::ToString($hashBytes)).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
    }
}

function ConvertTo-Gpv2Literal {
    param(
        [Parameter(Mandatory = $true)]
        $Value
    )

    if ($null -eq $Value) {
        return 'null'
    }

    if ($Value -is [bool]) {
        return $Value.ToString().ToLowerInvariant()
    }

    if ($Value -is [byte] -or $Value -is [int16] -or $Value -is [int32] -or $Value -is [int64]) {
        return $Value.ToString([System.Globalization.CultureInfo]::InvariantCulture)
    }

    if ($Value -is [single] -or $Value -is [double] -or $Value -is [decimal]) {
        return ([double]$Value).ToString('G', [System.Globalization.CultureInfo]::InvariantCulture)
    }

    $text = [string]$Value
    $escaped = $text.Replace('\', '\\').Replace('"', '\"')
    return '"' + $escaped + '"'
}

function New-Gpv2PrimitiveLine {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$Arguments
    )

    $pairs = New-Object System.Collections.Generic.List[string]
    foreach ($key in $Arguments.Keys) {
        $pairs.Add(('{0}={1}' -f $key, (ConvertTo-Gpv2Literal $Arguments[$key])))
    }

    return '{0}({1})' -f $Name, ($pairs -join ',')
}

function Split-Gpv2ArgumentList {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    $segments = New-Object System.Collections.Generic.List[string]
    $builder = New-Object System.Text.StringBuilder
    $inQuotes = $false
    $escape = $false

    foreach ($char in $Text.ToCharArray()) {
        if ($escape) {
            [void]$builder.Append($char)
            $escape = $false
            continue
        }

        if (($char -eq '\') -and $inQuotes) {
            [void]$builder.Append($char)
            $escape = $true
            continue
        }

        if ($char -eq '"') {
            [void]$builder.Append($char)
            $inQuotes = -not $inQuotes
            continue
        }

        if (($char -eq ',') -and -not $inQuotes) {
            $segments.Add($builder.ToString())
            [void]$builder.Clear()
            continue
        }

        [void]$builder.Append($char)
    }

    if ($builder.Length -gt 0) {
        $segments.Add($builder.ToString())
    }

    return ,$segments.ToArray()
}

function ConvertFrom-Gpv2Literal {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    $valueText = $Text.Trim()

    if ($valueText -match '^"(.*)"$') {
        $inner = $matches[1]
        $inner = $inner.Replace('\"', '"').Replace('\\', '\')
        return $inner
    }

    if ($valueText -eq 'true') {
        return $true
    }

    if ($valueText -eq 'false') {
        return $false
    }

    if ($valueText -eq 'null') {
        return $null
    }

    $number = 0.0
    if ([double]::TryParse($valueText, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$number)) {
        return $number
    }

    return $valueText
}

function Parse-Gpv2Primitive {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Line
    )

    $trimmed = $Line.Trim()
    if ($trimmed -notmatch '^([A-Z_]+)\((.*)\)$') {
        throw "Invalid primitive line: $Line"
    }

    $name = $matches[1]
    $argumentText = $matches[2]
    $arguments = [ordered]@{}

    if (-not [string]::IsNullOrWhiteSpace($argumentText)) {
        foreach ($segment in (Split-Gpv2ArgumentList $argumentText)) {
            if ([string]::IsNullOrWhiteSpace($segment)) {
                continue
            }

            if ($segment -notmatch '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)\s*$') {
                throw "Invalid primitive argument: $segment"
            }

            $arguments[$matches[1]] = ConvertFrom-Gpv2Literal $matches[2]
        }
    }

    return [pscustomobject]@{
        Name      = $name
        Arguments = [pscustomobject]$arguments
        Raw       = $trimmed
    }
}
function Get-GlyphRegistryPath {
    return Join-Path $PSScriptRoot 'glyph_registry.json'
}

function Normalize-GlyphRegistryKey {
    param(
        [AllowEmptyString()][string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return ''
    }

    return (($Value.Trim().ToUpperInvariant()) -replace '\s+', '_')
}

function Import-GlyphRegistry {
    param([switch]$Force)

    if ($script:GlyphRegistryCache -and -not $Force) {
        return $script:GlyphRegistryCache
    }

    $path = Get-GlyphRegistryPath
    if (-not (Test-Path $path)) {
        throw "Glyph registry file not found: $path"
    }

    $raw = Get-Content -Path $path -Raw | ConvertFrom-Json
    $entries = @(Get-Gpv2Collection (Get-Gpv2OptionalValue -Container $raw -PropertyName 'entries' -Default @()))
    $byId = @{}
    $byAlias = @{}
    foreach ($entry in $entries) {
        $idKey = Normalize-GlyphRegistryKey ([string](Get-Gpv2RequiredValue -Container $entry -PropertyName 'GLYPH_ID'))
        $aliasKey = Normalize-GlyphRegistryKey ([string](Get-Gpv2RequiredValue -Container $entry -PropertyName 'ASCII_ALIAS'))
        $byId[$idKey] = $entry
        $byAlias[$aliasKey] = $entry
    }

    $modifierMap = @{}
    $modifierSource = Get-Gpv2OptionalValue -Container $raw -PropertyName 'MODIFIER_MAP' -Default $null
    if ($modifierSource) {
        foreach ($name in @($modifierSource.PSObject.Properties | Select-Object -ExpandProperty Name)) {
            $modifierMap[(Normalize-GlyphRegistryKey $name)] = [string](Get-Gpv2OptionalValue -Container $modifierSource -PropertyName $name)
        }
    }

    $script:GlyphRegistryCache = [pscustomobject]@{
        META        = Get-Gpv2OptionalValue -Container $raw -PropertyName 'META'
        Entries     = $entries
        ById        = $byId
        ByAlias     = $byAlias
        ModifierMap = $modifierMap
    }

    return $script:GlyphRegistryCache
}

function Get-GlyphRegistryEntry {
    param(
        [string]$GlyphId,
        [string]$AsciiAlias
    )

    $registry = Import-GlyphRegistry
    $idKey = Normalize-GlyphRegistryKey ([string]$GlyphId)
    $aliasKey = Normalize-GlyphRegistryKey ([string]$AsciiAlias)

    if (-not [string]::IsNullOrWhiteSpace($idKey) -and $registry.ById.ContainsKey($idKey)) {
        return $registry.ById[$idKey]
    }

    if (-not [string]::IsNullOrWhiteSpace($aliasKey) -and $registry.ByAlias.ContainsKey($aliasKey)) {
        return $registry.ByAlias[$aliasKey]
    }

    return $null
}

function Get-GlyphTokenModifiers {
    param($Token)

    $modifiers = New-Object System.Collections.Generic.List[string]
    if ($Token -isnot [string]) {
        $single = Normalize-GlyphRegistryKey ([string](Get-Gpv2OptionalValue -Container $Token -PropertyName 'modifier' -Default ''))
        if (-not [string]::IsNullOrWhiteSpace($single)) {
            $modifiers.Add($single)
        }

        foreach ($modifier in (Get-Gpv2Collection (Get-Gpv2OptionalValue -Container $Token -PropertyName 'modifiers' -Default @()))) {
            $normalized = Normalize-GlyphRegistryKey ([string]$modifier)
            if (-not [string]::IsNullOrWhiteSpace($normalized) -and -not $modifiers.Contains($normalized)) {
                $modifiers.Add($normalized)
            }
        }
    }

    return @($modifiers)
}

function ConvertTo-GlyphModifierSuffix {
    param(
        [string[]]$Modifiers
    )

    $registry = Import-GlyphRegistry
    $suffixes = New-Object System.Collections.Generic.List[string]
    foreach ($modifier in (Get-Gpv2Collection $Modifiers)) {
        $normalized = Normalize-GlyphRegistryKey ([string]$modifier)
        if ($registry.ModifierMap.ContainsKey($normalized)) {
            $suffixes.Add([string]$registry.ModifierMap[$normalized])
        }
    }

    return ($suffixes -join '')
}

function Resolve-GlyphUiSpec {
    param(
        $GlyphUi
    )

    if ($null -eq $GlyphUi) {
        return [pscustomobject]@{
            HasGlyphUi         = $false
            Profile            = $null
            RequiredForBackend = $false
            Status             = 'ABSENT'
            CanonicalSequence  = ''
            Issues             = @()
            Tokens             = @()
        }
    }

    $registry = Import-GlyphRegistry
    $profile = [string](Get-Gpv2OptionalValue -Container $GlyphUi -PropertyName 'profile' -Default 'GLYPH_UI_V1')
    $requiredForBackend = [bool](Get-Gpv2OptionalValue -Container $GlyphUi -PropertyName 'required_for_backend' -Default $false)
    $sequence = @(Get-Gpv2Collection (Get-Gpv2OptionalValue -Container $GlyphUi -PropertyName 'sequence' -Default @()))
    $issues = New-Object System.Collections.Generic.List[string]
    $tokens = New-Object System.Collections.ArrayList
    $canonicalTokens = New-Object System.Collections.Generic.List[string]

    foreach ($token in $sequence) {
        $glyphId = ''
        $asciiAlias = ''

        if ($token -is [string]) {
            $tokenText = [string]$token
            if ((Normalize-GlyphRegistryKey $tokenText) -like 'GL-*' -or (Normalize-GlyphRegistryKey $tokenText) -like 'OP-*') {
                $glyphId = $tokenText
            }
            else {
                $asciiAlias = $tokenText
            }
        }
        else {
            $glyphId = [string](Get-Gpv2OptionalValue -Container $token -PropertyName 'glyph_id' -Default '')
            $asciiAlias = [string](Get-Gpv2OptionalValue -Container $token -PropertyName 'ascii_alias' -Default '')
        }

        $entry = Get-GlyphRegistryEntry -GlyphId $glyphId -AsciiAlias $asciiAlias
        if ($null -eq $entry) {
            $issues.Add(('unknown_glyph:{0}{1}' -f $glyphId, $(if ($asciiAlias) { ':' + $asciiAlias } else { '' })))
            continue
        }

        $allowedModifiers = @(Get-Gpv2Collection (Get-Gpv2OptionalValue -Container $entry -PropertyName 'ALLOWED_MODIFIERS' -Default @()) | ForEach-Object { Normalize-GlyphRegistryKey ([string]$_) })
        $modifiers = @(Get-GlyphTokenModifiers -Token $token)
        foreach ($modifier in $modifiers) {
            if ($allowedModifiers -notcontains $modifier) {
                $issues.Add(('modifier_not_allowed:{0}:{1}' -f [string]$entry.ASCII_ALIAS, $modifier))
            }
        }

        $backendSafe = [bool](Get-Gpv2OptionalValue -Container $entry -PropertyName 'BACKEND_SAFE' -Default $false)
        $uiOnly = [bool](Get-Gpv2OptionalValue -Container $entry -PropertyName 'UI_ONLY' -Default $true)
        if ($requiredForBackend -and ((-not $backendSafe) -or $uiOnly)) {
            $issues.Add(('glyph_not_backend_safe:{0}' -f [string]$entry.ASCII_ALIAS))
        }

        $suffix = ConvertTo-GlyphModifierSuffix -Modifiers $modifiers
        $canonicalTokens.Add(([string]$entry.ASCII_ALIAS + $suffix))
        [void]$tokens.Add([pscustomobject]@{
                GlyphId     = [string]$entry.GLYPH_ID
                AsciiAlias  = [string]$entry.ASCII_ALIAS
                DisplayName = [string](Get-Gpv2OptionalValue -Container $entry -PropertyName 'DISPLAY_NAME' -Default '')
                BackendSafe = $backendSafe
                UiOnly      = $uiOnly
                Modifiers   = @($modifiers)
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
        HasGlyphUi         = ($sequence.Count -gt 0)
        Profile            = $profile
        RequiredForBackend = $requiredForBackend
        Status             = $status
        CanonicalSequence  = ($canonicalTokens -join '|')
        Issues             = @($issues)
        Tokens             = @($tokens)
        RegistryVersion    = [string](Get-Gpv2OptionalValue -Container $registry.META -PropertyName 'VERSION' -Default '')
    }
}

function Invoke-HgovAssessment {
    param(
        [Parameter(Mandatory = $true)]
        $Payload
    )

    $score = 0
    $triggers = New-Object System.Collections.Generic.List[string]
    $context = Get-Gpv2OptionalValue -Container $Payload -PropertyName 'CONTEXT'
    $meta = Get-Gpv2RequiredValue -Container $Payload -PropertyName 'META'
    $facts = Get-Gpv2Collection (Get-Gpv2OptionalValue -Container $Payload -PropertyName 'FACTS' -Default @())

    if ((Get-Gpv2OptionalValue -Container $meta -PropertyName 'MODE' -Default '') -eq 'FACT_STRICT') {
        $score += 5
        $triggers.Add('fact_strict_mode')
    }

    if ($context) {
        if ([bool](Get-Gpv2OptionalValue -Container $context -PropertyName 'recent_topic' -Default $false)) {
            $score += 20
            $triggers.Add('recent_topic')
        }
        if ([bool](Get-Gpv2OptionalValue -Container $context -PropertyName 'premise_unverified' -Default $false)) {
            $score += 30
            $triggers.Add('premise_unverified')
        }
        if ([bool](Get-Gpv2OptionalValue -Container $context -PropertyName 'conflict_with_canon' -Default $false)) {
            $score += 40
            $triggers.Add('conflict_with_canon')
        }
    }

    foreach ($fact in $facts) {
        $key = [string](Get-Gpv2RequiredValue -Container $fact -PropertyName 'key')
        $source = [string](Get-Gpv2OptionalValue -Container $fact -PropertyName 'source' -Default '')
        $confidence = [double](Get-Gpv2OptionalValue -Container $fact -PropertyName 'confidence' -Default 0.5)
        $externalClaim = [bool](Get-Gpv2OptionalValue -Container $fact -PropertyName 'external_claim' -Default $false)
        $hasSource = -not [string]::IsNullOrWhiteSpace($source)

        if (-not $hasSource) {
            $score += 25
            $triggers.Add(('missing_source:{0}' -f $key))
        }
        if ($externalClaim) {
            $score += 15
            $triggers.Add(('external_claim:{0}' -f $key))
        }
        if ($confidence -gt 0.95 -and -not $hasSource) {
            $score += 10
            $triggers.Add(('overconfident_unsourced:{0}' -f $key))
        }
    }

    if ($score -gt 100) {
        $score = 100
    }

    $riskLevel = 'LOW'
    if ($score -ge 75) {
        $riskLevel = 'CRITICAL'
    }
    elseif ($score -ge 50) {
        $riskLevel = 'HIGH'
    }
    elseif ($score -ge 25) {
        $riskLevel = 'MID'
    }

    $premiseStatus = 'CONFIRMED'
    if ($context -and [bool](Get-Gpv2OptionalValue -Container $context -PropertyName 'conflict_with_canon' -Default $false)) {
        $premiseStatus = 'CONFLICTED'
    }
    elseif ($context -and [bool](Get-Gpv2OptionalValue -Container $context -PropertyName 'premise_unverified' -Default $false)) {
        $premiseStatus = 'UNCONFIRMED'
    }

    $policy = 'ALLOW'
    switch ($riskLevel) {
        'MID' { $policy = 'QUALIFY' }
        'HIGH' { $policy = 'VERIFY_OR_REFRAME' }
        'CRITICAL' { $policy = 'BLOCK_ASSERTION' }
    }

    return [pscustomobject]@{
        RiskScore     = $score
        RiskLevel     = $riskLevel
        PremiseStatus = $premiseStatus
        Policy        = $policy
        Triggers      = @($triggers)
    }
}

function Test-Gpv2GlOrder {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$GlLines
    )

    $orderMap = @{
        LIMIT  = 0
        ASSERT = 1
        FACT   = 2
        SOURCE = 3
        REF    = 4
        STATE  = 5
        RISK   = 6
        UNSURE = 7
    }

    $lastIndex = -1
    foreach ($line in $GlLines) {
        $primitive = Parse-Gpv2Primitive $line
        if ($orderMap.ContainsKey($primitive.Name)) {
            $currentIndex = $orderMap[$primitive.Name]
            if ($currentIndex -lt $lastIndex) {
                return $false
            }
            $lastIndex = $currentIndex
        }
    }

    return $true
}

function Expand-Gpv2Packet {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$GlgLines
    )

    $parsed = @($GlgLines | ForEach-Object { Parse-Gpv2Primitive $_ })
    $glSnapshot = $parsed | Where-Object { $_.Name -eq 'PACK' -and $_.Arguments.name -eq 'gl_canon_b64' } | Select-Object -First 1
    $glyphPack = $parsed | Where-Object { $_.Name -eq 'PACK' -and $_.Arguments.name -eq 'glyph_ascii' } | Select-Object -First 1
    $letterTokensPack = $parsed | Where-Object { $_.Name -eq 'PACK' -and $_.Arguments.name -eq 'letter_tokens' } | Select-Object -First 1
    $letterGlyphPack = $parsed | Where-Object { $_.Name -eq 'PACK' -and $_.Arguments.name -eq 'letter_glyph_ascii' } | Select-Object -First 1
    $stat = $parsed | Where-Object { $_.Name -eq 'STAT' } | Select-Object -First 1
    $idx = $parsed | Where-Object { $_.Name -eq 'IDX' } | Select-Object -First 1
    $hash = $parsed | Where-Object { $_.Name -eq 'HASH' } | Select-Object -First 1
    $route = $parsed | Where-Object { $_.Name -eq 'ROUTE' } | Select-Object -First 1

    $glLines = @()
    if ($glSnapshot) {
        $bytes = [System.Convert]::FromBase64String([string]$glSnapshot.Arguments.val)
        $glText = [System.Text.Encoding]::UTF8.GetString($bytes)
        $glLines = @([regex]::Split($glText, "`r`n|`n") | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    }

    return [pscustomobject]@{
        IDX              = $(if ($idx) { $idx.Arguments.key } else { $null })
        Risk             = $(if ($stat) { $stat.Arguments.risk } else { $null })
        Uncertainty      = $(if ($stat) { $stat.Arguments.uncertainty } else { $null })
        Hash             = $(if ($hash) { $hash.Arguments.val } else { $null })
        GlyphAscii       = $(if ($glyphPack) { $glyphPack.Arguments.val } else { $null })
        LetterTokens     = $(if ($letterTokensPack) { $letterTokensPack.Arguments.val } else { $null })
        LetterGlyphAscii = $(if ($letterGlyphPack) { $letterGlyphPack.Arguments.val } else { $null })
        Route            = $(if ($route) { [pscustomobject]@{ Module = $route.Arguments.module; Mode = $route.Arguments.mode } } else { $null })
        GL               = $glLines
    }
}

function Test-Gpv2Packet {
    param(
        [Parameter(Mandatory = $true)]
        $Packet
    )

    $issues = New-Object System.Collections.Generic.List[string]

    if (-not (Test-Gpv2GlOrder -GlLines $Packet.GL)) {
        $issues.Add('GL order is invalid.')
    }

    if (-not ($Packet.GL_G | Where-Object { $_ -like 'IDX(*' })) {
        $issues.Add('GL_G is missing IDX.')
    }

    if (-not ($Packet.GL_G | Where-Object { $_ -like 'HASH(*' })) {
        $issues.Add('GL_G is missing HASH.')
    }

    if ($Packet.GL | Where-Object { $_ -like 'UNSURE(*' }) {
        $statLine = $Packet.GL_G | Where-Object { $_ -like 'STAT(*' } | Select-Object -First 1
        if (-not $statLine) {
            $issues.Add('GL_G is missing STAT for uncertainty propagation.')
        }
        else {
            $parsedStat = Parse-Gpv2Primitive $statLine
            if ([string]$parsedStat.Arguments.uncertainty -ne '1') {
                $issues.Add('GL_G STAT uncertainty flag should be 1 when GL contains UNSURE.')
            }
        }
    }

    if ($Packet.GL | Where-Object { $_ -like 'STATE(name="GLYPH_UI_STATUS"*' }) {
        if (-not ($Packet.GL_G | Where-Object { $_ -eq 'TAG(ns="GLYPH",name="PRESENT")' })) {
            $issues.Add('GL_G is missing glyph presence tag.')
        }
        if (-not ($Packet.GL_G | Where-Object { $_ -like 'PACK(name="glyph_ascii"*' })) {
            $issues.Add('GL_G is missing glyph_ascii pack.')
        }
    }

    if ($Packet.GL | Where-Object { $_ -like 'STATE(name="LETTER_BRIDGE_STATUS"*' }) {
        if (-not ($Packet.GL_G | Where-Object { $_ -eq 'TAG(ns="BRIDGE",name="LETTER_PRESENT")' })) {
            $issues.Add('GL_G is missing letter bridge presence tag.')
        }
        if (-not ($Packet.GL_G | Where-Object { $_ -like 'PACK(name="letter_tokens"*' })) {
            $issues.Add('GL_G is missing letter_tokens pack.')
        }
        if (-not ($Packet.GL_G | Where-Object { $_ -like 'PACK(name="letter_glyph_ascii"*' })) {
            $issues.Add('GL_G is missing letter_glyph_ascii pack.')
        }
    }

    $expanded = Expand-Gpv2Packet -GlgLines $Packet.GL_G
    if ((@($expanded.GL) -join "`n") -ne (@($Packet.GL) -join "`n")) {
        $issues.Add('Roundtrip fidelity failed for GL snapshot.')
    }

    return [pscustomobject]@{
        Pass   = ($issues.Count -eq 0)
        Issues = @($issues)
    }
}

function Invoke-Gpv2Compile {
    [CmdletBinding(DefaultParameterSetName = 'ByObject')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ByObject')]
        $Payload,
        [Parameter(Mandatory = $true, ParameterSetName = 'ByPath')]
        [string]$Path
    )

    if ($PSCmdlet.ParameterSetName -eq 'ByPath') {
        $Payload = Get-Content -Path $Path -Raw | ConvertFrom-Json
    }

    $meta = Get-Gpv2RequiredValue -Container $Payload -PropertyName 'META'
    $semantic = Get-Gpv2OptionalValue -Container $Payload -PropertyName 'SEMANTIC'
    $routing = Get-Gpv2RequiredValue -Container $Payload -PropertyName 'ROUTING'
    $rawGlyphUi = Get-Gpv2OptionalValue -Container $Payload -PropertyName 'GLYPH_UI' -Default $null
    $letterBridge = Resolve-LetterBridgeSpec -LetterBridge (Get-Gpv2OptionalValue -Container $Payload -PropertyName 'LETTER_BRIDGE' -Default $null)
    if ($letterBridge.HasLetterBridge -and -not $rawGlyphUi) {
        $rawGlyphUi = [pscustomobject]@{
            profile = 'GLYPH_UI_V1'
            required_for_backend = $letterBridge.RequiredForBackend
            sequence = @($letterBridge.DerivedGlyphTokens)
        }
    }
    $glyphUi = Resolve-GlyphUiSpec -GlyphUi $rawGlyphUi

    [void](Get-Gpv2RequiredValue -Container $meta -PropertyName 'ID')
    [void](Get-Gpv2RequiredValue -Container $meta -PropertyName 'VERSION')
    [void](Get-Gpv2RequiredValue -Container $meta -PropertyName 'MODE')
    [void](Get-Gpv2RequiredValue -Container $routing -PropertyName 'module')
    [void](Get-Gpv2RequiredValue -Container $routing -PropertyName 'mode')

    if ($letterBridge.Status -eq 'BLOCKED') {
        throw ('LETTER_BRIDGE validation failed: ' + ($letterBridge.Issues -join '; '))
    }

    if ($glyphUi.Status -eq 'BLOCKED') {
        throw ('GLYPH_UI backend validation failed: ' + ($glyphUi.Issues -join '; '))
    }

    if ($letterBridge.HasLetterBridge -and $glyphUi.HasGlyphUi -and -not [string]::IsNullOrWhiteSpace($letterBridge.DerivedGlyphSequence)) {
        if ($letterBridge.DerivedGlyphSequence -ne $glyphUi.CanonicalSequence) {
            throw ('LETTER_BRIDGE and GLYPH_UI mismatch: ' + $letterBridge.DerivedGlyphSequence + ' != ' + $glyphUi.CanonicalSequence)
        }
    }

    $hgov = Invoke-HgovAssessment -Payload $Payload

    $limitLines = New-Object System.Collections.Generic.List[string]
    $assertLines = New-Object System.Collections.Generic.List[string]
    $factLines = New-Object System.Collections.Generic.List[string]
    $sourceLines = New-Object System.Collections.Generic.List[string]
    $refLines = New-Object System.Collections.Generic.List[string]
    $stateLines = New-Object System.Collections.Generic.List[string]
    $riskLines = New-Object System.Collections.Generic.List[string]
    $unsureLines = New-Object System.Collections.Generic.List[string]

    foreach ($constraint in (Get-Gpv2Collection (Get-Gpv2OptionalValue -Container $Payload -PropertyName 'CONSTRAINTS' -Default @()) | Sort-Object key, rule)) {
        $limitLines.Add((New-Gpv2PrimitiveLine -Name 'LIMIT' -Arguments ([ordered]@{
                    key  = [string](Get-Gpv2RequiredValue -Container $constraint -PropertyName 'key')
                    rule = [string](Get-Gpv2RequiredValue -Container $constraint -PropertyName 'rule')
                })))
    }

    foreach ($assertion in (Get-Gpv2Collection (Get-Gpv2OptionalValue -Container $Payload -PropertyName 'ASSERTIONS' -Default @()) | Sort-Object rule)) {
        $assertLines.Add((New-Gpv2PrimitiveLine -Name 'ASSERT' -Arguments ([ordered]@{
                    rule = [string](Get-Gpv2RequiredValue -Container $assertion -PropertyName 'rule')
                    pass = [bool](Get-Gpv2OptionalValue -Container $assertion -PropertyName 'pass' -Default $false)
                })))
    }

    if ($glyphUi.HasGlyphUi) {
        $assertLines.Add((New-Gpv2PrimitiveLine -Name 'ASSERT' -Arguments ([ordered]@{
                    rule = 'GLYPH_UI registry validation'
                    pass = [bool]($glyphUi.Status -eq 'VALID')
                })))
    }

    if ($letterBridge.HasLetterBridge) {
        $assertLines.Add((New-Gpv2PrimitiveLine -Name 'ASSERT' -Arguments ([ordered]@{
                    rule = 'LETTER_BRIDGE resolution'
                    pass = [bool]($letterBridge.Status -eq 'VALID')
                })))
    }

    foreach ($fact in (Get-Gpv2Collection (Get-Gpv2OptionalValue -Container $Payload -PropertyName 'FACTS' -Default @()) | Sort-Object key)) {
        $key = [string](Get-Gpv2RequiredValue -Container $fact -PropertyName 'key')
        $value = [string](Get-Gpv2OptionalValue -Container $fact -PropertyName 'value' -Default '')
        $confidence = [double](Get-Gpv2OptionalValue -Container $fact -PropertyName 'confidence' -Default 0.5)
        $source = [string](Get-Gpv2OptionalValue -Container $fact -PropertyName 'source' -Default '')
        $ref = [string](Get-Gpv2OptionalValue -Container $fact -PropertyName 'ref' -Default '')
        $hasSource = -not [string]::IsNullOrWhiteSpace($source)

        if ($hasSource) {
            $factLines.Add((New-Gpv2PrimitiveLine -Name 'FACT' -Arguments ([ordered]@{
                        key  = $key
                        val  = $value
                        conf = $confidence
                    })))
            $sourceLines.Add((New-Gpv2PrimitiveLine -Name 'SOURCE' -Arguments ([ordered]@{
                        key = $key
                        ref = $source
                    })))
            if (-not [string]::IsNullOrWhiteSpace($ref)) {
                $refLines.Add((New-Gpv2PrimitiveLine -Name 'REF' -Arguments ([ordered]@{
                            key = $key
                            id  = $ref
                        })))
            }
        }
        else {
            $unsureLines.Add((New-Gpv2PrimitiveLine -Name 'UNSURE' -Arguments ([ordered]@{
                        key    = $key
                        reason = 'missing_source'
                        conf   = $confidence
                    })))
        }
    }

    $stateLines.Add((New-Gpv2PrimitiveLine -Name 'STATE' -Arguments ([ordered]@{
                name = 'PREMISE_STATUS'
                val  = [string]$hgov.PremiseStatus
            })))
    $stateLines.Add((New-Gpv2PrimitiveLine -Name 'STATE' -Arguments ([ordered]@{
                name = 'POLICY'
                val  = [string]$hgov.Policy
            })))

    $glTrans = [string](Get-Gpv2OptionalValue -Container $semantic -PropertyName 'GL_TRANS' -Default '')
    if (-not [string]::IsNullOrWhiteSpace($glTrans)) {
        $stateLines.Add((New-Gpv2PrimitiveLine -Name 'STATE' -Arguments ([ordered]@{
                    name = 'GL_TRANS'
                    val  = $glTrans
                })))
    }

    if ($glyphUi.HasGlyphUi) {
        $stateLines.Add((New-Gpv2PrimitiveLine -Name 'STATE' -Arguments ([ordered]@{
                    name = 'GLYPH_UI_STATUS'
                    val  = [string]$glyphUi.Status
                })))
        $stateLines.Add((New-Gpv2PrimitiveLine -Name 'STATE' -Arguments ([ordered]@{
                    name = 'GLYPH_UI_PROFILE'
                    val  = [string]$glyphUi.Profile
                })))
        $stateLines.Add((New-Gpv2PrimitiveLine -Name 'STATE' -Arguments ([ordered]@{
                    name = 'GLYPH_UI_ASCII'
                    val  = [string]$glyphUi.CanonicalSequence
                })))
    }

    if ($letterBridge.HasLetterBridge) {
        $stateLines.Add((New-Gpv2PrimitiveLine -Name 'STATE' -Arguments ([ordered]@{
                    name = 'LETTER_BRIDGE_STATUS'
                    val  = [string]$letterBridge.Status
                })))
        $stateLines.Add((New-Gpv2PrimitiveLine -Name 'STATE' -Arguments ([ordered]@{
                    name = 'LETTER_BRIDGE_TOKENS'
                    val  = [string]$letterBridge.CanonicalLetters
                })))
        $stateLines.Add((New-Gpv2PrimitiveLine -Name 'STATE' -Arguments ([ordered]@{
                    name = 'LETTER_BRIDGE_GLYPH'
                    val  = [string]$letterBridge.DerivedGlyphSequence
                })))
    }

    $riskLines.Add((New-Gpv2PrimitiveLine -Name 'RISK' -Arguments ([ordered]@{
                level = [string]$hgov.RiskLevel
            })))

    if ($glyphUi.HasGlyphUi -and $glyphUi.Issues.Count -gt 0) {
        $issueReason = (($glyphUi.Issues | Select-Object -First 3) -join ';')
        $unsureLines.Add((New-Gpv2PrimitiveLine -Name 'UNSURE' -Arguments ([ordered]@{
                    key    = 'glyph_ui_registry'
                    reason = $issueReason
                    conf   = 0.4
                })))
    }

    if ($letterBridge.HasLetterBridge -and $letterBridge.Issues.Count -gt 0) {
        $issueReason = (($letterBridge.Issues | Select-Object -First 3) -join ';')
        $unsureLines.Add((New-Gpv2PrimitiveLine -Name 'UNSURE' -Arguments ([ordered]@{
                    key    = 'letter_bridge'
                    reason = $issueReason
                    conf   = 0.45
                })))
    }

    $glLines = @(
        $limitLines
        $assertLines
        $factLines
        $sourceLines
        $refLines
        $stateLines
        $riskLines
        $unsureLines
    ) | Where-Object { $_ }

    $canonicalJson = ConvertTo-Gpv2CanonicalString $Payload
    $glCanonicalText = $glLines -join "`n"
    $hashInput = @(
        [string](Get-Gpv2RequiredValue -Container $meta -PropertyName 'ID')
        [string](Get-Gpv2RequiredValue -Container $meta -PropertyName 'VERSION')
        [string](Get-Gpv2RequiredValue -Container $meta -PropertyName 'MODE')
        $canonicalJson
        $glCanonicalText
    ) -join "`n---`n"
    $hash = New-Gpv2Hash -Text $hashInput
    $glSnapshot = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($glCanonicalText))
    $uncertaintyFlag = if ($unsureLines.Count -gt 0) { '1' } else { '0' }

    $glgLines = New-Object System.Collections.Generic.List[string]
    $glgLines.Add((New-Gpv2PrimitiveLine -Name 'IDX' -Arguments ([ordered]@{ key = [string](Get-Gpv2RequiredValue -Container $meta -PropertyName 'ID') })))
    $glgLines.Add((New-Gpv2PrimitiveLine -Name 'TAG' -Arguments ([ordered]@{ ns = 'ORA'; name = 'GPV2' })))
    $glgLines.Add((New-Gpv2PrimitiveLine -Name 'TAG' -Arguments ([ordered]@{ ns = 'MODE'; name = [string](Get-Gpv2RequiredValue -Container $meta -PropertyName 'MODE') })))
    if ($glyphUi.HasGlyphUi) {
        $glgLines.Add((New-Gpv2PrimitiveLine -Name 'TAG' -Arguments ([ordered]@{ ns = 'GLYPH'; name = 'PRESENT' })))
    }
    if ($letterBridge.HasLetterBridge) {
        $glgLines.Add((New-Gpv2PrimitiveLine -Name 'TAG' -Arguments ([ordered]@{ ns = 'BRIDGE'; name = 'LETTER_PRESENT' })))
    }
    $glgLines.Add((New-Gpv2PrimitiveLine -Name 'STAT' -Arguments ([ordered]@{ risk = [string]$hgov.RiskLevel; uncertainty = $uncertaintyFlag })))
    $glgLines.Add((New-Gpv2PrimitiveLine -Name 'HASH' -Arguments ([ordered]@{ algo = 'sha256'; val = $hash })))
    $glgLines.Add((New-Gpv2PrimitiveLine -Name 'ROUTE' -Arguments ([ordered]@{ module = [string](Get-Gpv2RequiredValue -Container $routing -PropertyName 'module'); mode = [string](Get-Gpv2RequiredValue -Container $routing -PropertyName 'mode') })))
    if ($glyphUi.HasGlyphUi) {
        $glgLines.Add((New-Gpv2PrimitiveLine -Name 'PACK' -Arguments ([ordered]@{ name = 'glyph_profile'; val = [string]$glyphUi.Profile })))
        $glgLines.Add((New-Gpv2PrimitiveLine -Name 'PACK' -Arguments ([ordered]@{ name = 'glyph_ascii'; val = [string]$glyphUi.CanonicalSequence })))
    }
    if ($letterBridge.HasLetterBridge) {
        $glgLines.Add((New-Gpv2PrimitiveLine -Name 'PACK' -Arguments ([ordered]@{ name = 'letter_tokens'; val = [string]$letterBridge.CanonicalLetters })))
        $glgLines.Add((New-Gpv2PrimitiveLine -Name 'PACK' -Arguments ([ordered]@{ name = 'letter_glyph_ascii'; val = [string]$letterBridge.DerivedGlyphSequence })))
    }
    $glgLines.Add((New-Gpv2PrimitiveLine -Name 'PACK' -Arguments ([ordered]@{ name = 'gl_count'; val = [string]$glLines.Count })))
    $glgLines.Add((New-Gpv2PrimitiveLine -Name 'PACK' -Arguments ([ordered]@{ name = 'gl_canon_b64'; val = $glSnapshot })))

    $packet = [pscustomobject]@{
        META     = [pscustomobject]@{
            ID      = [string](Get-Gpv2RequiredValue -Container $meta -PropertyName 'ID')
            VERSION = [string](Get-Gpv2RequiredValue -Container $meta -PropertyName 'VERSION')
            MODE    = [string](Get-Gpv2RequiredValue -Container $meta -PropertyName 'MODE')
            HASH    = $hash
        }
        HGOV          = $hgov
        LETTER_BRIDGE = $letterBridge
        GLYPH_UI      = $glyphUi
        JSON          = $Payload
        GL            = @($glLines)
        GL_G          = @($glgLines)
    }

    $packet | Add-Member -MemberType NoteProperty -Name VALIDATION -Value (Test-Gpv2Packet -Packet $packet)
    return $packet
}

Export-ModuleMember -Function Invoke-Gpv2Compile, Parse-Gpv2Primitive, Expand-Gpv2Packet, Test-Gpv2Packet, Invoke-HgovAssessment, Test-Gpv2GlOrder, New-Gpv2Hash, Import-GlyphRegistry, Get-GlyphRegistryEntry, Resolve-GlyphUiSpec, Import-LetterGlyphBridge, Get-LetterGlyphBridgeEntry, Resolve-LetterBridgeSpec


