[CmdletBinding()]
param([string]$ReportPath = "")

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$BacktestRoot = Join-Path $ProjectRoot "reports\backtests"
$SharedRoot = Join-Path $ProjectRoot "reports\shared"
New-Item -ItemType Directory -Force -Path $SharedRoot | Out-Null

if (-not $ReportPath) {
    $Latest = Get-ChildItem -LiteralPath $BacktestRoot -Filter "*.md" -File |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($null -eq $Latest) { throw "No local Markdown backtest report was found." }
    $Source = $Latest
} else {
    $Source = Get-Item -LiteralPath $ReportPath
}
$Content = Get-Content -Raw -LiteralPath $Source.FullName
$Forbidden = @("api[_ -]?key", "access[_ -]?token", "refresh[_ -]?token", "account[_ -]?(number|id)")
foreach ($Pattern in $Forbidden) {
    if ($Content -match $Pattern) { throw "The report contains a forbidden sensitive field: $Pattern" }
}
$Destination = Join-Path $SharedRoot $Source.Name
Copy-Item -LiteralPath $Source.FullName -Destination $Destination -Force
Write-Host "Shared report exported: $Destination" -ForegroundColor Green
