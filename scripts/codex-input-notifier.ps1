param(
    [switch]$Watch,
    [switch]$Demo,
    [ValidateSet("question", "approval", "blocked")]
    [string]$DemoEvent = "question",
    [string]$DemoText = "Codex is waiting for your input.",
    [int]$PollIntervalMs = 900,
    [int]$DebounceSeconds = 20
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-CodexNotifyEnabled {
    $raw = $env:CODEX_NOTIFY_ON_INPUT
    if ([string]::IsNullOrWhiteSpace($raw)) {
        $raw = "true"
    }
    return ($raw.ToLowerInvariant() -eq "true")
}

function Send-CodexDesktopNotification {
    param(
        [string]$Title,
        [string]$Message
    )

    try {
        if (Get-Command -Name New-BurntToastNotification -ErrorAction SilentlyContinue) {
            New-BurntToastNotification -Text $Title, $Message | Out-Null
            return
        }
    } catch {
    }

    try {
        Add-Type -AssemblyName System.Windows.Forms | Out-Null
        Add-Type -AssemblyName System.Drawing | Out-Null
        $notifyIcon = New-Object System.Windows.Forms.NotifyIcon
        $notifyIcon.Icon = [System.Drawing.SystemIcons]::Information
        $notifyIcon.BalloonTipTitle = $Title
        $notifyIcon.BalloonTipText = $Message
        $notifyIcon.Visible = $true
        $notifyIcon.ShowBalloonTip(4000)
        Start-Sleep -Milliseconds 4500
        $notifyIcon.Dispose()
    } catch {
    }
}

function Send-CodexInputNotification {
    param(
        [string]$EventType,
        [string]$Message
    )

    if (-not (Test-CodexNotifyEnabled)) {
        return
    }

    # Terminal bell.
    [Console]::Write("`a")

    $title = "Codex input needed ($EventType)"
    Send-CodexDesktopNotification -Title $title -Message $Message
}

function Test-IsInputNeededQuestion {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $false
    }

    $trimmed = $Text.Trim()
    $lower = $trimmed.ToLowerInvariant()

    if ($trimmed.EndsWith("?")) { return $true }
    if ($lower -match "please (provide|share|confirm)") { return $true }
    if ($lower -match "i need (your|a) (input|answer|confirmation|approval)") { return $true }
    if ($lower -match "could you|can you|would you|which option|what should") { return $true }

    return $false
}

function Get-AssistantOutputText {
    param($Payload)

    if (-not $Payload.content) {
        return ""
    }

    $parts = @()
    foreach ($item in $Payload.content) {
        if ($item.type -eq "output_text" -and -not [string]::IsNullOrWhiteSpace($item.text)) {
            $parts += $item.text
        }
    }

    return ($parts -join "`n").Trim()
}

function Get-CodexSessionFiles {
    $root = Join-Path $env:USERPROFILE ".codex\sessions"
    if (-not (Test-Path $root)) {
        return @()
    }
    return Get-ChildItem -Path $root -Recurse -Filter "*.jsonl" -File | Sort-Object LastWriteTimeUtc
}

function Read-NewSessionLines {
    param(
        [string]$Path,
        [hashtable]$Offsets
    )

    $content = Get-Content -Path $Path
    $offset = 0
    if ($Offsets.ContainsKey($Path)) {
        $offset = [int]$Offsets[$Path]
    }

    $total = $content.Count
    if ($offset -gt $total) {
        $offset = 0
    }

    $new = @()
    if ($total -gt $offset) {
        $new = $content[$offset..($total - 1)]
    }

    $Offsets[$Path] = $total
    return $new
}

function Start-CodexInputNotifierWatch {
    $state = @{
        Offsets          = @{}
        LastNotification = ""
        LastAt           = [datetime]::MinValue
    }

    while ($true) {
        if (-not (Test-CodexNotifyEnabled)) {
            Start-Sleep -Milliseconds $PollIntervalMs
            continue
        }

        $files = Get-CodexSessionFiles
        foreach ($file in $files) {
            $lines = Read-NewSessionLines -Path $file.FullName -Offsets $state.Offsets
            foreach ($line in $lines) {
                if ([string]::IsNullOrWhiteSpace($line)) {
                    continue
                }

                try {
                    $event = $line | ConvertFrom-Json -Depth 20
                } catch {
                    continue
                }

                $notifyKey = ""
                $notifyType = ""
                $notifyText = ""

                if ($event.type -eq "response_item" -and $event.payload.type -eq "function_call" -and $event.payload.name -eq "shell_command") {
                    try {
                        $args = $event.payload.arguments | ConvertFrom-Json -Depth 10
                        $cmd = ""
                        if ($null -ne $args.command) {
                            $cmd = [string]$args.command
                        }
                        $justification = ""
                        if ($null -ne $args.justification) {
                            $justification = [string]$args.justification
                        }
                        if ($cmd -and $args.sandbox_permissions -eq "require_escalated") {
                            $notifyType = "approval"
                            $notifyText = if ([string]::IsNullOrWhiteSpace($justification)) { "Codex requested command approval." } else { $justification }
                            $notifyKey = "approval::$notifyText"
                        }
                    } catch {
                    }
                }

                if ($event.type -eq "response_item" -and $event.payload.type -eq "message" -and $event.payload.role -eq "assistant") {
                    $assistantText = Get-AssistantOutputText -Payload $event.payload
                    if (Test-IsInputNeededQuestion -Text $assistantText) {
                        $notifyType = "question"
                        $notifyText = $assistantText
                        $notifyKey = "question::$notifyText"
                    } elseif ($assistantText.ToLowerInvariant() -match "blocked|cannot continue|can't continue|need your approval") {
                        $notifyType = "blocked"
                        $notifyText = $assistantText
                        $notifyKey = "blocked::$notifyText"
                    }
                }

                if ($event.type -eq "response_item" -and $event.payload.type -eq "message" -and $event.payload.role -eq "user") {
                    # Reset debounce after user replies, so the next prompt can notify.
                    $state.LastNotification = ""
                    $state.LastAt = [datetime]::MinValue
                }

                if (-not [string]::IsNullOrWhiteSpace($notifyKey)) {
                    $secondsSinceLast = ((Get-Date) - $state.LastAt).TotalSeconds
                    $isDuplicate = ($state.LastNotification -eq $notifyKey -and $secondsSinceLast -lt $DebounceSeconds)
                    if (-not $isDuplicate) {
                        Send-CodexInputNotification -EventType $notifyType -Message $notifyText
                        $state.LastNotification = $notifyKey
                        $state.LastAt = Get-Date
                    }
                }
            }
        }

        Start-Sleep -Milliseconds $PollIntervalMs
    }
}

if ($Demo) {
    Send-CodexInputNotification -EventType $DemoEvent -Message $DemoText
    exit 0
}

if ($Watch) {
    Start-CodexInputNotifierWatch
}
