Set-StrictMode -Version Latest

$modulePath = Join-Path $PSScriptRoot '..\runtime\modules\h-nerons\h_nerons_runtime.psm1'
$samplePath = Join-Path $PSScriptRoot '..\runtime\modules\h-nerons\sample_payload.json'

Import-Module $modulePath -Force

$sample = Invoke-HNeronsAssessment -Path $samplePath
if (-not $sample.Validation.Pass) {
    throw ('Sample payload failed validation: ' + ($sample.Validation.Issues -join '; '))
}
if ($sample.Status.VerifiedCount -ne 1) {
    throw 'Expected 1 VERIFIED claim in sample payload.'
}
if ($sample.Status.ConflictCount -ne 1) {
    throw 'Expected 1 CONFLICT_DETECTED claim in sample payload.'
}
if ($sample.Status.UnsureCount -ne 1) {
    throw 'Expected 1 UNSURE_* claim in sample payload.'
}
if (@($sample.Packet.GL_G | Where-Object { $_ -like 'HASH(*' }).Count -ne 1) {
    throw 'Expected one HASH primitive in GL_G output.'
}

$partialPayload = [pscustomobject]@{
    META = [pscustomobject]@{
        ID = 'H_NERONS_PARTIAL_001'
        VERSION = '1.0.0'
        MODE = 'FACT_STRICT'
        INTENT = 'Verifier une assertion avec validation partielle.'
    }
    DRAFT_TEXT = 'Le support premium HelixCloud est disponible 24/7.'
    CONTEXT = [pscustomobject]@{
        recent_topic = $true
        premise_unverified = $false
        conflict_with_canon = $false
        high_impact = $false
    }
    ROUTING = [pscustomobject]@{
        module = 'MODULE_H_NERONS_V1_0'
        mode = 'FACT_STRICT'
    }
    EXTERNAL_EVIDENCE = @(
        [pscustomobject]@{
            id = 'SRC-P1'
            claim_index = 1
            source_name = 'HelixCloud SLA'
            source_tier = 'official'
            freshness_days = 14
            stance = 'partial'
            snippet = 'The premium tier offers 24/5 support and 24/7 only for critical incidents.'
        }
    )
}
$partial = Invoke-HNeronsAssessment -Payload $partialPayload
if ($partial.Claims[0].Status -ne 'PARTIALLY_VERIFIED') {
    throw 'Expected PARTIALLY_VERIFIED status for partial evidence payload.'
}

$redactionPayload = [pscustomobject]@{
    META = [pscustomobject]@{
        ID = 'H_NERONS_REDACTION_001'
        VERSION = '1.0.0'
        MODE = 'FACT_STRICT'
        INTENT = 'Verifier qu une adresse email ne sort pas dans les query terms.'
    }
    DRAFT_TEXT = 'HelixCloud fournit un support via admin@example.com en moins de 30 minutes.'
    CONTEXT = [pscustomobject]@{
        recent_topic = $true
        premise_unverified = $false
        conflict_with_canon = $false
        high_impact = $false
    }
    ROUTING = [pscustomobject]@{
        module = 'MODULE_H_NERONS_V1_0'
        mode = 'FACT_STRICT'
    }
}
$redaction = Invoke-HNeronsAssessment -Payload $redactionPayload
if ($redaction.LookupPlan[0].QueryTerms -match '@') {
    throw 'Email address leaked into query terms.'
}

[pscustomobject]@{
    sample = $sample.Status
    partial = $partial.Claims[0].Status
    redaction_query = $redaction.LookupPlan[0].QueryTerms
} | ConvertTo-Json -Depth 6
