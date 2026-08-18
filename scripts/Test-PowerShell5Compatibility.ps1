[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$Failures = @()
Get-ChildItem -LiteralPath $PSScriptRoot -Filter "*.ps1" | ForEach-Object {
    $Tokens = $null
    $Errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile(
        $_.FullName,
        [ref]$Tokens,
        [ref]$Errors
    ) | Out-Null
    if ($Errors.Count -gt 0) {
        $Failures += "$($_.Name): $($Errors.Message -join ' | ')"
    }
}
if ($Failures.Count -gt 0) {
    $Failures | ForEach-Object { Write-Error $_ }
    throw "Windows PowerShell 5.1 compatibility check failed."
}
Write-Host "All PowerShell scripts parse in Windows PowerShell 5.1."
