Set-StrictMode -Version Latest

$script:SessionState = [ordered]@{
    Active = $false
    RunCount = 0
    LastRunAt = $null
    LastPromptText = $null
    LastResult = $null
}

function Get-HNeronsModuleRoot {
    return $PSScriptRoot
}

function Get-HNeronsRuntimeRoot {
    return (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
}

function Get-HNeronsBootstrapModulePath {
    return (Join-Path (Get-HNeronsRuntimeRoot) 'gpv2_runtime.psm1')
}

function Get-HNeronsSpecPath {
    return (Join-Path (Get-HNeronsModuleRoot) 'MODULE_H_NERONS_GPV2_v1.0.0.json')
}

function Import-HNeronsBootstrapModule {
    $modulePath = Get-HNeronsBootstrapModulePath
    if (-not (Test-Path -LiteralPath $modulePath)) {
        throw "Bootstrap module not found: $modulePath"
    }

    Import-Module -Name $modulePath -Force | Out-Null
}

function Get-HNOptionalValue {
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

function Get-HNRequiredValue {
    param(
        [Parameter(Mandatory = $true)]
        $Container,
        [Parameter(Mandatory = $true)]
        [string]$PropertyName
    )

    $value = Get-HNOptionalValue -Container $Container -PropertyName $PropertyName -Default $null
    if ($null -eq $value) {
        throw "Missing required property: $PropertyName"
    }

    return $value
}

function Get-HNCollection {
    param($Value)

    if ($null -eq $Value) {
        return @()
    }

    if (($Value -is [System.Collections.IEnumerable]) -and -not ($Value -is [string])) {
        return @($Value)
    }

    return @($Value)
}

function ConvertTo-HNCanonicalString {
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
            $parts.Add((ConvertTo-HNCanonicalString ([string]$key)) + ':' + (ConvertTo-HNCanonicalString $Value[$key]))
        }
        return '{' + ($parts -join ',') + '}'
    }

    if (($Value -is [System.Collections.IEnumerable]) -and -not ($Value -is [string])) {
        $parts = New-Object System.Collections.Generic.List[string]
        foreach ($item in $Value) {
            $parts.Add((ConvertTo-HNCanonicalString $item))
        }
        return '[' + ($parts -join ',') + ']'
    }

    $propertyNames = @($Value.PSObject.Properties | Select-Object -ExpandProperty Name)
    if ($propertyNames.Count -gt 0) {
        $ordered = [ordered]@{}
        foreach ($prop in ($propertyNames | Sort-Object)) {
            $ordered[$prop] = Get-HNOptionalValue -Container $Value -PropertyName $prop
        }
        return ConvertTo-HNCanonicalString $ordered
    }

    return ConvertTo-HNCanonicalString ([string]$Value)
}

function ConvertTo-HNLiteral {
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

function New-HNPrimitiveLine {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$Arguments
    )

    $pairs = New-Object System.Collections.Generic.List[string]
    foreach ($key in $Arguments.Keys) {
        $pairs.Add(('{0}={1}' -f $key, (ConvertTo-HNLiteral $Arguments[$key])))
    }

    return '{0}({1})' -f $Name, ($pairs -join ',')
}

function Get-HNeronsSpec {
    $path = Get-HNeronsSpecPath
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Spec file not found: $path"
    }

    return (Get-Content -LiteralPath $path -Raw | ConvertFrom-Json)
}

function Measure-HNTokenEstimate {
    param(
        [AllowEmptyString()][string]$Text
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return 0
    }

    return @([regex]::Split($Text.Trim(), '\s+') | Where-Object { $_ }).Count
}

function Get-HNeronsPromptText {
    param(
        [Parameter(Mandatory = $true)]
        $Payload
    )

    $meta = Get-HNOptionalValue -Container $Payload -PropertyName 'META' -Default $null
    $candidates = @(
        (Get-HNOptionalValue -Container $Payload -PropertyName 'PROMPT_TEXT' -Default '')
        (Get-HNOptionalValue -Container $Payload -PropertyName 'DRAFT_TEXT' -Default '')
        (Get-HNOptionalValue -Container $meta -PropertyName 'INTENT' -Default '')
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }

    if ($candidates.Count -eq 0) {
        return ''
    }

    return [string]$candidates[0]
}
function Split-HNeronsDraft {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DraftText
    )

    $normalized = ($DraftText -replace '[\r\n]+', ' ').Trim()
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return @()
    }

    $parts = [regex]::Split($normalized, '(?<=[\.!?;])\s+') | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    return @($parts)
}

