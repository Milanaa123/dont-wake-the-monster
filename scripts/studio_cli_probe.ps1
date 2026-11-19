#Requires -Version 5.1
# Probe supported Roblox Studio --task RunScript with NO user credentials.
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$root = (Resolve-Path ".").Path
$out = Join-Path $root "capture"
New-Item -ItemType Directory -Path $out -Force | Out-Null

function Capture([string]$name) {
  try {
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName System.Windows.Forms
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen
    if (-not $screen) { throw "No display" }
    $bounds = $screen.Bounds
    $bitmap = [System.Drawing.Bitmap]::new($bounds.Width, $bounds.Height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.CopyFromScreen($bounds.Location,[System.Drawing.Point]::Empty,$bounds.Size)
    $bitmap.Save((Join-Path $out $name),[System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose(); $bitmap.Dispose()
  } catch { Write-Host "Capture unavailable: $($_.Exception.Message)" }
}
$report = [ordered]@{installed=$false;cli_task_started=$false;cli_marker_found=$false;requires_login=$null;details=""}
try {
  Capture "00-initial.png"
  $installer=Join-Path $env:RUNNER_TEMP "RobloxStudioInstaller.exe"
  Invoke-WebRequest -Uri "https://setup.rbxcdn.com/RobloxStudioInstaller.exe" -OutFile $installer -TimeoutSec 110 -UseBasicParsing
  $signature=Get-AuthenticodeSignature $installer
  if ($signature.Status -ne "Valid" -or $signature.SignerCertificate.Subject -notmatch "Roblox") { throw "Invalid official Roblox installer signature." }
  $setup=Start-Process -FilePath $installer -PassThru
  $studio=$null
  $until=(Get-Date).AddSeconds(165)
  do {
    Start-Sleep -Seconds 7
    $running=Get-Process RobloxStudioBeta -ErrorAction SilentlyContinue|Select-Object -First 1
    if ($running) { try {$studio=$running.Path} catch{} }
    if (-not $studio) {
      $dirs=@((Join-Path $env:LOCALAPPDATA "Roblox\Versions"),(Join-Path $env:ProgramFiles "Roblox\Versions"))
      foreach ($dir in $dirs) {
        if (Test-Path $dir) {
          $found=Get-ChildItem $dir -Filter RobloxStudioBeta.exe -Recurse -ErrorAction SilentlyContinue|Select-Object -First 1
          if ($found) {$studio=$found.FullName;break}
        }
      }
    }
    if ($studio) {break}
  } while ((Get-Date) -lt $until)
  Capture "01-installed.png"
  if (-not $studio) {throw "Studio exe not found"}
  # Prevent the common installer race: RobloxStudioBeta.exe appears before
  # the bootstrapper has finished downloading the complete Studio distribution.
  Write-Host "Studio executable located; waiting for installation stabilization."
  $stable=0
  $lastSize=-1
  $waitUntil=(Get-Date).AddSeconds(140)
  do {
    Start-Sleep -Seconds 10
    $installers=@(Get-Process -Name RobloxStudioInstaller,RobloxStudioLauncherBeta -ErrorAction SilentlyContinue)
    $size=(Get-Item -LiteralPath $studio).Length
    if ($installers.Count -eq 0 -and $size -eq $lastSize) {$stable+=1} else {$stable=0}
    $lastSize=$size
  } while ($stable -lt 3 -and (Get-Date) -lt $waitUntil)
  # Give Roblox's launched child downloaders time to finish placing resources.
  Start-Sleep -Seconds 25
  $signatureStudio=Get-AuthenticodeSignature $studio
  if ($signatureStudio.Status -ne 'Valid' -or $signatureStudio.SignerCertificate.Subject -notmatch 'Roblox') {
    throw "Refusing unsigned or non-Roblox Studio executable."
  }
  $report.installed=$true
  $file=Join-Path $root "dist\dont-wake-the-monster.rbxlx"
  $script=Join-Path $root "scripts\studio_cli_smoketest.luau"
  $output=Join-Path $out "studio-command-output.log"
  $args=@("--task","RunScript","--localPlaceFile",$file,"--runScriptFile",$script,"--outputFile",$output,"--quitAfterExecution")
  $report.cli_task_started=$true
  Write-Host "Starting documented RunScript task using local .rbxlx; no login automation."
  $p=Start-Process -FilePath $studio -ArgumentList $args -PassThru
  Start-Sleep -Seconds 15
  # Bring Studio's own window to foreground instead of screenshotting runner logs.
  try {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class StudioFocus {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hwnd);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hwnd, int mode);
}
'@ -ErrorAction SilentlyContinue
    $window=Get-Process RobloxStudioBeta -ErrorAction SilentlyContinue | Where-Object {$_.MainWindowHandle -ne [IntPtr]::Zero}|Select-Object -First 1
    if ($window) {
      [StudioFocus]::ShowWindow($window.MainWindowHandle,3)|Out-Null
      [StudioFocus]::SetForegroundWindow($window.MainWindowHandle)|Out-Null
      Start-Sleep -Seconds 2
    }
  } catch { Write-Host "Studio focus failed: $($_.Exception.Message)" }
  Capture "02-cli-running.png"
  try {$p.WaitForExit(55000)|Out-Null} catch {}
  Capture "03-cli-completed.png"
  $report.cli_marker_found = (Test-Path $output) -and ((Get-Content $output -Raw) -match 'DWTM_STUDIO_CLI_FINISHED')
  if (Test-Path $output) {
    $safe=Get-Content $output -Raw
    $safe.Substring(0,[Math]::Min($safe.Length,4000))|Set-Content (Join-Path $out "cli-output-summary.txt")
  }
  if (-not $report.cli_marker_found) {$report.details="RunScript did not print completion. This does NOT prove Roblox gameplay ran."}
  else {$report.details="Studio CLI Lua marker exists. This verifies editing-time script execution only, not gameplay."}
} catch {
  $report.details=$_.Exception.Message
  Capture "99-error.png"
}
finally {
  $report|ConvertTo-Json|Set-Content (Join-Path $out "diagnostics.json")
  Write-Host ("DWTM_CLI_PROBE="+($report|ConvertTo-Json -Compress))
}
