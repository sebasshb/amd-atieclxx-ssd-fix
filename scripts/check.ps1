# check.ps1
# Measures how much atieclxx.exe ("AMD External Events Utility" service) writes over a few seconds.
# Read-only: it only reads Windows counters and changes nothing.
# Usage (PowerShell as administrator):
#   powershell -ExecutionPolicy Bypass -File .\check.ps1
#   powershell -ExecutionPolicy Bypass -File .\check.ps1 -Seconds 60

param([int]$Seconds = 30)

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host 'Run PowerShell as administrator: the service counters cannot be read without it.' -ForegroundColor Yellow
    return
}

function Get-AtieclxxWrites {
    $p = @(Get-CimInstance Win32_Process -Filter "Name='atieclxx.exe'")
    if ($p.Count -eq 0) { return $null }
    return [double](($p | Measure-Object WriteTransferCount -Sum).Sum)
}

$a = Get-AtieclxxWrites
if ($null -eq $a) {
    Write-Host 'atieclxx.exe is not running: nothing to measure.' -ForegroundColor Green
    return
}

Write-Host ("Measuring for {0} seconds..." -f $Seconds)
Start-Sleep -Seconds $Seconds
$b = Get-AtieclxxWrites

if ($null -eq $b -or $b -lt $a) {
    Write-Host 'The process restarted during the measurement. Run the script again.' -ForegroundColor Yellow
    return
}

$kbs = ($b - $a) / $Seconds / 1KB
Write-Host ("atieclxx.exe writes {0:N0} KB/s (~{1:N1} GB per day with the PC on 24 h)" -f $kbs, ($kbs * 86400 / 1MB))

if ($kbs -ge 150) {
    Write-Host 'AFFECTED: continuous writes. See apply.ps1.' -ForegroundColor Red
} else {
    Write-Host 'OK: no continuous writes.' -ForegroundColor Green
}