function Get-HNeronsClaimType {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    $normalized = $Text.ToLowerInvariant()

    if ($normalized -match '\b(loi|decret|reglement|directive|norme|iso|rgpd|gdpr|compliance|conformite)\b') {
        return 'RULE_REGULATORY'
    }

    if ($normalized -match '\b(compatible|compatibilite|supporte|support|version|plugin|api|sdk|postgresql|mysql|windows|linux|macos)\b') {
        return 'TECH_COMPAT'
    }

    if ($normalized -match '(\d+[\.,]?\d*\s?(eur|usd|%|pourcent|m eur|k eur|m\b|kwh|co2))|\b(chiffre d''affaires|revenue|revenu|prix|cout|cost|taux|volume|quota)\b') {
        return 'NUMERIC_VOLATILE'
    }

    if ($normalized -match '\b(202\d|20[3-9]\d|aujourd|hier|demain|recent|latest|release|released|cette semaine|ce mois|ce trimestre)\b') {
        return 'FACT_DYNAMIC'
    }

    if ($normalized -match '\b(selon|tendance|semble|probable|suggere|analyse|interprete)\b') {
        return 'INTERPRETIVE_CLAIM'
    }

    return 'FACT_STATIC'
}

function Test-HNeronsVerifiableClaim {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    $signalCount = 0

    if ($Text -match '\b[A-Z][\p{L}\p{Nd}_-]{2,}\b') {
        $signalCount++
    }

    if ($Text -match '\d') {
        $signalCount++
    }

    if ($Text.ToLowerInvariant() -match '\b(loi|decret|reglement|norme|iso|compatible|supporte|version|prix|taux|date|ceo|release|support)\b') {
        $signalCount++
    }

    return ($signalCount -ge 1 -and $Text.Trim().Length -ge 12)
}

function Get-HNeronsSanitizedQueryTerms {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    $sanitized = $Text -replace '\b[\w\.-]+@[\w\.-]+\.[A-Za-z]{2,}\b', ' ' -replace '\+?\d[\d\s\-\(\)]{7,}\d', ' '
    $stopWords = @('dans', 'avec', 'pour', 'sans', 'mais', 'plus', 'moins', 'tres', 'cela', 'cette', 'cet', 'sur', 'des', 'les', 'une', 'est', 'sont', 'the', 'and', 'with', 'from', 'that', 'this', 'before', 'after', 'entre', 'avant', 'apres')
    $tokens = [regex]::Matches($sanitized.ToLowerInvariant(), '[\p{L}\p{Nd}_-]{3,}') |
        ForEach-Object { $_.Value } |
        Where-Object { $stopWords -notcontains $_ } |
        Select-Object -First 8

    return ($tokens -join ' ')
}

function Get-HNeronsAuthorityWeight {
    param([string]$Tier)

    $normalized = ([string]$Tier).ToLowerInvariant()
    switch ($normalized) {
        'primary' { return 1.0 }
        'official' { return 0.95 }
        'recognized_secondary' { return 0.75 }
        'secondary' { return 0.55 }
        default { return 0.3 }
    }
}

function Get-HNeronsFreshnessWeight {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ClaimType,
        $FreshnessDays
    )

    $age = -1
    try {
        if ($null -ne $FreshnessDays) {
            $age = [int]$FreshnessDays
        }
    }
    catch {
        $age = -1
    }

    if ($age -lt 0) {
        return 0.6
    }

    switch ($ClaimType) {
        'FACT_STATIC' {
            if ($age -le 3650) { return 1.0 }
            return 0.85
        }
        'FACT_DYNAMIC' {
            if ($age -le 7) { return 1.0 }
            if ($age -le 30) { return 0.85 }
            if ($age -le 90) { return 0.65 }
            return 0.35
        }
        'NUMERIC_VOLATILE' {
            if ($age -le 7) { return 1.0 }
            if ($age -le 30) { return 0.85 }
            if ($age -le 90) { return 0.65 }
            return 0.3
        }
        'RULE_REGULATORY' {
            if ($age -le 30) { return 1.0 }
            if ($age -le 180) { return 0.85 }
            return 0.55
        }
        'TECH_COMPAT' {
            if ($age -le 30) { return 1.0 }
            if ($age -le 180) { return 0.8 }
            if ($age -le 365) { return 0.6 }
            return 0.4
        }
        'INTERPRETIVE_CLAIM' {
            if ($age -le 365) { return 0.8 }
            return 0.6
        }
        default {
            return 0.6
        }
    }
}

