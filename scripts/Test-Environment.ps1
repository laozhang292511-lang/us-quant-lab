$ProjectRoot = Split-Path -Parent $PSScriptRoot
$Python = Join-Path $ProjectRoot "envs\core\Scripts\python.exe"
if (-not (Test-Path -LiteralPath $Python)) {
    throw "核心环境不存在。"
}
Push-Location $ProjectRoot
try {
    $env:PYTHONPATH = Join-Path $ProjectRoot "src"
    & $Python -m pytest
    & $Python -m ruff check src tests
} finally {
    Pop-Location
}
