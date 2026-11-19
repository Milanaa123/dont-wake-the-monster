#Requires -Version 5.1
# Experimental unattended Windows Studio capture.
# Only fetches installer from Roblox's official CDN; never logs in or publishes.
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$root = (Resolve-Path ".").Path
$out = Join-Path $root "capture"
New-Item -ItemType Directory -Path $out -Force | Out-Null
$report = [ordered]@{
  host = $env:RUNNER_OS
  installed = $false
  studio_launched = $false
  play_key_sent = $false
  screenshots = 0
  video_generated = $false
  gameplay_verified = $false
  blocker = $null
}

function Capture([string]$name) {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        $screen = [System.Windows.Forms.Screen]::PrimaryScreen
        if (!$screen) { throw "No interactive display was detected" }
        $bounds = $screen.Bounds
        $bmp = [System.Drawing.Bitmap]::new($bounds.Width, $bounds.Height)
        $graphics = [System.Drawing.Graphics]::FromImage($bmp)
        $graphics.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
        $path = Join-Path $out $name
        $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
        $graphics.Dispose()
        $bmp.Dispose()
        $report.screenshots += 1
        Write-Host "Captured $name ($($bounds.Width)x$($bounds.Height))"
        return $true
    } catch {
        Write-Host "Screenshot failed: $($_.Exception.Message)"
        return $false
    }
}

try {
    Capture "00-before.png" | Out-Null
    $installer = Join-Path $env:RUNNER_TEMP "RobloxStudioInstaller.exe"
    Write-Host "Downloading Roblox Studio from its official CDN."
    Invoke-WebRequest -Uri "https://setup.rbxcdn.com/RobloxStudioInstaller.exe" -OutFile $installer -UseBasicParsing -TimeoutSec 110
    $signature = Get-AuthenticodeSignature -FilePath $installer
    if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch "Roblox") {
        throw "Official installer signature verification failed. Status: $($signature.Status)"
    }
    Write-Host "Validated Roblox installer signer; starting setup."
    $process = Start-Process -FilePath $installer -PassThru
    $studio = $null
    $deadline = (Get-Date).AddSeconds(155)
    do {
        Start-Sleep -Seconds 8
        # The 2026 Studio installer may use Program Files rather than LocalAppData.
        # Prefer the actually running signed Studio executable from our own installer.
        $runningStudio = Get-Process RobloxStudioBeta -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($runningStudio) {
            try { $studio = $runningStudio.Path } catch { }
        }
        if (-not $studio) {
            foreach ($versions in @(
                (Join-Path $env:LOCALAPPDATA "Roblox\Versions"),
                (Join-Path $env:ProgramFiles "Roblox\Versions"),
                (Join-Path ${env:ProgramFiles(x86)} "Roblox\Versions")
            )) {
                if (-not (Test-Path $versions)) { continue }
                $studio = Get-ChildItem $versions -Filter "RobloxStudioBeta.exe" -Recurse -ErrorAction SilentlyContinue |
                    Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
                if ($studio) { break }
            }
        }
        if ($studio) { break }
    } while ((Get-Date) -lt $deadline)
    Capture "01-after-installer.png" | Out-Null
    if (!$studio) { throw "No RobloxStudioBeta.exe found after official install attempt" }

    $report.installed = $true
    Write-Host "Studio found. Launching local .rbxlx place without credentials."
    $place = Join-Path $root "dist\dont-wake-the-monster.rbxlx"
    if (!(Test-Path $place)) { throw "The built game .rbxlx does not exist." }
    $args = "--task EditFile --localPlaceFile `"$place`""
    Start-Process -FilePath $studio -ArgumentList $args -PassThru | Out-Null
    $report.studio_launched = $true

    Start-Sleep -Seconds 18
    Capture "02-studio-start.png" | Out-Null

    # Explicitly never attempt credential entry or SSO. If blocked at sign-in,
    # the screenshots show it and we stop instead of faking gameplay.
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class WindowFocus {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hwnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hwnd, int cmd);
}
'@ -ErrorAction SilentlyContinue
    $studioProcess = Get-Process RobloxStudioBeta -ErrorAction SilentlyContinue | Where-Object {$_.MainWindowHandle -ne [IntPtr]::Zero} | Select-Object -First 1
    if (!$studioProcess) {
        $report.blocker = "Studio opened without an interactive window (login/headless runner/display problem)."
    } else {
        [WindowFocus]::ShowWindow($studioProcess.MainWindowHandle, 3) | Out-Null
        [WindowFocus]::SetForegroundWindow($studioProcess.MainWindowHandle) | Out-Null
        Start-Sleep -Seconds 4
        # Start Roblox Studio Play test, not a Roblox public game.
        [System.Windows.Forms.SendKeys]::SendWait("{F5}")
        $report.play_key_sent = $true
        Write-Host "Sent Play shortcut (F5) to Studio, collecting real screen frames."
        Start-Sleep -Seconds 7
        Capture "03-after-play.png" | Out-Null
        for ($i = 0; $i -lt 48; $i++) {
            Capture ("frame-{0:D3}.png" -f $i) | Out-Null
            Start-Sleep -Milliseconds 240
        }
    }
    # A window and an F5 keypress do not prove that a play session started.
    # Retain diagnostic screenshots only. Never turn login/error frames into
    # footage that could be mistaken for gameplay.
    if (-not $report.blocker) {
        $report.blocker = "Gameplay has not been verified. Inspect screenshots on an authenticated interactive desktop."
    }
    if (-not $report.play_key_sent) {
        Write-Host "No interactive playtest was started. See screenshots and blocker in diagnostic report."
    }
} catch {
    $report.blocker = $_.Exception.Message
    Write-Host "Environment blocker: $($report.blocker)"
    Capture "99-error.png" | Out-Null
} finally {
    ($report | ConvertTo-Json -Depth 4) | Set-Content (Join-Path $out "diagnostics.json")
    Write-Host "STUDIO_CAPTURE_DIAGNOSTICS=$($report | ConvertTo-Json -Compress)"
}

# An unverified attempt must not appear as a passing gameplay check.
if (-not $report.gameplay_verified) { exit 1 }
