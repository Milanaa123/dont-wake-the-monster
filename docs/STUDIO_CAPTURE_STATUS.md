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
