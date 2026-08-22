param (
    [string]$JtlFile,
    [double]$MaximumErrorRate = 1.0,
    [double]$Maximum95thPercentile = 2000
)

Write-Host "===== JMETER SLA VALIDATION ====="

if (-not $JtlFile) {
    Write-Host "ERROR: JTL file path was not provided."
    exit 1
}

if (-not (Test-Path $JtlFile)) {
    Write-Host "ERROR: JTL file not found:"
    Write-Host $JtlFile
    exit 1
}

$data = Import-Csv $JtlFile

if (-not $data -or $data.Count -eq 0) {
    Write-Host "ERROR: JTL file contains no samples."
    exit 1
}

$totalSamples = $data.Count

$failedSamples = @(
    $data | Where-Object {
        $_.success -eq 'false'
    }
).Count

$errorRate = ($failedSamples * 100.0) / $totalSamples

$elapsedTimes = @(
    $data |
    Where-Object {
        $_.elapsed -match '^\d+$'
    } |
    ForEach-Object {
        [double]$_.elapsed
    }
)

if ($elapsedTimes.Count -eq 0) {
    Write-Host "ERROR: No valid elapsed response-time values found."
    exit 1
}

$sortedTimes = $elapsedTimes | Sort-Object

$index = [math]::Ceiling(0.95 * $sortedTimes.Count) - 1

if ($index -lt 0) {
    $index = 0
}

$percentile95 = $sortedTimes[$index]

Write-Host ""
Write-Host "Total Samples              = $totalSamples"
Write-Host "Failed Samples             = $failedSamples"
Write-Host "Error Rate                 = $([math]::Round($errorRate,2))%"
Write-Host "95th Percentile Response   = $([math]::Round($percentile95,2)) ms"
Write-Host "Maximum Allowed Error Rate = $MaximumErrorRate%"
Write-Host "Maximum Allowed 95th SLA   = $Maximum95thPercentile ms"
Write-Host ""

if ($errorRate -gt $MaximumErrorRate) {
    Write-Host "ERROR RATE SLA FAILED"
    exit 1
}

if ($percentile95 -gt $Maximum95thPercentile) {
    Write-Host "RESPONSE TIME SLA FAILED"
    exit 1
}

Write-Host "===== SLA VALIDATION PASSED ====="
exit 0