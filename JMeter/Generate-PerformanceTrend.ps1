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

$data = @(Import-Csv $HistoryFile)

if ($data.Count -eq 0) {
    Write-Host "ERROR: Performance history is empty."
    exit 1
}

# Sort builds numerically
$data = @(
    $data | Sort-Object {
        [int]$_.Build
    }
)

# Prepare table rows
$rows = ""

foreach ($row in $data) {

    if ($row.Result -eq "PASS") {
        $resultClass = "pass"
    }
    else {
        $resultClass = "fail"
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

# Prepare chart data
$buildLabels = @()
$p95Values = @()

foreach ($row in $data) {
    $buildLabels += "'Build $($row.Build)'"
    $p95Values += [double]$row.'95thPercentile'
}

$labelsString = $buildLabels -join ","
$p95String = $p95Values -join ","

$latest = $data[-1]

$html = @"
<!DOCTYPE html>

<html>

<head>

<meta charset="UTF-8">

<title>JMeter Performance Trend Report</title>

<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

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

.summary-grid {
    display: grid;
    grid-template-columns: repeat(5, 1fr);
    gap: 15px;
}

.card {
    background-color: #f8f8f8;
    padding: 15px;
    border-radius: 6px;
    text-align: center;
}

.card-title {
    font-size: 13px;
    color: #666666;
}

.card-value {
    font-size: 22px;
    font-weight: bold;
    margin-top: 8px;
}

.chart-container {
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

<div class="summary-grid">

<div class="card">
<div class="card-title">Total Builds</div>
<div class="card-value">$($data.Count)</div>
</div>

<div class="card">
<div class="card-title">Latest Build</div>
<div class="card-value">$($latest.Build)</div>
</div>

<div class="card">
<div class="card-title">Latest Environment</div>
<div class="card-value">$($latest.Environment)</div>
</div>

<div class="card">
<div class="card-title">Latest P95</div>
<div class="card-value">$($latest.'95thPercentile') ms</div>
</div>

<div class="card">
<div class="card-title">Latest Result</div>
<div class="card-value">$($latest.Result)</div>
</div>

</div>

</div>

<div class="chart-container">

<h2>95th Percentile Response Time Trend</h2>

<canvas id="p95Chart"></canvas>

</div>

<h2>Performance History</h2>

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

<script>

const labels = [$labelsString];

const p95Values = [$p95String];

const ctx = document.getElementById('p95Chart');

new Chart(ctx, {
    type: 'line',

    data: {
        labels: labels,

        datasets: [{
            label: '95th Percentile Response Time (ms)',

            data: p95Values,

            borderWidth: 3,

            tension: 0.3,

            fill: false,

            pointRadius: 5
        }]
    },

    options: {

        responsive: true,

        scales: {

            y: {
                beginAtZero: true,

                title: {
                    display: true,
                    text: 'Response Time (ms)'
                }
            },

            x: {
                title: {
                    display: true,
                    text: 'Jenkins Build'
                }
            }

        }

    }
});

</script>

</body>

</html>
"@

Set-Content -Path $OutputFile -Value $html -Encoding UTF8

Write-Host ""
Write-Host "Performance trend report generated successfully."
Write-Host "Output file: $OutputFile"
Write-Host "===== PERFORMANCE TREND REPORT COMPLETED ====="

exit 0