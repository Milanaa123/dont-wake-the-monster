# Roblox Studio verification status — 2026-11-19

## Current cloud desktop attempt

- Inspected the actual interactive cloud desktop: Debian GNU/Linux 13.6, x86-64. Roblox Studio was not preinstalled.
- The normal package installation could not acquire the system package lock. Prepared Debian Wine 10 packages in a user-writable directory, resolved their relocation/dependency errors, and launched the real official `RobloxStudioInstaller.exe` from `https://setup.rbxcdn.com/RobloxStudioInstaller.exe`.
- The actual Roblox Studio Installer window opened. Its own log repeatedly reported `HttpError: TlsVerificationFail` (code 11) when requesting `https://clientsettingscdn.roblox.com/v2/settings/application/PCStudioBootstrapper` and `https://clientsettingscdn.roblox.com/v2/client-version/WindowsStudio64`.
- The installer did not reach a Studio login window or finish installing Studio. The stalled attempt was canceled. No account credentials were entered; there is no active Roblox login handoff.
- The original installer log is preserved at [evidence/cloud-studio-installer.log](evidence/cloud-studio-installer.log). It records network/bootstrap diagnostics, not gameplay.
- **The Roblox game engine did not run. No real gameplay recording was produced. The game was not uploaded or published.**

## Code verification

[Fix commit 9c5a6c7](https://github.com/Milanaa123/dont-wake-the-monster/commit/9c5a6c78df018c9e7ebf9aa1d4d9008896aef792)
passed [GitHub build 44493913763](https://github.com/Milanaa123/dont-wake-the-monster/actions/runs/44493913763):
source/economy/WAV checks, Luau syntax compilation, garden/personality/affection/merchant/persistence suites, and Rojo packaging.
The downloaded CI `.rbxlx` was byte-identical to the local build for that commit
(SHA-256 `8c520cf8cec6407ce9fc2d9aa7e736adf5534fc075b3a3f394381b63a5d58c6e`).
A subsequent camera-button placement correction moves it to the left column to also avoid the pet-care panel.

These checks do not verify rendered graphics, Roblox APIs, physics, multiplayer, or live persistence.
Cross-server profile session locking is still pending.

## Earlier Windows runner attempt

[Windows probe 44487820502](https://github.com/Milanaa123/dont-wake-the-monster/actions/runs/44487820502)
finished green, but its diagnostics said `installed: true`, `cli_task_started: true`, `cli_marker_found: false`.
Its final real screenshot showed the Roblox Studio sign-in screen. This was **not** a successful engine test.
The scripts now return a failure for an unverified probe, preserve diagnostic screenshots,
and do not turn login/error frames into a gameplay video.

## Requirement for the next engine test

An accessible Windows/macOS desktop with functioning Roblox network access and a persistent interactive session
is the supported path. The account owner should confirm Roblox sign-in personally on that desktop.
Then open the built `.rbxlx`, run an actual local Play session, inspect Output/errors, and record that session.
Publishing remains a separate owner-approved action.

---

# Real Roblox Studio capture — verified blocker (2026-11-19)

## What was attempted (no Roblox account credentials used)

Two disposable Windows GitHub Actions runners were launched to build and inspect
the actual game's `.rbxlx` file. Both used Roblox's officially signed Studio
installer (`https://setup.rbxcdn.com/RobloxStudioInstaller.exe`).

- First attempt: [Actions run 44454242929](https://github.com/Milanaa123/dont-wake-the-monster/actions/runs/44454242929).
  Rojo build succeeded; installer launched the Roblox Studio login window.
  The script initially checked the wrong executable location, then timed out.
- Second attempt: [Actions run 44454786790](https://github.com/Milanaa123/dont-wake-the-monster/actions/runs/44454786790).
  Fixed executable discovery. The local place launch was attempted with Studio's
  `--task EditFile --localPlaceFile` CLI parameters, and F5 Play was sent.
  The real screenshots show Roblox Studio still blocked by **Login to Roblox**.
  The startup also briefly displayed a missing/corrupt files message while
  installation was still underway. The final screenshots remained at login.

### Evidence

Run 2 uploaded `studio-capture-evidence`: 52 real screenshots and
`diagnostics.json`, retained temporarily by GitHub Actions.

Result fields: `installed: true`, `studio_launched: true`,
`play_key_sent: true`, `video_generated: false`. These prove that a
Windows Studio window was opened and F5 sent, **not** that gameplay ran.

### Next blocker to resolve

Roblox Studio needs a valid authenticated developer session for this setup.
Do **not** paste Roblox passwords, login cookies, 2FA recovery codes, or API
keys into GitHub source, issues, this chat, or CI logs.

The GitHub-hosted Windows runner is ephemeral: it destroys its login session
after each job. For regular automated gameplay capture, prefer a user-controlled
persistent Windows desktop (local or cloud) with Studio logged in by the
account owner, plus a self-hosted GitHub Actions runner or an authorized
remote automation mechanism.

The user may log into Roblox Studio on their own remote desktop using the
official Roblox authentication flow. Avoid giving credentials to an agent.
Once an authorized, persistent desktop exists, install Studio, open the
`.rbxlx`, start a real local playtest, then record with FFmpeg or Studio's
supported capture tooling.

**Important:** the 2026-11-19 test did not run the game engine or verify the
game's logic, performance, or visual quality. No gameplay footage exists yet.
