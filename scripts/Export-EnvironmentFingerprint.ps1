[CmdletBinding()]
param([switch]$Verify)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ExpectedPython = "3.11.13"
$Expected = [ordered]@{
    core = @{ package = "laozhang-quant-lab"; version = "0.1.0" }
    vibe = @{ package = "vibe-trading-ai"; version = "0.1.13" }
    lumibot = @{ package = "lumibot"; version = "4.5.83" }
    agentquant = @{ package = "agentquant"; version = "0.2.0" }
}
$Results = [ordered]@{}
$Failures = @()

$UvExe = Join-Path $ProjectRoot ".tools\uv\bin\uv.exe"
if (Test-Path -LiteralPath $UvExe) {
    $UvVersion = ((& $UvExe --version) -replace '^uv\s+', '').Split(' ')[0]
    if ($UvVersion -ne "0.8.12") { $Failures += "uv is $UvVersion; expected 0.8.12" }
} else {
    $UvVersion = "missing"
    $Failures += "uv executable is missing"
}

foreach ($Name in $Expected.Keys) {
    $Python = Join-Path $ProjectRoot "envs\$Name\Scripts\python.exe"
    if (-not (Test-Path -LiteralPath $Python)) {
        $Failures += "Missing environment: $Name"
        continue
    }
    $PythonVersion = (& $Python -c "import platform; print(platform.python_version())").Trim()
    $PackageName = $Expected[$Name].package
    $PackageVersion = (& $Python -c "import importlib.metadata as m; print(m.version('$PackageName'))").Trim()
    $Results[$Name] = [ordered]@{
        python = $PythonVersion
        package = $PackageName
        version = $PackageVersion
    }
    if ($PythonVersion -ne $ExpectedPython) { $Failures += "$Name uses Python $PythonVersion; expected $ExpectedPython" }
    if ($PackageVersion -ne $Expected[$Name].version) {
        $Failures += "$Name package is $PackageVersion; expected $($Expected[$Name].version)"
    }
}

$SkillCount = (Get-ChildItem -LiteralPath (Join-Path $ProjectRoot ".codex\skills") -Directory -ErrorAction SilentlyContinue).Count
if ($SkillCount -ne 9) { $Failures += "Trading skill count is $SkillCount; expected 9" }
$AgentCommitFile = Join-Path $ProjectRoot "vendor\AgentQuant\.source-commit"
$AgentSourceCommit = if (Test-Path -LiteralPath $AgentCommitFile) {
    (Get-Content -Raw -LiteralPath $AgentCommitFile).Trim()
} else {
    "missing"
}
if ($AgentSourceCommit -ne "8275a8e5331bd63b5a7bcb26e9704ecca85c2bc2") {
    $Failures += "AgentQuant source marker does not match the locked commit"
}
$GitCommit = (& git.exe -c "safe.directory=$($ProjectRoot.Replace('\', '/'))" -C $ProjectRoot rev-parse HEAD).Trim()
$Profile = "not-configured"
$LocalConfig = Join-Path $ProjectRoot "config\local.yaml"
if (Test-Path -LiteralPath $LocalConfig) {
    $ProfileLine = Select-String -LiteralPath $LocalConfig -Pattern '^profile:\s*(.+)$' | Select-Object -First 1
    if ($ProfileLine) { $Profile = $ProfileLine.Matches[0].Groups[1].Value.Trim() }
}

$Fingerprint = [ordered]@{
    schema_version = 1
    generated_at_utc = [DateTime]::UtcNow.ToString("o")
    profile = $Profile
    repository_commit = $GitCommit
    expected_python = $ExpectedPython
    uv_version = $UvVersion
    environments = $Results
    agentquant_source_commit = $AgentSourceCommit
    trading_skill_count = $SkillCount
    verification_passed = ($Failures.Count -eq 0)
    failures = $Failures
}
$RuntimeRoot = Join-Path $ProjectRoot "runtime"
New-Item -ItemType Directory -Force -Path $RuntimeRoot | Out-Null
$OutputPath = Join-Path $RuntimeRoot "environment-fingerprint.json"
$Fingerprint | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
$Fingerprint | ConvertTo-Json -Depth 6
Write-Host "Fingerprint saved: $OutputPath"

if ($Verify -and $Failures.Count -gt 0) { exit 1 }
