$RepoRoot = Split-Path $PSScriptRoot -Parent
$JtlFile = Join-Path $RepoRoot "jenkins_results.jtl"

$MaxErrorRate = 1.0

Write-Host "===== JMETER ERROR RATE VALIDATION ====="
Write-Host "JTL File = $JtlFile"

if (-not (Test-Path $JtlFile)) {
    Write-Host "ERROR: JTL file not found: $JtlFile"
    exit 1
}

$data = Import-Csv $JtlFile

$totalSamples = @($data).Count

$failedSamples = @(
    $data | Where-Object {
        $_.success -eq "false"
    }
).Count

if ($totalSamples -eq 0) {
    Write-Host "ERROR: JTL file contains no samples."
    exit 1
}

$errorRate = ($failedSamples * 100.0) / $totalSamples
$errorRate = [math]::Round($errorRate, 2)

Write-Host "Total Samples       = $totalSamples"
Write-Host "Failed Samples      = $failedSamples"
Write-Host "Error Rate          = $errorRate%"
Write-Host "Maximum Allowed     = $MaxErrorRate%"

if ($errorRate -gt $MaxErrorRate) {
    Write-Host "===== ERROR RATE VALIDATION FAILED ====="
    exit 1
}

Write-Host "===== ERROR RATE VALIDATION PASSED ====="
exit 0