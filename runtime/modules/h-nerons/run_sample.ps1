Set-StrictMode -Version Latest

$modulePath = Join-Path $PSScriptRoot 'h_nerons_runtime.psm1'
$samplePath = Join-Path $PSScriptRoot 'sample_payload.json'

Import-Module $modulePath -Force
Invoke-HNeronsAssessment -Path $samplePath | ConvertTo-Json -Depth 8