function Get-HNeronsSuggestedAction {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Status
    )

    switch ($Status) {
        'VERIFIED' { return 'ALLOW_NORMAL_FORMULATION' }
        'PARTIALLY_VERIFIED' { return 'LIMIT_SCOPE_AND_EXPLICIT_RESERVES' }
        'CONFLICT_DETECTED' { return 'PRESENT_CONFLICT_OR_REGENERATE_BOUNDED' }
        'UNSURE_EXTERNAL' { return 'DOWNGRADE_ASSERTIVENESS' }
        'UNSURE_EXPLICIT' { return 'BLOCK_STRONG_ASSERTION' }
        default { return 'FORWARD_UNCHANGED' }
    }
}
function Get-HNeronsEvidenceForClaim {
    param(
        [Parameter(Mandatory = $true)]
        $Claim,
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$Evidence
    )

    $matched = New-Object System.Collections.Generic.List[object]
    foreach ($item in $Evidence) {
        $claimIndex = Get-HNOptionalValue -Container $item -PropertyName 'claim_index' -Default $null
        if ($null -ne $claimIndex) {
            try {
                if ([int]$claimIndex -eq [int]$Claim.Index) {
                    $matched.Add($item)
                    continue
                }
            }
            catch {
            }
        }

        $claimHint = [string](Get-HNOptionalValue -Container $item -PropertyName 'claim_hint' -Default '')
        if (-not [string]::IsNullOrWhiteSpace($claimHint) -and $Claim.Text.ToLowerInvariant().Contains($claimHint.ToLowerInvariant())) {
            $matched.Add($item)
            continue
        }

        $snippet = [string](Get-HNOptionalValue -Container $item -PropertyName 'snippet' -Default '')
        if (-not [string]::IsNullOrWhiteSpace($snippet)) {
            $claimTokens = @($Claim.QueryTerms -split '\s+' | Where-Object { $_ })
            $commonTokens = @($claimTokens | Where-Object { $snippet.ToLowerInvariant().Contains($_) })
            if ($commonTokens.Count -ge 3) {
                $matched.Add($item)
            }
        }
    }

    return $matched.ToArray()
}

function Get-HNeronsClaims {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DraftText,
        $Context
    )

    $highImpact = [bool](Get-HNOptionalValue -Container $Context -PropertyName 'high_impact' -Default $false)
    $claims = New-Object System.Collections.Generic.List[object]
    $index = 0

    foreach ($sentence in (Split-HNeronsDraft -DraftText $DraftText)) {
        $index++
        $verifiable = Test-HNeronsVerifiableClaim -Text $sentence
        $claimType = if ($verifiable) { Get-HNeronsClaimType -Text $sentence } else { 'NON_VERIFIABLE' }
        $critical = $false
        if ($claimType -in @('RULE_REGULATORY', 'NUMERIC_VOLATILE')) {
            $critical = $true
        }
        elseif ($highImpact -and $verifiable) {
            $critical = $true
        }

        $claims.Add([pscustomobject]@{
                Index = $index
                Text = $sentence
                Verifiable = $verifiable
                Type = $claimType
                Critical = $critical
                QueryTerms = if ($verifiable) { Get-HNeronsSanitizedQueryTerms -Text $sentence } else { '' }
            })
    }

    return $claims.ToArray()
}

