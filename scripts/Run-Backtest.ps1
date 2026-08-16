[CmdletBinding()]
param(
    [string]$Start = "2010-01-01",
    [string]$End = "",
    [switch]$Offline
)

$ErrorActionPreference = "Stop"
$Utf8 = New-Object Text.UTF8Encoding($false)
[Console]::InputEncoding = $Utf8
[Console]::OutputEncoding = $Utf8
$OutputEncoding = $Utf8
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$Python = Join-Path $ProjectRoot "envs\core\Scripts\python.exe"
$KeyFile = Join-Path $ProjectRoot "runtime\secrets\twelve-data.key"
if (-not (Test-Path -LiteralPath $Python)) {
    throw "核心环境尚未安装，请先运行 scripts\Setup-Environments.ps1"
}

$Arguments = @("-m", "quant_lab.cli", "--start", $Start)
if ($End) { $Arguments += @("--end", $End) }
if ($Offline) { $Arguments += "--offline" }

Push-Location $ProjectRoot
try {
    $env:PYTHONPATH = Join-Path $ProjectRoot "src"
    $env:PYTHONUTF8 = "1"
    if (Test-Path -LiteralPath $KeyFile) {
        Add-Type -AssemblyName System.Security
        $Encrypted = (Get-Content -Raw -LiteralPath $KeyFile).Trim()
        if (-not $Encrypted) { throw "Twelve Data key file is empty. Run scripts\Set-TwelveDataKey.ps1 again." }
        $ProtectedBytes = [Convert]::FromBase64String($Encrypted)
        $PlainBytes = [Security.Cryptography.ProtectedData]::Unprotect(
            $ProtectedBytes,
            $null,
            [Security.Cryptography.DataProtectionScope]::CurrentUser
        )
        try {
            $env:TWELVE_DATA_API_KEY = [Text.Encoding]::UTF8.GetString($PlainBytes)
        } finally {
            [Array]::Clear($PlainBytes, 0, $PlainBytes.Length)
            [Array]::Clear($ProtectedBytes, 0, $ProtectedBytes.Length)
        }
    }
    & $Python @Arguments
} finally {
    Remove-Item Env:TWELVE_DATA_API_KEY -ErrorAction SilentlyContinue
    Remove-Item Env:PYTHONUTF8 -ErrorAction SilentlyContinue
    Pop-Location
}
