param (
    [string]$JtlFile,
    [string]$HistoryFile,
    [string]$BuildNumber,
    [string]$Environment,
    [string]$Threads,
    [string]$RampUp
)

Write-Host "===== SAVING PERFORMANCE HISTORY ====="

if (-not (Test-Path $JtlFile)) {
    Write-Host "ERROR: JTL file not found: $JtlFile"
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
    Write-Host "ERROR: No valid elapsed values found."
    exit 1
}

$sortedTimes = $elapsedTimes | Sort-Object

$index = [math]::Ceiling(0.95 * $sortedTimes.Count) - 1

if ($index -lt 0) {
    $index = 0
}

$percentile95 = $sortedTimes[$index]

if (-not (Test-Path $HistoryFile)) {
    "Build,Environment,Threads,RampUp,TotalSamples,FailedSamples,ErrorRate,95thPercentile,Result" |
        Set-Content $HistoryFile
}

$line = "$BuildNumber,$Environment,$Threads,$RampUp,$totalSamples,$failedSamples,$([math]::Round($errorRate,2)),$([math]::Round($percentile95,2)),PASS"

Add-Content -Path $HistoryFile -Value $line

Write-Host "Build Number       = $BuildNumber"
Write-Host "Environment        = $Environment"
Write-Host "Threads            = $Threads"
Write-Host "Ramp-Up            = $RampUp"
Write-Host "Total Samples      = $totalSamples"
Write-Host "Failed Samples     = $failedSamples"
Write-Host "Error Rate         = $([math]::Round($errorRate,2))%"
Write-Host "95th Percentile    = $([math]::Round($percentile95,2)) ms"
Write-Host ""
Write-Host "Performance history updated successfully."
Write-Host "===== PERFORMANCE HISTORY SAVED ====="

exit 0