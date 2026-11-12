# apply.ps1
# Blocks the atieclxx.exe self-copy by denying the SYSTEM account permission to write or delete
# ONE copy of the file. The service keeps running (VRR/FreeSync, hotkeys).
# Creates no scheduled tasks and leaves nothing running.
# Usage (PowerShell as administrator):
#   powershell -ExecutionPolicy Bypass -File .\apply.ps1

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host 'Run PowerShell as administrator.' -ForegroundColor Yellow
    return
}

$f = Join-Path $env:SystemRoot 'System32\config\systemprofile\AppData\Local\AMD\atieclxx.exe'
if (-not (Test-Path -LiteralPath $f)) {
    Write-Host "$f does not exist." -ForegroundColor Yellow
    Write-Host 'Your driver does not self-copy to this path. Nothing was changed.'
    return
}

Write-Host 'Current permissions:'
& icacls $f
Write-Host ''

Write-Host 'Applying the block (SYSTEM only, this file only)...'
& icacls $f /deny '*S-1-5-18:(WD,AD,WEA,WA,DE)'
Write-Host ''

$sid = New-Object System.Security.Principal.SecurityIdentifier('S-1-5-18')
$blocked = $false
foreach ($r in (Get-Acl -LiteralPath $f).Access) {
    if ($r.AccessControlType -eq 'Deny' -and -not $r.IsInherited) {
        try { if ($r.IdentityReference.Translate([System.Security.Principal.SecurityIdentifier]) -eq $sid) { $blocked = $true } } catch {}
    }
}
if (-not $blocked) {
    Write-Host 'The block could not be applied.' -ForegroundColor Red
    return
}
Write-Host 'Block applied.' -ForegroundColor Green
Write-Host ''

$check = Join-Path $PSScriptRoot 'check.ps1'
if (Test-Path -LiteralPath $check) {
    Write-Host 'Checking that the writes stopped:'
    & $check -Seconds 15
}
Write-Host ''
Write-Host 'IMPORTANT: run revert.ps1 before installing a new AMD driver.' -ForegroundColor Yellow