function Get-HNeronsClaimQualification {
    param(
        [Parameter(Mandatory = $true)]
        $Claim,
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$Evidence,
        $Context
    )

    $matchedEvidence = @(Get-HNeronsEvidenceForClaim -Claim $Claim -Evidence $Evidence)
    $contextHighImpact = [bool](Get-HNOptionalValue -Container $Context -PropertyName 'high_impact' -Default $false)
    $critical = [bool]$Claim.Critical -or $contextHighImpact

    $supportWeight = 0.0
    $conflictWeight = 0.0
    $partialEvidence = 0
    $scoredEvidence = New-Object System.Collections.Generic.List[object]

    foreach ($item in $matchedEvidence) {
        $sourceTier = [string](Get-HNOptionalValue -Container $item -PropertyName 'source_tier' -Default 'unknown')
        $stance = ([string](Get-HNOptionalValue -Container $item -PropertyName 'stance' -Default 'insufficient')).ToUpperInvariant()
        $authorityWeight = Get-HNeronsAuthorityWeight -Tier $sourceTier
        $freshnessWeight = Get-HNeronsFreshnessWeight -ClaimType $Claim.Type -FreshnessDays (Get-HNOptionalValue -Container $item -PropertyName 'freshness_days' -Default $null)
        $weight = [Math]::Round(($authorityWeight * $freshnessWeight), 4)

        switch ($stance) {
            'SUPPORTS' { $supportWeight += $weight }
            'PARTIAL' {
                $supportWeight += ($weight * 0.55)
                $partialEvidence++
            }
            'CONFLICTS' { $conflictWeight += $weight }
            default { }
        }

        $scoredEvidence.Add([pscustomobject]@{
                Id = [string](Get-HNOptionalValue -Container $item -PropertyName 'id' -Default '')
                SourceName = [string](Get-HNOptionalValue -Container $item -PropertyName 'source_name' -Default 'unknown_source')
                SourceTier = $sourceTier
                FreshnessDays = Get-HNOptionalValue -Container $item -PropertyName 'freshness_days' -Default $null
                Stance = $stance
                Weight = $weight
                Snippet = [string](Get-HNOptionalValue -Container $item -PropertyName 'snippet' -Default '')
                Url = [string](Get-HNOptionalValue -Container $item -PropertyName 'url' -Default '')
            })
    }

    $status = 'UNSURE_EXTERNAL'
    $reason = 'external_data_insufficient'
    $totalWeight = $supportWeight + $conflictWeight

    if ($scoredEvidence.Count -eq 0 -or $totalWeight -lt 0.45) {
        if ($critical) {
            $status = 'UNSURE_EXPLICIT'
            $reason = 'critical_claim_without_sufficient_verification'
        }
        else {
            $status = 'UNSURE_EXTERNAL'
            $reason = 'external_data_insufficient'
        }
    }
    elseif ($conflictWeight -ge 0.75 -and $conflictWeight -ge ($supportWeight * 0.75)) {
        $status = 'CONFLICT_DETECTED'
        $reason = 'conflicting_sources_detected'
    }
    elseif ($supportWeight -ge 1.35 -and $conflictWeight -lt 0.25) {
        $status = 'VERIFIED'
        $reason = 'weighted_support_consensus'
    }
    elseif ($supportWeight -ge 0.5) {
        $status = 'PARTIALLY_VERIFIED'
        $reason = 'support_present_but_scope_or_freshness_incomplete'
    }
    elseif ($critical) {
        $status = 'UNSURE_EXPLICIT'
        $reason = 'critical_claim_without_sufficient_verification'
    }

    $confidence = 0.25
    switch ($status) {
        'VERIFIED' { $confidence = 0.82 + [Math]::Min(0.16, ($supportWeight / 10.0)) - [Math]::Min(0.08, ($conflictWeight / 10.0)) }
        'PARTIALLY_VERIFIED' { $confidence = 0.56 + [Math]::Min(0.14, ($supportWeight / 10.0)) - [Math]::Min(0.08, ($conflictWeight / 10.0)) }
        'CONFLICT_DETECTED' { $confidence = 0.44 + [Math]::Min(0.16, (($supportWeight + $conflictWeight) / 10.0)) }
        'UNSURE_EXTERNAL' { $confidence = 0.25 }
        'UNSURE_EXPLICIT' { $confidence = 0.18 }
    }
    $confidence = [Math]::Round([Math]::Max(0.05, [Math]::Min(0.98, $confidence)), 2)

    $evidenceArray = $scoredEvidence.ToArray()

    return [pscustomobject]@{
        Index = $Claim.Index
        Text = $Claim.Text
        Type = $Claim.Type
        Critical = $critical
        QueryTerms = $Claim.QueryTerms
        Status = $status
        Confidence = $confidence
        Reason = $reason
        SuggestedAction = Get-HNeronsSuggestedAction -Status $status
        Evidence = $evidenceArray
        SourceCount = $evidenceArray.Count
        SupportWeight = [Math]::Round($supportWeight, 3)
        ConflictWeight = [Math]::Round($conflictWeight, 3)
        PartialEvidenceCount = $partialEvidence
    }
}
function ConvertTo-HNeronsRegulatedSentence {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Sentence,
        $Qualification,
        [bool]$Verifiable
    )

    if (-not $Verifiable -or $null -eq $Qualification) {
        return $Sentence
    }

    switch ([string]$Qualification.Status) {
        'VERIFIED' {
            return $Sentence
        }
        'PARTIALLY_VERIFIED' {
            return ('Verification partielle: {0} Des zones restent a confirmer.' -f $Sentence.Trim())
        }
        'CONFLICT_DETECTED' {
            return ('Conflit detecte sur ce point: {0} Les sources consultees ne convergent pas assez pour l''affirmer nettement.' -f $Sentence.Trim())
        }
        'UNSURE_EXTERNAL' {
            return ('Je ne peux pas confirmer de facon fiable ce point: {0}' -f $Sentence.Trim())
        }
        'UNSURE_EXPLICIT' {
            return ('Affirmation forte bloquee faute de verification suffisante: {0}' -f $Sentence.Trim())
        }
        default {
            return $Sentence
        }
    }
}

function Get-HNeronsRegulatedResponse {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$ClaimCandidates,
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$QualifiedClaims
    )

    $indexMap = @{}
    foreach ($claim in $QualifiedClaims) {
        $indexMap[[string]$claim.Index] = $claim
    }

    $lines = foreach ($candidate in $ClaimCandidates) {
        $qualification = $null
        if ($indexMap.ContainsKey([string]$candidate.Index)) {
            $qualification = $indexMap[[string]$candidate.Index]
        }

        ConvertTo-HNeronsRegulatedSentence -Sentence $candidate.Text -Qualification $qualification -Verifiable ([bool]$candidate.Verifiable)
    }

    return (($lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join ' ')
}

