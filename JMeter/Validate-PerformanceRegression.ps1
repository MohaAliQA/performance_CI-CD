param (
    [string]$HistoryFile,
    [int]$CurrentBuildNumber,
    [double]$AllowedDegradationPercent = 50
)

Write-Host "===== PERFORMANCE REGRESSION VALIDATION ====="

if (-not (Test-Path $HistoryFile)) {
    Write-Host "ERROR: Performance history file not found:"
    Write-Host $HistoryFile
    exit 1
}

$data = Import-Csv $HistoryFile

if (-not $data -or $data.Count -eq 0) {
    Write-Host "ERROR: Performance history is empty."
    exit 1
}

$currentRows = @(
    $data | Where-Object {
        [int]$_.Build -eq $CurrentBuildNumber
    }
)

if ($currentRows.Count -eq 0) {
    Write-Host "ERROR: Current build $CurrentBuildNumber not found in history."
    exit 1
}

$currentRow = $currentRows[-1]

$currentP95 = [double]$currentRow.'95thPercentile'

Write-Host ""
Write-Host "Current Build       = $CurrentBuildNumber"
Write-Host "Current P95         = $currentP95 ms"

$previousRows = @(
    $data | Where-Object {
        [int]$_.Build -lt $CurrentBuildNumber -and
        $_.Result -eq 'PASS'
    }
)

if ($previousRows.Count -eq 0) {
    Write-Host ""
    Write-Host "No previous successful build found."
    Write-Host "Regression validation skipped for baseline build."
    Write-Host "===== REGRESSION VALIDATION PASSED ====="
    exit 0
}

$previousRows = $previousRows | Sort-Object {
    [int]$_.Build
}

$baselineRow = $previousRows[-1]

$baselineBuild = [int]$baselineRow.Build
$baselineP95 = [double]$baselineRow.'95thPercentile'

$maximumAcceptableP95 =
    $baselineP95 * (1 + ($AllowedDegradationPercent / 100))

Write-Host "Baseline Build      = $baselineBuild"
Write-Host "Baseline P95        = $baselineP95 ms"
Write-Host "Allowed Degradation = $AllowedDegradationPercent%"
Write-Host "Maximum P95 Allowed = $([math]::Round($maximumAcceptableP95,2)) ms"
Write-Host ""

if ($currentP95 -gt $maximumAcceptableP95) {

    Write-Host "PERFORMANCE REGRESSION DETECTED"
    Write-Host "Current P95 $currentP95 ms exceeds allowed $([math]::Round($maximumAcceptableP95,2)) ms"

    # Mark current build as FAILED in performance history
    $currentRow.Result = 'FAIL'

    $updatedData = @(
        $data | ForEach-Object {
            if ([int]$_.Build -eq $CurrentBuildNumber) {
                $currentRow
            }
            else {
                $_
            }
        }
    )

    $updatedData | Export-Csv -Path $HistoryFile -NoTypeInformation

    Write-Host "Build $CurrentBuildNumber marked as FAIL in performance history."

    exit 1
}

Write-Host "NO PERFORMANCE REGRESSION DETECTED"
Write-Host "Current P95 $currentP95 ms is within the allowed limit."

Write-Host "===== REGRESSION VALIDATION PASSED ====="

exit 0