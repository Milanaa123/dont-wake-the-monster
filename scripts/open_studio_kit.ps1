param([string]$StudioPath, [switch]$InstallOnly)
$ErrorActionPreference = "Stop"
if (!$StudioPath) {
    $roots = @("$env:LOCALAPPDATA\Roblox\Versions","$env:ProgramFiles\Roblox\Versions")
    $StudioPath = Get-ChildItem -Path $roots -Filter RobloxStudioBeta.exe -Recurse -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
}
if (!$StudioPath) { throw "Install Roblox Studio from create.roblox.com and open it once." }
$sig = Get-AuthenticodeSignature -LiteralPath $StudioPath
if ($sig.Status -ne "Valid" -or $sig.SignerCertificate.Subject -notmatch "Roblox") { throw "Expected the signed Roblox Studio executable." }
$source = Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot "content") -Directory |
    Where-Object { $_.Name -match '^dwtm_orchard_[a-f0-9]{12}$' }
if (@($source).Count -ne 1) { throw "Extract the complete Studio kit first." }
$target = Join-Path (Join-Path (Split-Path $StudioPath) "content") $source.Name
New-Item -ItemType Directory -Path $target -Force | Out-Null
foreach ($file in Get-ChildItem -LiteralPath $source.FullName -File) {
    $destination = Join-Path $target $file.Name
    if (Test-Path -LiteralPath $destination) {
        if ((Get-FileHash -LiteralPath $destination).Hash -ne (Get-FileHash -LiteralPath $file.FullName).Hash) {
            throw "Different file already present at $destination"
        }
    } else { Copy-Item -LiteralPath $file.FullName -Destination $destination }
}
if (!$InstallOnly) {
    $place = Join-Path $PSScriptRoot "DontWakeTheMonster-Studio.rbxlx"
    Start-Process -FilePath $StudioPath -ArgumentList ('--task EditFile --localPlaceFile "' + $place + '"')
}
