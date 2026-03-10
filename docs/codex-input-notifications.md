# Codex Input-Needed Notifications (PowerShell / Windows)

This adds opt-in notifications when Codex is waiting for user input:
- terminal bell (`\a`)
- desktop notification (BurntToast if installed, otherwise Windows tray balloon if available)

Normal Codex output is not modified because notifications are driven by Codex session event files.

## Files

- `scripts/codex-input-notifier.ps1` - watcher and notifier script

## Enable in PowerShell profile

Add this to your PowerShell profile (`$PROFILE`):

```powershell
$env:CODEX_NOTIFY_ON_INPUT = "true"

$codexNotifierScript = "C:\Users\Osman\Desktop\putaway app\scripts\codex-input-notifier.ps1"

# Start one watcher job per shell.
if (-not (Get-Job -Name codex-input-notifier -ErrorAction SilentlyContinue)) {
    Start-Job -Name codex-input-notifier -ScriptBlock {
        param($scriptPath)
        & $scriptPath -Watch
    } -ArgumentList $codexNotifierScript | Out-Null
}
```

Reload profile:

```powershell
. $PROFILE
```

## Disable

```powershell
$env:CODEX_NOTIFY_ON_INPUT = "false"
```

Optional: stop the watcher job.

```powershell
Get-Job -Name codex-input-notifier -ErrorAction SilentlyContinue | Stop-Job
Get-Job -Name codex-input-notifier -ErrorAction SilentlyContinue | Remove-Job
```

## Optional desktop toast support

Install BurntToast once (optional):

```powershell
Install-Module BurntToast -Scope CurrentUser
```

Without BurntToast, script falls back to a Windows tray balloon where available.

## Test / demo

Run:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\Osman\Desktop\putaway app\scripts\codex-input-notifier.ps1" -Demo -DemoEvent question -DemoText "Demo: Codex is waiting for your answer."
```

If enabled, you should hear a bell and see a desktop notification.
