[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$SecretDir = Join-Path $ProjectRoot "runtime\secrets"
$KeyFile = Join-Path $SecretDir "twelve-data.key"

Write-Host "Secure Twelve Data API Key Setup" -ForegroundColor Cyan
Write-Host "Your input will be hidden. The key will be encrypted for this Windows user with DPAPI."
$SecureKey = Read-Host "Paste your API Key, then press Enter" -AsSecureString
if ($SecureKey.Length -lt 8) {
    throw "The input is too short. Nothing was saved."
}

New-Item -ItemType Directory -Force -Path $SecretDir | Out-Null
Add-Type -AssemblyName System.Security
$Pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureKey)
$PlainBytes = $null
try {
    $PlainText = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($Pointer)
    $PlainBytes = [Text.Encoding]::UTF8.GetBytes($PlainText)
    $ProtectedBytes = [Security.Cryptography.ProtectedData]::Protect(
        $PlainBytes,
        $null,
        [Security.Cryptography.DataProtectionScope]::CurrentUser
    )
    $Encrypted = [Convert]::ToBase64String($ProtectedBytes)
    Set-Content -LiteralPath $KeyFile -Value $Encrypted -Encoding ASCII -NoNewline
} finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($Pointer)
    if ($null -ne $PlainBytes) { [Array]::Clear($PlainBytes, 0, $PlainBytes.Length) }
    $PlainText = $null
}
Write-Host "Saved: runtime\secrets\twelve-data.key" -ForegroundColor Green
Write-Host "This file is excluded from Git and can only be decrypted by this Windows user on this computer."
Read-Host "Press Enter to close"
