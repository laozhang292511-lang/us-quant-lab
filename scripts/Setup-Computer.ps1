[CmdletBinding()]
param(
    [ValidateSet("ComputerA", "ComputerB")]
    [string]$Profile = "ComputerB",
    [switch]$ConfirmUnitPolicy,
    [switch]$AllowSystemDrive,
    [switch]$AuditOnly
)

$ErrorActionPreference = "Stop"
$Utf8 = New-Object Text.UTF8Encoding($false)
[Console]::InputEncoding = $Utf8
[Console]::OutputEncoding = $Utf8
$OutputEncoding = $Utf8
$env:PYTHONUTF8 = "1"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ProjectRoot = [IO.Path]::GetFullPath($ProjectRoot)
$ProjectDrive = [IO.Path]::GetPathRoot($ProjectRoot).TrimEnd("\")
$PythonVersion = "3.11.13"
$UvVersion = "0.8.12"
$AgentQuantCommit = "8275a8e5331bd63b5a7bcb26e9704ecca85c2bc2"
$UvUrl = "https://github.com/astral-sh/uv/releases/download/0.8.12/uv-x86_64-pc-windows-msvc.zip"

if ($ProjectDrive -eq "C:" -and -not $AllowSystemDrive) {
    throw "The repository is on C:. Clone it to an approved non-system drive, or explicitly pass -AllowSystemDrive."
}
if ($Profile -eq "ComputerB" -and -not $ConfirmUnitPolicy) {
    throw "Computer B is employer-owned. Confirm that company policy permits this installation, then rerun with -ConfirmUnitPolicy."
}
if ($AuditOnly) {
    & (Join-Path $PSScriptRoot "Export-EnvironmentFingerprint.ps1") -Verify
    exit $LASTEXITCODE
}

$ToolsRoot = Join-Path $ProjectRoot ".tools"
$DownloadRoot = Join-Path $ToolsRoot "downloads"
$UvRoot = Join-Path $ToolsRoot "uv\bin"
$UvExe = Join-Path $UvRoot "uv.exe"
$PythonRoot = Join-Path $ToolsRoot "python"
$CacheRoot = Join-Path $ToolsRoot "uv-cache"
$EnvsRoot = Join-Path $ProjectRoot "envs"
$VendorRoot = Join-Path $ProjectRoot "vendor"
$RequirementsRoot = Join-Path $ProjectRoot "requirements"
New-Item -ItemType Directory -Force -Path $DownloadRoot, $UvRoot, $PythonRoot, $CacheRoot, $EnvsRoot, $VendorRoot | Out-Null

if (-not (Test-Path -LiteralPath $UvExe)) {
    $UvArchive = Join-Path $DownloadRoot "uv-$UvVersion.zip"
    $UvExtract = Join-Path $DownloadRoot "uv-$UvVersion"
    Write-Host "Downloading uv $UvVersion..." -ForegroundColor Cyan
    Invoke-WebRequest -UseBasicParsing -Uri $UvUrl -OutFile $UvArchive
    if (Test-Path -LiteralPath $UvExtract) {
        throw "Temporary extraction folder already exists: $UvExtract"
    }
    Expand-Archive -LiteralPath $UvArchive -DestinationPath $UvExtract
    $DownloadedUv = Get-ChildItem -LiteralPath $UvExtract -Filter "uv.exe" -Recurse | Select-Object -First 1
    if ($null -eq $DownloadedUv) { throw "uv.exe was not found in the downloaded archive." }
    Copy-Item -LiteralPath $DownloadedUv.FullName -Destination $UvExe
}

$env:UV_CACHE_DIR = $CacheRoot
$env:UV_PYTHON_INSTALL_DIR = $PythonRoot
& $UvExe python install $PythonVersion --install-dir $PythonRoot --no-bin
if ($LASTEXITCODE -ne 0) { throw "Python installation failed." }
$PythonExe = Get-ChildItem -LiteralPath $PythonRoot -Filter "python.exe" -Recurse |
    Where-Object { $_.FullName -notmatch "\\Scripts\\" } |
    Select-Object -First 1
if ($null -eq $PythonExe) { throw "Managed Python $PythonVersion was not found." }

function Ensure-Venv {
    param([Parameter(Mandatory)][string]$Name)
    $VenvRoot = Join-Path $EnvsRoot $Name
    $VenvPython = Join-Path $VenvRoot "Scripts\python.exe"
    if (-not (Test-Path -LiteralPath $VenvPython)) {
        & $UvExe venv --python $PythonExe.FullName $VenvRoot | Out-Host
        if ($LASTEXITCODE -ne 0) { throw "Failed to create environment: $Name" }
    }
    return $VenvPython
}

Write-Host "Installing the deterministic core..." -ForegroundColor Cyan
$CorePython = Ensure-Venv -Name "core"
& $UvExe pip sync --python $CorePython (Join-Path $RequirementsRoot "core.lock.txt")
if ($LASTEXITCODE -ne 0) { throw "Core dependency synchronization failed." }
& $UvExe pip install --python $CorePython --no-deps -e "$ProjectRoot[dev]"
if ($LASTEXITCODE -ne 0) { throw "Core installation failed." }

Write-Host "Installing Vibe-Trading 0.1.13..." -ForegroundColor Cyan
$VibePython = Ensure-Venv -Name "vibe"
& $UvExe pip sync --python $VibePython (Join-Path $RequirementsRoot "vibe.lock.txt")
if ($LASTEXITCODE -ne 0) { throw "Vibe-Trading installation failed." }

Write-Host "Installing Lumibot 4.5.83..." -ForegroundColor Cyan
$LumibotPython = Ensure-Venv -Name "lumibot"
& $UvExe pip sync --python $LumibotPython (Join-Path $RequirementsRoot "lumibot.lock.txt")
if ($LASTEXITCODE -ne 0) { throw "Lumibot installation failed." }

Write-Host "Installing AgentQuant 0.2.0 from its locked source commit..." -ForegroundColor Cyan
$AgentRoot = Join-Path $VendorRoot "AgentQuant"
if (-not (Test-Path -LiteralPath (Join-Path $AgentRoot "pyproject.toml"))) {
    if (-not (Get-Command git.exe -ErrorAction SilentlyContinue)) { throw "Git is required to install AgentQuant." }
    & git.exe clone "https://github.com/OnePunchMonk/AgentQuant" $AgentRoot
    if ($LASTEXITCODE -ne 0) { throw "AgentQuant clone failed." }
    & git.exe -C $AgentRoot checkout $AgentQuantCommit
    if ($LASTEXITCODE -ne 0) { throw "AgentQuant checkout failed." }
}
$AgentPython = Ensure-Venv -Name "agentquant"
& $UvExe pip sync --python $AgentPython (Join-Path $RequirementsRoot "agentquant.lock.txt")
if ($LASTEXITCODE -ne 0) { throw "AgentQuant dependency synchronization failed." }
& $UvExe pip install --python $AgentPython --no-deps -e "$AgentRoot[dev]"
if ($LASTEXITCODE -ne 0) { throw "AgentQuant installation failed." }
Set-Content -LiteralPath (Join-Path $AgentRoot ".source-commit") -Value $AgentQuantCommit -Encoding ASCII -NoNewline

$LocalConfig = Join-Path $ProjectRoot "config\local.yaml"
$ProfileId = if ($Profile -eq "ComputerB") { "computer-b-restricted" } else { "computer-a-personal" }
$LiveAllowed = if ($Profile -eq "ComputerB") { "false" } else { "false" }
@(
    "schema_version: 1",
    "profile: $ProfileId",
    "install_root: `"$($ProjectRoot.Replace('\', '/'))`"",
    "mode: backtest",
    "allow_broker_credentials: false",
    "schwab_live: $LiveAllowed"
) | Set-Content -LiteralPath $LocalConfig -Encoding UTF8

Write-Host "Running full acceptance tests..." -ForegroundColor Cyan
& (Join-Path $PSScriptRoot "Test-All.ps1")
if ($LASTEXITCODE -ne 0) { throw "Acceptance tests failed." }
& (Join-Path $PSScriptRoot "Export-EnvironmentFingerprint.ps1") -Verify
if ($LASTEXITCODE -ne 0) { throw "Environment verification failed." }
Write-Host "Installation and verification completed." -ForegroundColor Green
