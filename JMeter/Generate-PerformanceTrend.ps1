param (
    [string]$HistoryFile,
    [string]$OutputFile
)

Write-Host "===== GENERATING PERFORMANCE TREND REPORT ====="

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

$rows = ""

foreach ($row in $data) {

    $resultClass = if ($row.Result -eq "PASS") {
        "pass"
    }
    else {
        "fail"
    }

    $rows += @"
<tr>
    <td>$($row.Build)</td>
    <td>$($row.Environment)</td>
    <td>$($row.Threads)</td>
    <td>$($row.RampUp)</td>
    <td>$($row.TotalSamples)</td>
    <td>$($row.FailedSamples)</td>
    <td>$($row.ErrorRate)%</td>
    <td>$($row.'95thPercentile') ms</td>
    <td class="$resultClass">$($row.Result)</td>
</tr>
"@
}

$html = @"
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">

<title>JMeter Performance Trend Report</title>

<style>

body {
    font-family: Arial, sans-serif;
    margin: 30px;
    background-color: #f5f5f5;
}

h1 {
    color: #333333;
}

.summary {
    background-color: white;
    padding: 20px;
    margin-bottom: 20px;
    border-radius: 8px;
}

table {
    width: 100%;
    border-collapse: collapse;
    background-color: white;
}

th {
    background-color: #333333;
    color: white;
    padding: 10px;
}

td {
    border: 1px solid #dddddd;
    padding: 10px;
    text-align: center;
}

.pass {
    color: green;
    font-weight: bold;
}

.fail {
    color: red;
    font-weight: bold;
}

</style>

</head>

<body>

<h1>JMeter Performance Trend Report</h1>

<div class="summary">

<p><b>Total Builds:</b> $($data.Count)</p>

<p><b>Latest Build:</b> $($data[-1].Build)</p>

<p><b>Latest Environment:</b> $($data[-1].Environment)</p>

<p><b>Latest P95:</b> $($data[-1].'95thPercentile') ms</p>

<p><b>Latest Result:</b> $($data[-1].Result)</p>

</div>

<table>

<tr>
    <th>Build</th>
    <th>Environment</th>
    <th>Threads</th>
    <th>Ramp-Up</th>
    <th>Total Samples</th>
    <th>Failed Samples</th>
    <th>Error Rate</th>
    <th>95th Percentile</th>
    <th>Result</th>
</tr>

$rows

</table>

</body>
</html>
"@

Set-Content -Path $OutputFile -Value $html -Encoding UTF8

Write-Host ""
Write-Host "Trend report generated successfully."
Write-Host "Output file: $OutputFile"
Write-Host "===== PERFORMANCE TREND REPORT COMPLETED ====="

exit 0