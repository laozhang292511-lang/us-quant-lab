$ProjectRoot = Split-Path -Parent $PSScriptRoot
$Utf8 = New-Object Text.UTF8Encoding($false)
[Console]::InputEncoding = $Utf8
[Console]::OutputEncoding = $Utf8
$OutputEncoding = $Utf8
$env:PYTHONUTF8 = "1"
$Python = Join-Path $ProjectRoot "envs\core\Scripts\python.exe"
$RunId = "{0}-{1}" -f ([DateTime]::UtcNow.ToString("yyyyMMddHHmmss")), $PID
$TestRoot = Join-Path $ProjectRoot "runtime\test-temp\environment-$RunId"
New-Item -ItemType Directory -Force -Path $TestRoot | Out-Null
$env:RUFF_CACHE_DIR = Join-Path $TestRoot "ruff-cache"
if (-not (Test-Path -LiteralPath $Python)) {
    throw "核心环境不存在。"
}
Push-Location $ProjectRoot
try {
    $env:PYTHONPATH = Join-Path $ProjectRoot "src"
    & $Python -m pytest -p no:cacheprovider --basetemp (Join-Path $TestRoot "pytest")
    & $Python -m ruff check src tests
} finally {
    Pop-Location
}
