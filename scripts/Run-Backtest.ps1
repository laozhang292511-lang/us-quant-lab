[CmdletBinding()]
param(
    [string]$Start = "2010-01-01",
    [string]$End = "",
    [switch]$Offline
)

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$Python = Join-Path $ProjectRoot "envs\core\Scripts\python.exe"
if (-not (Test-Path -LiteralPath $Python)) {
    throw "核心环境尚未安装，请先运行 scripts\Setup-Environments.ps1"
}

$Arguments = @("-m", "quant_lab.cli", "--start", $Start)
if ($End) { $Arguments += @("--end", $End) }
if ($Offline) { $Arguments += "--offline" }

Push-Location $ProjectRoot
try {
    $env:PYTHONPATH = Join-Path $ProjectRoot "src"
    & $Python @Arguments
} finally { Pop-Location }
