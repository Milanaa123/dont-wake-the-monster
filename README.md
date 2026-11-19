# DON'T WAKE THE MONSTER! 👾

A colorful, chaotic multiplayer Roblox prototype: feed your ridiculous pet, trigger unpredictable reactions, fill the noise meter, and survive the giant monster's wake-up tantrum.

## Prototype features

- Procedurally constructed floating island, decorations, glowing crystals, clouds and an enormous sleeping monster.
- Thirty collectible, differently styled companion pets with procedural cosmetic details, bought using **in-game coins only**.
- **Gardening & Secret Alchemy v0.4**: 30 crops, 9 plots/player, 28 coin-earnable seed varieties, offline growth, staged art and 26 hidden experimental recipes.
- The player's recipe book **starts empty**. Mixing 2–3 harvested ingredients discovers new formulas, and successful discoveries persist. Failed mixes create funny edible Oops Soup. No ingredient formulas are exposed in the client before discovery.
- Four earnable fertilizer types speed up growth; two premium seed types and one premium fertilizer remain disabled previews.
- Each animal has a distinctive look and one of six comedy temperaments affecting, but not determining, chaos outcomes.
- Four mobile-friendly feed buttons, **12 reaction types**, food combos, and six spontaneous island-wide surprises.
- Shared noise meter, randomized monster attacks, three-hit survival, and coins for surviving rounds.
- Starter quests, reaction discovery album, daily in-game coin treat, a collection/inventory screen and pet swapping.
- Persistent coins, owned pets, equipped pet, discovered reactions and quest progress (when Roblox DataStore works).
- Responsive touchscreen controls and keyboard support.
- Automatic Luau compilation, Rojo `.rbxlx` build and source/invariant checks through GitHub Actions.

**Status: v0.4 source-code MVP. GitHub CI builds, compiles and executes isolated garden rules, but Roblox Studio runtime/multiplayer/device testing has NOT been performed.** Procedural art is a placeholder for final optimized meshes and animations. NO real Robux payments or marketplace product IDs are connected. In-game coin prices are not Robux prices. Cross-server persistence needs session-lock hardening before public release.

## No-computer workflow

1. Open the repository's **Actions** tab and select **Build Roblox place**.
2. Open the latest completed run, download its `roblox-place` artifact (`.rbxlx` inside a zip).
3. Open the place in Roblox Studio on Windows/macOS or a remote PC for an actual playtest. GitHub builds do not execute the game engine.
4. An optional **manual**, Saved-by-default upload workflow now exists: see [docs/PUBLISHING.md](docs/PUBLISHING.md). It only updates an existing Roblox place after a secret API key and Place ID are configured. No GitHub push publishes to Roblox. Never put the key in source, issues or chat.

## Source layout

- `src/shared/Config.luau`: balance, feed items, creature types and reaction catalog.
- `src/server/World.luau`: procedural world and monster art.
- `src/server/Game.server.luau`: authoritative multiplayer game loop, hearts, boss damage, pet effects and saving.
- `src/server/Progression.luau`: catalog, buying/equipping pets, daily rewards and gardening persistence.
- `src/shared/GardenConfig.luau`: crop catalog, recipes and disabled premium product definitions.
- `src/server/Garden.luau`: authoritative farming, hidden-recipe discovery and crafting.
- `src/server/RecipeCatalog.luau`: **server-only** secret formulas, never replicated to the client.
- `src/client/Garden.client.luau`: mobile garden, seed shop, ingredient mixer and personal recipe book.
- `scripts/test_garden.py`: isolated Luau runtime tests for farming, hidden recipes, discoveries, persistence and anti-exploit rules.
- `src/client/HUD.client.luau`: controls, notifications, noise and survival UI.
- `src/client/Collection.client.luau`: pet inventory, shop and quest tracking.
- `scripts/validate_project.py`: offline source-structure and economy checks.
- `scripts/publish_roblox.py` and `.github/workflows/upload-roblox.yml`: optional, manually triggered place upload (not currently connected).
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
- [x] GitHub Actions Rojo build and Luau syntax checks verified
- [ ] Roblox Studio runtime / multiplayer playtest
- [ ] Custom creature and environment art
- [ ] Production DataStore & economy tests
- [ ] Monetization IDs, purchase receipt handling and age/regional compliance
- [ ] Mobile performance profiling, moderation and public release

See [Gardening guide](docs/GARDENING.md), [Changelog](docs/CHANGELOG.md) and [Roadmap](docs/ROADMAP.md).
