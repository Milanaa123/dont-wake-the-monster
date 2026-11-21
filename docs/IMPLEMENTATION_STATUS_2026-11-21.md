# Don’t Wake the Monster! — verified build status, 2026-11-21

This file reports **implemented and tested source changes**, not a claim that the experience matches the original visual reference or has passed Roblox Studio Play mode.

## Implemented on main

- Codex's original packed 3D mesh library, rigged cosmetic pets, 15-piece R15 outfit, crop meshes, hand-authored texture atlas, local Studio kit and original WAVs.
- Atomic, renewable, four-minute DataStore session leases. Each login acquires a distinct visit token. A conflicting session cannot overwrite the active player's data; a lease is released after a successful final save. Mocked concurrent-server tests run in Luau.
- Original denser mature strawberry geometry, more fruit on some strawberry runners, leafy watermelon crowns, and denser wheat/carrots. The corn kernel-heavy asset remains below the strict per-model mobile polygon budget. Rebuild generated meshes before packaging, including explicit manual uploads.
- A small contextual three-step onboarding: feed a pet, plant a seed, collect a crop. The panel reads real server snapshot events and never grants rewards itself.
- Replace sphere-shaped neon celebration effects with capped noncollidable polygon leaves/petals. Native effects are used for actual server-confirmed actions.
- Strict GLB/mobile-triangle budgets, Rojo build, Luau compilation, gardening/merchant/pet/persistence tests, a binary Studio geometry audit and Lune local mesh hierarchy checks.

## Evidence

- Game/test CI: https://github.com/Milanaa123/dont-wake-the-monster/actions/runs/44851856806
- Authored GLB/mobile budget CI: https://github.com/Milanaa123/dont-wake-the-monster/actions/runs/44851381231
- Source code: https://github.com/Milanaa123/dont-wake-the-monster

## Not yet verified / not finished

- **Real Roblox Studio Play test, gameplay video and live FPS**. Windows runner starts Studio, but the graphical workflow did not authenticate into a running playable session. Treat offline GLB preview images strictly as asset renders, not gameplay screenshots.
- **Final artist-quality fidelity** to the user's detailed 3/4-view garden reference. New vegetation is denser, but a measured real Studio side-by-side art review is still required.
- **Public Roblox audio playback**. Offline Studio kit contains 19 original WAV files. Publishing real audio assets and supplying moderation-approved Roblox asset IDs remains a separate, authenticated task.
- **Published Roblox experience**. This is NOT published; the existing upload workflow stays manual, with private Saved mode by default.
- **Live DataStore session-lock behavior**. Collision/expiry logic is covered by simulated Luau tests, not yet live multi-server Roblox tests.
- **Mobile performance on actual low-end phones**. CI enforces geometry rules, but cannot substitute for GPU/FPS measurement.

## Next real acceptance checks

Open the latest Windows Studio kit and run Play (with developer-authorized login), inspect the player's R15 motion, verify seven core actions (feed, pet, carry, plant, harvest, monster chase, rejoin persistence), capture an actual 3/4 garden frame, and compare it with the reference. Profile three device quality tiers before public release.

No automatic publication and no paid assets have been enabled by this change.
