[CmdletBinding()]
param(
    [ValidateSet("Dashboard", "Research")]
    [string]$Mode = "Dashboard",
    [string]$Ticker = "SPY"
)

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$AgentRoot = Join-Path $ProjectRoot "vendor\AgentQuant"
$Python = Join-Path $ProjectRoot "envs\agentquant\Scripts\python.exe"
$Streamlit = Join-Path $ProjectRoot "envs\agentquant\Scripts\streamlit.exe"
if (-not (Test-Path -LiteralPath $Python) -or -not (Test-Path -LiteralPath $AgentRoot)) {
    throw "AgentQuant 尚未完整安装。"
}
$env:PYTHONPATH = $AgentRoot
Push-Location $AgentRoot
try {
    if ($Mode -eq "Dashboard") {
        & $Streamlit run run_app.py --server.address 127.0.0.1 --server.port 8501
    } else {
        & $Python -m src.cli run --ticker $Ticker --trace
    }
} finally { Pop-Location }
