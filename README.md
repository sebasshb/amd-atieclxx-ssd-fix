# AMD atieclxx SSD fix (manual)

A **manual, transparent** workaround for the AMD Radeon driver bug where the **"AMD External Events Utility"** service (`atieclxx.exe`) writes to the system drive non-stop, at about **54–56 GB per day**, **without disabling the service**. **VRR/FreeSync** and Adrenalin hotkeys keep working.

> ⚠️ **Unofficial** workaround, not affiliated with AMD. Use at your own risk (see [LICENSE](LICENSE)).
> AMD has confirmed the bug and says it will be fixed in **Adrenalin 26.11.1**. This is a stopgap until then.

## The problem

On affected drivers, `atieclxx.exe` **copies itself every second** to:

```
C:\Windows\System32\config\systemprofile\AppData\Local\AMD\atieclxx.exe
```

Each copy is about 660 KB, so the PC writes **about 660 KB/s continuously**. According to AMD, the cause is an interaction between this service and Microsoft's PCIe filter driver, related to Resizable BAR / Smart Access Memory.

## Am I affected?

In **PowerShell as administrator**:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\check.ps1
```

**600 KB/s or more** means you are affected. A few KB/s means you are not.

You can also see it in `resmon` → **Disk** tab → sort by **Write (B/sec)**: `atieclxx.exe` shows up writing all the time.

## The fix

The fix **denies the SYSTEM account permission to overwrite or delete that single copy**. The self-copy fails immediately and the writes stop, while the service keeps running.

- It does not modify the driver or the original file.
- It creates no scheduled tasks and leaves no processes running.
- It downloads nothing and does not connect to the internet.
- It can be reverted with a single command.

### With the scripts

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\apply.ps1    # apply the block and measure
powershell -ExecutionPolicy Bypass -File .\scripts\check.ps1    # measure again any time
powershell -ExecutionPolicy Bypass -File .\scripts\revert.ps1   # remove the block
```

If Windows blocks the downloaded scripts, unblock them first:

```powershell
Get-ChildItem .\scripts\*.ps1 | Unblock-File
```

### By hand, without the scripts

```powershell
$f = "$env:SystemRoot\System32\config\systemprofile\AppData\Local\AMD\atieclxx.exe"
icacls $f                                            # show current permissions
icacls $f /deny "*S-1-5-18:(WD,AD,WEA,WA,DE)"        # apply the block
icacls $f /remove:d "*S-1-5-18"                      # remove the block
```

The denied permissions are `WD` (write data), `AD` (append data), `WEA` (write extended attributes), `WA` (write attributes) and `DE` (delete). They are denied only to `S-1-5-18` (SYSTEM) and only on that one copy.

## When the official driver ships

1. Run **`revert.ps1`** **before** installing the new driver (for example Adrenalin 26.11.1).
2. Install the driver.
3. Run **`check.ps1`**. If it shows close to 0 KB/s, AMD fixed it and there is nothing else to do.

## Alternatives and why I don't use them

| Alternative | Drawback |
|---|---|
| Disabling the "AMD External Events Utility" service | Can break VRR/FreeSync, hotkeys and monitor hot-plug detection |
| Disabling Resizable BAR / SAM in the BIOS | Lower performance in games |
| Third-party tools with scheduled tasks running as SYSTEM | Adds a process with the highest privileges that isn't needed |

## Tested result

On a PC with a Ryzen 7 5800X3D, RX 9060 XT and Windows 11, `atieclxx.exe` writes went from **662 KB/s** (about 54.5 GB per day) to **0 KB/s**, with VRR still working.

## Credits and sources

- The technical findings (the self-copy every second and the ACL block) come from [necanditool/Radeon-atieclxx-SSD-Fix](https://github.com/necanditool/Radeon-atieclxx-SSD-Fix) (MIT license). This repo is a minimal, manual version.
- Spanish version: [sebasshb/amd-atieclxx-ssd-fix-es](https://github.com/sebasshb/amd-atieclxx-ssd-fix-es)
- [Hardware Busters: AMD confirms the bug, fix due in Adrenalin 26.11.1](https://hwbusters.com/news/amd-confirms-radeon-driver-bug-that-keeps-ssds-writing-at-idle-fix-due-in-adrenalin-26-11-1/)
- [TechPowerUp: AMD Confirms Excessive SSD Writes in Radeon Drivers](https://www.techpowerup.com/354605/amd-confirms-excessive-ssd-writes-in-radeon-drivers-fix-coming-with-adrenalin-26-11-1)
- [WindowsForum: How to check atieclxx.exe](https://windowsforum.com/news/amd-radeon-ssd-write-bug-how-to-check-atieclxx-exe-on-windows-10-and-11.450605/)

AMD, Radeon, FreeSync and Smart Access Memory are trademarks of Advanced Micro Devices, Inc. This project is not affiliated with AMD.