function New-HNeronsHgovPayload {
    param(
        [Parameter(Mandatory = $true)]
        $Payload,
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$QualifiedClaims
    )

    $meta = Get-HNRequiredValue -Container $Payload -PropertyName 'META'
    $inputContext = Get-HNOptionalValue -Container $Payload -PropertyName 'CONTEXT' -Default $null
    $facts = New-Object System.Collections.Generic.List[object]

    foreach ($claim in $QualifiedClaims) {
        $facts.Add([pscustomobject]@{
                key = ('claim_{0:00}' -f [int]$claim.Index)
                confidence = [double]$claim.Confidence
                source = if ($claim.SourceCount -gt 0) { 'external_evidence_bundle' } else { '' }
                external_claim = $true
            })
    }

    $recentTopic = [bool](Get-HNOptionalValue -Container $inputContext -PropertyName 'recent_topic' -Default $false)
    if (-not $recentTopic) {
        $recentTopic = (@($QualifiedClaims | Where-Object { $_.Type -in @('FACT_DYNAMIC', 'NUMERIC_VOLATILE', 'RULE_REGULATORY') }).Count -gt 0)
    }

    return [pscustomobject]@{
        META = [pscustomobject]@{
            MODE = [string](Get-HNOptionalValue -Container $meta -PropertyName 'MODE' -Default 'FACT_STRICT')
        }
        CONTEXT = [pscustomobject]@{
            recent_topic = $recentTopic
            premise_unverified = (@($QualifiedClaims | Where-Object { $_.Status -ne 'VERIFIED' }).Count -gt 0)
            conflict_with_canon = (@($QualifiedClaims | Where-Object { $_.Status -eq 'CONFLICT_DETECTED' }).Count -gt 0)
        }
        FACTS = $facts.ToArray()
    }
}

function New-HNeronsGlLines {
    param(
        [Parameter(Mandatory = $true)]
        $Payload,
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$QualifiedClaims,
        [Parameter(Mandatory = $true)]
        $Hgov
    )

    $limitLines = New-Object System.Collections.Generic.List[string]
    $assertLines = New-Object System.Collections.Generic.List[string]
    $factLines = New-Object System.Collections.Generic.List[string]
    $sourceLines = New-Object System.Collections.Generic.List[string]
    $refLines = New-Object System.Collections.Generic.List[string]
    $stateLines = New-Object System.Collections.Generic.List[string]
    $riskLines = New-Object System.Collections.Generic.List[string]
    $unsureLines = New-Object System.Collections.Generic.List[string]

    $limitLines.Add((New-HNPrimitiveLine -Name 'LIMIT' -Arguments ([ordered]@{ key = 'privacy'; rule = 'no_private_data_outbound' })))
    $limitLines.Add((New-HNPrimitiveLine -Name 'LIMIT' -Arguments ([ordered]@{ key = 'source_policy'; rule = 'prioritize_primary_and_official_sources' })))
    $limitLines.Add((New-HNPrimitiveLine -Name 'LIMIT' -Arguments ([ordered]@{ key = 'assertiveness'; rule = 'block_strong_claim_if_verification_insufficient' })))

    $assertLines.Add((New-HNPrimitiveLine -Name 'ASSERT' -Arguments ([ordered]@{ rule = 'claim_detection_executed'; pass = $true })))
    $assertLines.Add((New-HNPrimitiveLine -Name 'ASSERT' -Arguments ([ordered]@{ rule = 'regulation_before_emit'; pass = $true })))
    $assertLines.Add((New-HNPrimitiveLine -Name 'ASSERT' -Arguments ([ordered]@{ rule = 'lookup_queries_redacted'; pass = $true })))

    foreach ($claim in ($QualifiedClaims | Sort-Object Index)) {
        $claimKey = ('claim_{0:00}' -f [int]$claim.Index)
        $factLines.Add((New-HNPrimitiveLine -Name 'FACT' -Arguments ([ordered]@{
                        key = $claimKey
                        val = [string]$claim.Status
                        conf = [double]$claim.Confidence
                    })))
        $factLines.Add((New-HNPrimitiveLine -Name 'FACT' -Arguments ([ordered]@{
                        key = ($claimKey + '_type')
                        val = [string]$claim.Type
                        conf = [double]$claim.Confidence
                    })))

        $bestEvidence = @($claim.Evidence | Sort-Object Weight -Descending | Select-Object -First 1)
        if ($bestEvidence.Count -gt 0) {
            $sourceLines.Add((New-HNPrimitiveLine -Name 'SOURCE' -Arguments ([ordered]@{
                            key = $claimKey
                            ref = [string]$bestEvidence[0].SourceName
                        })))
            if (-not [string]::IsNullOrWhiteSpace([string]$bestEvidence[0].Id)) {
                $refLines.Add((New-HNPrimitiveLine -Name 'REF' -Arguments ([ordered]@{
                                key = $claimKey
                                id = [string]$bestEvidence[0].Id
                            })))
            }
        }

        if ([string]$claim.Status -ne 'VERIFIED') {
            $unsureLines.Add((New-HNPrimitiveLine -Name 'UNSURE' -Arguments ([ordered]@{
                            key = $claimKey
                            reason = [string]$claim.Reason
                            conf = [double]$claim.Confidence
                        })))
        }
    }

    $stateLines.Add((New-HNPrimitiveLine -Name 'STATE' -Arguments ([ordered]@{ name = 'CLAIM_COUNT'; val = [string]$QualifiedClaims.Count })))
    $stateLines.Add((New-HNPrimitiveLine -Name 'STATE' -Arguments ([ordered]@{ name = 'VERIFIED_COUNT'; val = [string](@($QualifiedClaims | Where-Object { $_.Status -eq 'VERIFIED' }).Count) })))
    $stateLines.Add((New-HNPrimitiveLine -Name 'STATE' -Arguments ([ordered]@{ name = 'PARTIAL_COUNT'; val = [string](@($QualifiedClaims | Where-Object { $_.Status -eq 'PARTIALLY_VERIFIED' }).Count) })))
    $stateLines.Add((New-HNPrimitiveLine -Name 'STATE' -Arguments ([ordered]@{ name = 'CONFLICT_COUNT'; val = [string](@($QualifiedClaims | Where-Object { $_.Status -eq 'CONFLICT_DETECTED' }).Count) })))
    $stateLines.Add((New-HNPrimitiveLine -Name 'STATE' -Arguments ([ordered]@{ name = 'POLICY'; val = [string]$Hgov.Policy })))
    $stateLines.Add((New-HNPrimitiveLine -Name 'STATE' -Arguments ([ordered]@{ name = 'DEGRADE_MODE'; val = [string]((@($QualifiedClaims | Where-Object { $_.Status -ne 'VERIFIED' }).Count -gt 0)) })))

    $riskLines.Add((New-HNPrimitiveLine -Name 'RISK' -Arguments ([ordered]@{ level = [string]$Hgov.RiskLevel })))

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

    return @($glLines)
}

