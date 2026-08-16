$ProjectRoot = Split-Path -Parent $PSScriptRoot
$Failures = 0

Write-Host "[1/4] 母版核心测试"
$env:PYTHONPATH = Join-Path $ProjectRoot "src"
Push-Location $ProjectRoot
& (Join-Path $ProjectRoot "envs\core\Scripts\python.exe") -m pytest -q
if ($LASTEXITCODE -ne 0) { $Failures++ }
& (Join-Path $ProjectRoot "envs\core\Scripts\python.exe") -m ruff check src tests
if ($LASTEXITCODE -ne 0) { $Failures++ }
Pop-Location

Write-Host "[2/4] Vibe-Trading"
& (Join-Path $ProjectRoot "envs\vibe\Scripts\vibe-trading.exe") --version
if ($LASTEXITCODE -ne 0) { $Failures++ }

Write-Host "[3/4] Lumibot 与 Schwab 适配器"
$env:LUMIBOT_CACHE_FOLDER = Join-Path $ProjectRoot "data\lumibot-cache"
& (Join-Path $ProjectRoot "envs\lumibot\Scripts\python.exe") -c "import lumibot; from lumibot.brokers import Schwab; print(lumibot.__version__)"
if ($LASTEXITCODE -ne 0) { $Failures++ }

Write-Host "[4/4] AgentQuant 测试"
$AgentRoot = Join-Path $ProjectRoot "vendor\AgentQuant"
$env:PYTHONPATH = $AgentRoot
Push-Location $AgentRoot
& (Join-Path $ProjectRoot "envs\agentquant\Scripts\python.exe") -m pytest -q
if ($LASTEXITCODE -ne 0) { $Failures++ }
Pop-Location

if ($Failures -gt 0) { throw "验收失败项数: $Failures" }
Write-Host "全部验收通过。"
