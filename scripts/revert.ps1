# revert.ps1
# Removes the block added by apply.ps1 and restores the original permissions.
# Run it BEFORE installing a new AMD driver (for example Adrenalin 26.11.1).
# Usage (PowerShell as administrator):
#   powershell -ExecutionPolicy Bypass -File .\revert.ps1

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host 'Run PowerShell as administrator.' -ForegroundColor Yellow
    return
}

$f = Join-Path $env:SystemRoot 'System32\config\systemprofile\AppData\Local\AMD\atieclxx.exe'
if (-not (Test-Path -LiteralPath $f)) {
    Write-Host "$f does not exist: nothing to revert." -ForegroundColor Green
    return
}

& icacls $f /remove:d '*S-1-5-18'
Write-Host ''
Write-Host 'Current permissions:'
& icacls $f
Write-Host ''
Write-Host 'Block removed. After installing the new driver, run check.ps1 to see whether AMD fixed it.' -ForegroundColor Green