function New-HNeronsGlgLines {
    param(
        [Parameter(Mandatory = $true)]
        $Payload,
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$QualifiedClaims,
        [Parameter(Mandatory = $true)]
        $Hgov,
        [Parameter(Mandatory = $true)]
        [string]$Hash,
        [Parameter(Mandatory = $true)]
        [string]$GlSnapshot
    )

    $meta = Get-HNRequiredValue -Container $Payload -PropertyName 'META'
    $routing = Get-HNRequiredValue -Container $Payload -PropertyName 'ROUTING'
    $uncertaintyFlag = if (@($QualifiedClaims | Where-Object { $_.Status -ne 'VERIFIED' }).Count -gt 0) { '1' } else { '0' }
    $statusSummary = (($QualifiedClaims | Sort-Object Index | ForEach-Object { ('{0}:{1}' -f ('{0:00}' -f [int]$_.Index), $_.Status) }) -join '|')

    $glgLines = New-Object System.Collections.Generic.List[string]
    $glgLines.Add((New-HNPrimitiveLine -Name 'IDX' -Arguments ([ordered]@{ key = [string](Get-HNOptionalValue -Container $meta -PropertyName 'ID' -Default 'H_NERONS_RUNTIME') })))
    $glgLines.Add((New-HNPrimitiveLine -Name 'TAG' -Arguments ([ordered]@{ ns = 'ORA'; name = 'H_NERONS' })))
    $glgLines.Add((New-HNPrimitiveLine -Name 'TAG' -Arguments ([ordered]@{ ns = 'MODE'; name = [string](Get-HNOptionalValue -Container $meta -PropertyName 'MODE' -Default 'FACT_STRICT') })))
    $glgLines.Add((New-HNPrimitiveLine -Name 'TAG' -Arguments ([ordered]@{ ns = 'CLAIMS'; name = if ($QualifiedClaims.Count -gt 0) { 'PRESENT' } else { 'NONE' } })))
    $glgLines.Add((New-HNPrimitiveLine -Name 'STAT' -Arguments ([ordered]@{ risk = [string]$Hgov.RiskLevel; uncertainty = $uncertaintyFlag })))
    $glgLines.Add((New-HNPrimitiveLine -Name 'HASH' -Arguments ([ordered]@{ algo = 'sha256'; val = $Hash })))
    $glgLines.Add((New-HNPrimitiveLine -Name 'ROUTE' -Arguments ([ordered]@{ module = [string](Get-HNOptionalValue -Container $routing -PropertyName 'module' -Default 'MODULE_H_NERONS_V1_0'); mode = [string](Get-HNOptionalValue -Container $routing -PropertyName 'mode' -Default 'FACT_STRICT') })))
    $glgLines.Add((New-HNPrimitiveLine -Name 'PACK' -Arguments ([ordered]@{ name = 'claim_count'; val = [string]$QualifiedClaims.Count })))
    $glgLines.Add((New-HNPrimitiveLine -Name 'PACK' -Arguments ([ordered]@{ name = 'policy'; val = [string]$Hgov.Policy })))
    $glgLines.Add((New-HNPrimitiveLine -Name 'PACK' -Arguments ([ordered]@{ name = 'status_summary'; val = $statusSummary })))
    $glgLines.Add((New-HNPrimitiveLine -Name 'PACK' -Arguments ([ordered]@{ name = 'gl_canon_b64'; val = $GlSnapshot })))

    return $glgLines.ToArray()
}
function Test-HNeronsResult {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$GlLines,
        [Parameter(Mandatory = $true)]
        [string]$RegulatedResponse,
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$QualifiedClaims
    )

    $issues = New-Object System.Collections.Generic.List[string]

    if ([string]::IsNullOrWhiteSpace($RegulatedResponse)) {
        $issues.Add('Regulated response is empty.')
    }

    if (Get-Command -Name Test-Gpv2GlOrder -ErrorAction SilentlyContinue) {
        if (-not (Test-Gpv2GlOrder -GlLines $GlLines)) {
            $issues.Add('GL order is invalid.')
        }
    }

    foreach ($claim in $QualifiedClaims) {
        if ([string]::IsNullOrWhiteSpace([string]$claim.Status)) {
            $issues.Add(('Claim {0} is missing a status.' -f $claim.Index))
        }
        if ([string]::IsNullOrWhiteSpace([string]$claim.QueryTerms)) {
            $issues.Add(('Claim {0} is missing query terms.' -f $claim.Index))
        }
    }

    return [pscustomobject]@{
        Pass = ($issues.Count -eq 0)
        Issues = @($issues)
    }
}

