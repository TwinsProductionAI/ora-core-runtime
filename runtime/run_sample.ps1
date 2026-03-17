param(
    [string]$InputPath = (Join-Path $PSScriptRoot 'sample_payload.json'),
    [string]$OutputPath = (Join-Path $PSScriptRoot 'sample_output.json')
)

Import-Module (Join-Path $PSScriptRoot 'gpv2_runtime.psm1') -Force
$packet = Invoke-Gpv2Compile -Path $InputPath
$packet | ConvertTo-Json -Depth 8 | Set-Content -Path $OutputPath -Encoding UTF8
$packet | ConvertTo-Json -Depth 8
