[CmdletBinding()]
param(
    [ValidateSet("Console", "Web")]
    [string]$Mode = "Web",
    [int]$Port = 8899
)

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$Vibe = Join-Path $ProjectRoot "envs\vibe\Scripts\vibe-trading.exe"
if (-not (Test-Path -LiteralPath $Vibe)) {
    throw "Vibe-Trading 尚未安装。"
}
$env:VIBE_TRADING_HOME = Join-Path $ProjectRoot "runtime\vibe"
Push-Location $ProjectRoot
try {
    if ($Mode -eq "Console") {
        & $Vibe
    } else {
        Write-Host "Vibe-Trading 将仅监听本机：http://127.0.0.1:$Port"
        & $Vibe serve --host 127.0.0.1 --port $Port
    }
} finally { Pop-Location }