function Invoke-HNeronsAssessment {
    [CmdletBinding(DefaultParameterSetName = 'ByPath')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ByPath')]
        [string]$Path,
        [Parameter(Mandatory = $true, ParameterSetName = 'ByObject')]
        $Payload
    )

    Import-HNeronsBootstrapModule

    if ($PSCmdlet.ParameterSetName -eq 'ByPath') {
        $Payload = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    }

    $meta = Get-HNRequiredValue -Container $Payload -PropertyName 'META'
    [void](Get-HNRequiredValue -Container $meta -PropertyName 'ID')
    [void](Get-HNRequiredValue -Container $meta -PropertyName 'VERSION')
    [void](Get-HNRequiredValue -Container $meta -PropertyName 'MODE')
    [void](Get-HNRequiredValue -Container $Payload -PropertyName 'ROUTING')
    $draftText = [string](Get-HNRequiredValue -Container $Payload -PropertyName 'DRAFT_TEXT')

    $promptText = Get-HNeronsPromptText -Payload $Payload
    $context = Get-HNOptionalValue -Container $Payload -PropertyName 'CONTEXT' -Default $null
    $claimCandidates = @(Get-HNeronsClaims -DraftText $draftText -Context $context)
    $verifiableClaims = @($claimCandidates | Where-Object { $_.Verifiable })
    $evidence = @(Get-HNCollection (Get-HNOptionalValue -Container $Payload -PropertyName 'EXTERNAL_EVIDENCE' -Default @()))
    $evidenceInput = if ($evidence.Count -eq 0) { @([pscustomobject]@{}) } else { $evidence }
    $qualifiedClaims = @($verifiableClaims | ForEach-Object { Get-HNeronsClaimQualification -Claim $_ -Evidence $evidenceInput -Context $context })
    $lookupPlan = @($verifiableClaims | ForEach-Object {
            [pscustomobject]@{
                Index = $_.Index
                Type = $_.Type
                QueryTerms = $_.QueryTerms
                RequiresExternalCheck = $true
                PrivacySafe = $true
            }
        })
    $regulatedResponse = Get-HNeronsRegulatedResponse -ClaimCandidates $claimCandidates -QualifiedClaims $qualifiedClaims
    $hgovPayload = New-HNeronsHgovPayload -Payload $Payload -QualifiedClaims $qualifiedClaims
    $hgov = Invoke-HgovAssessment -Payload $hgovPayload
    $glLines = New-HNeronsGlLines -Payload $Payload -QualifiedClaims $qualifiedClaims -Hgov $hgov

    $canonicalJson = ConvertTo-HNCanonicalString $Payload
    $glCanonicalText = $glLines -join "`n"
    $hashInput = @(
        [string](Get-HNOptionalValue -Container $meta -PropertyName 'ID' -Default 'H_NERONS_RUNTIME')
        [string](Get-HNOptionalValue -Container $meta -PropertyName 'VERSION' -Default '1.0.0')
        [string](Get-HNOptionalValue -Container $meta -PropertyName 'MODE' -Default 'FACT_STRICT')
        $canonicalJson
        $glCanonicalText
        $regulatedResponse
    ) -join "`n---`n"
    $hash = New-Gpv2Hash -Text $hashInput
    $glSnapshot = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($glCanonicalText))
    $glgLines = New-HNeronsGlgLines -Payload $Payload -QualifiedClaims $qualifiedClaims -Hgov $hgov -Hash $hash -GlSnapshot $glSnapshot
    $validation = Test-HNeronsResult -GlLines $glLines -RegulatedResponse $regulatedResponse -QualifiedClaims $qualifiedClaims
    $spec = Get-HNeronsSpec

    $status = [pscustomobject]@{
        Ready = [bool]$validation.Pass
        RiskLevel = [string]$hgov.RiskLevel
        Policy = [string]$hgov.Policy
        ClaimCount = [int]$qualifiedClaims.Count
        VerifiedCount = [int](@($qualifiedClaims | Where-Object { $_.Status -eq 'VERIFIED' }).Count)
        PartialCount = [int](@($qualifiedClaims | Where-Object { $_.Status -eq 'PARTIALLY_VERIFIED' }).Count)
        ConflictCount = [int](@($qualifiedClaims | Where-Object { $_.Status -eq 'CONFLICT_DETECTED' }).Count)
        UnsureCount = [int](@($qualifiedClaims | Where-Object { $_.Status -like 'UNSURE_*' }).Count)
        Degraded = (@($qualifiedClaims | Where-Object { $_.Status -ne 'VERIFIED' }).Count -gt 0)
        Hash = $hash
    }

    $packet = [pscustomobject]@{
        META = [pscustomobject]@{
            ID = [string](Get-HNOptionalValue -Container $meta -PropertyName 'ID' -Default 'H_NERONS_RUNTIME')
            VERSION = [string](Get-HNOptionalValue -Container $meta -PropertyName 'VERSION' -Default '1.0.0')
            MODE = [string](Get-HNOptionalValue -Container $meta -PropertyName 'MODE' -Default 'FACT_STRICT')
            HASH = $hash
        }
        JSON = $Payload
        CLAIM_AUDIT = @($qualifiedClaims)
        LOOKUP_PLAN = @($lookupPlan)
        REGULATED_RESPONSE = $regulatedResponse
        HGOV = $hgov
        GL = @($glLines)
        GL_G = @($glgLines)
    }
    $packet | Add-Member -MemberType NoteProperty -Name VALIDATION -Value $validation

    $result = [pscustomobject]@{
        Spec = $spec.GPV2
        Status = $status
        Claims = @($qualifiedClaims)
        LookupPlan = @($lookupPlan)
        HGOV = $hgov
        Validation = $validation
        RegulatedResponse = $regulatedResponse
        Packet = $packet
    }

    $script:SessionState.Active = $true
    $script:SessionState.RunCount = [int]$script:SessionState.RunCount + 1
    $script:SessionState.LastRunAt = (Get-Date).ToString('s')
    $script:SessionState.LastPromptText = $promptText
    $script:SessionState.LastResult = $result

    return $result
}

