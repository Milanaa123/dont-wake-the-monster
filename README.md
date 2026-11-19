# DON'T WAKE THE MONSTER! 👾

A colorful, chaotic multiplayer Roblox prototype: feed your ridiculous pet, trigger unpredictable reactions, fill the noise meter, and survive the giant monster's wake-up tantrum.

## Prototype features

- Procedurally constructed floating island, decorations, glowing crystals, clouds and an enormous sleeping monster.
- One expressive companion creature per player (five color/species variants).
- Four mobile-friendly feed buttons, with **twelve possible reactions** and combo effects.
- Shared noise meter, timed monster wake-ups, randomized shockwave and sneeze attacks.
- Cooperative rewards (coins), server-authoritative cooldowns and persistent coin saves.
- Responsive HUD for mobile and desktop.
- Automated `.rbxlx` builds with GitHub Actions + Rojo.

**Status:** source-code MVP, not yet verified in Roblox Studio or published. Assets are procedural primitives, not final custom models/animations. Purchases are intentionally NOT connected to real Robux products yet.

## No-computer workflow

1. Open the repository's **Actions** tab and select **Build Roblox place**.
2. Open the latest completed run, download its `roblox-place` artifact (`.rbxlx` inside a zip).
3. Open the place in Roblox Studio on Windows/macOS or a remote PC for an actual playtest. GitHub builds do not execute the game engine.
4. For future publishing we can set up a *separate, gated* Open Cloud deployment workflow after a Roblox experience exists. Never place API keys in source files, issues or chat.

## Source layout

- `src/shared/Config.luau`: balance, feed items, creature types and reaction catalog.
- `src/server/World.luau`: procedural world and monster art.
- `src/server/Game.server.luau`: multiplayer game loop, noise, pet movement, chaos, rewards and saving.
- `src/client/HUD.client.luau`: controls, notifications and accessibility.
- `default.project.json`: Rojo build manifest.
- `.github/workflows/build.yml`: safe build-only CI pipeline.

## Local development (optional)

Install [Rojo](https://rojo.space), then run:

```sh
rojo build default.project.json --output build/dont-wake-the-monster.rbxlx
```

In Studio, select **Play** to test; enable Studio API services only for isolated test data where appropriate. Live data saving is designed to degrade gracefully when Studio DataStore access is disabled.

## Current development milestones

- [x] Source repository initialized
- [x] Gameplay code, world generator, client HUD drafted
- [ ] GitHub Actions build verified
- [ ] Roblox Studio runtime / multiplayer playtest
- [ ] Custom creature and environment art
- [ ] Production DataStore & economy tests
- [ ] Monetization IDs, purchase receipt handling and age/regional compliance
- [ ] Mobile performance profiling, moderation and public release

See `docs/ROADMAP.md` for test criteria and next steps.
