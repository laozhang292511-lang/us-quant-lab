$ProjectRoot = Split-Path -Parent $PSScriptRoot
$Utf8 = New-Object Text.UTF8Encoding($false)
[Console]::InputEncoding = $Utf8
[Console]::OutputEncoding = $Utf8
$OutputEncoding = $Utf8
$env:PYTHONUTF8 = "1"
$Failures = 0
$RunId = "{0}-{1}" -f ([DateTime]::UtcNow.ToString("yyyyMMddHHmmss")), $PID
$TestRoot = Join-Path $ProjectRoot "runtime\test-temp\$RunId"
$CoreTemp = Join-Path $TestRoot "core"
$AgentTemp = Join-Path $TestRoot "agentquant"
New-Item -ItemType Directory -Force -Path $CoreTemp, $AgentTemp | Out-Null
$env:RUFF_CACHE_DIR = Join-Path $TestRoot "ruff-cache"

Write-Host "[预检] Windows PowerShell 5.1 脚本兼容性"
$WindowsPowerShell = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
& $WindowsPowerShell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Test-PowerShell5Compatibility.ps1")
if ($LASTEXITCODE -ne 0) { $Failures++ }

Write-Host "[1/4] 母版核心测试"
$env:PYTHONPATH = Join-Path $ProjectRoot "src"
Push-Location $ProjectRoot
& (Join-Path $ProjectRoot "envs\core\Scripts\python.exe") -m pytest -q -p no:cacheprovider --basetemp $CoreTemp
if ($LASTEXITCODE -ne 0) { $Failures++ }
& (Join-Path $ProjectRoot "envs\core\Scripts\python.exe") -m ruff check src tests
if ($LASTEXITCODE -ne 0) { $Failures++ }
Pop-Location

Write-Host "[2/4] Vibe-Trading"
& (Join-Path $ProjectRoot "envs\vibe\Scripts\vibe-trading.exe") --version
if ($LASTEXITCODE -ne 0) { $Failures++ }

Write-Host "[3/4] Lumibot 与 Schwab 适配器"
$env:LUMIBOT_CACHE_FOLDER = Join-Path $ProjectRoot "data\lumibot-cache"
& (Join-Path $ProjectRoot "envs\lumibot\Scripts\python.exe") (Join-Path $PSScriptRoot "Test-LumibotImport.py")
if ($LASTEXITCODE -ne 0) { $Failures++ }

Write-Host "[4/4] AgentQuant 测试"
$AgentRoot = Join-Path $ProjectRoot "vendor\AgentQuant"
$env:PYTHONPATH = $AgentRoot
Push-Location $AgentRoot
& (Join-Path $ProjectRoot "envs\agentquant\Scripts\python.exe") -m pytest -q -p no:cacheprovider --basetemp $AgentTemp
if ($LASTEXITCODE -ne 0) { $Failures++ }
Pop-Location

if ($Failures -gt 0) { throw "验收失败项数: $Failures" }
Write-Host "全部验收通过。"