function Get-HNeronsStatus {
    if (-not $script:SessionState.Active -or $null -eq $script:SessionState.LastResult) {
        return [pscustomobject]@{
            Active = $false
            RunCount = [int]$script:SessionState.RunCount
            LastRunAt = $script:SessionState.LastRunAt
            Message = 'No H-NERONS assessment in session.'
        }
    }

    return [pscustomobject]@{
        Active = $true
        RunCount = [int]$script:SessionState.RunCount
        LastRunAt = $script:SessionState.LastRunAt
        PromptText = $script:SessionState.LastPromptText
        Status = $script:SessionState.LastResult.Status
        HGOV = $script:SessionState.LastResult.HGOV
    }
}

function Get-HNeronsTrace {
    [CmdletBinding()]
    param(
        [switch]$Detailed
    )

    if (-not $script:SessionState.Active -or $null -eq $script:SessionState.LastResult) {
        throw 'No H-NERONS trace available. Run an assessment first.'
    }

    if ($Detailed) {
        return $script:SessionState.LastResult
    }

    return [pscustomobject]@{
        Claims = $script:SessionState.LastResult.Claims
        LookupPlan = $script:SessionState.LastResult.LookupPlan
        Validation = $script:SessionState.LastResult.Validation
        Packet = $script:SessionState.LastResult.Packet
    }
}

function Reset-HNeronsSession {
    $script:SessionState.Active = $false
    $script:SessionState.RunCount = 0
    $script:SessionState.LastRunAt = $null
    $script:SessionState.LastPromptText = $null
    $script:SessionState.LastResult = $null

    return [pscustomobject]@{
        Reset = $true
    }
}

Export-ModuleMember -Function Get-HNeronsSpec, Get-HNeronsClaims, Invoke-HNeronsAssessment, Get-HNeronsStatus, Get-HNeronsTrace, Reset-HNeronsSession







