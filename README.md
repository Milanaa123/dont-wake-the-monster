# DON'T WAKE THE MONSTER! 👾

A colorful, chaotic multiplayer Roblox prototype: feed your ridiculous pet, trigger unpredictable reactions, fill the noise meter, and survive the giant monster's wake-up tantrum.

## Prototype features

- Procedurally constructed floating island, decorations, glowing crystals, clouds and an enormous sleeping monster.
- **Cottage Garden art direction (v0.7)** inspired by the player's green, sunlit gardening reference: soft golden-hour color grading, warm atmospheric haze, original orange orchard, strawberry bushes, melons, wheat, flower patches and dirt paths. Personal gardens have wood fencing and more recognizable crop details.
- **Optional 3/4 garden-view camera** enabled by default, switch to follow camera with the on-screen button or V key. This is actual Roblox client code, not a generated mockup.
- Thirty collectible, differently styled companion pets with procedural cosmetic details, bought using **in-game coins only**.
- **Gardening & Secret Alchemy v0.4**: 30 crops, 9 plots/player, 28 coin-earnable seed varieties, offline growth, staged art and 26 hidden experimental recipes.
- **Traveling Seed Merchant v1.0:** four discounted ordinary seed packs rotate globally every 12 minutes, with one purchase per offer per player per restock. The merchant uses only earned coins, and purchase limits persist through reconnects.
- **Secret Seed Forest v0.9:** three original explorable biomes, nine physical seed caches with hold-to-search prompts, personal cooldowns and a 28-seed discovery album.
- Four rotating weather conditions can change plant growth and create Golden, Dewy, Moonlit and Giggly mutations with a fixed doubled harvest. Pets help find seeds and tend growing crops.
- **Cooperative Seed Festival:** 12 server-wide seed searches reward participating players. Funny garden incidents such as singing plants and meowing melons can help wake the giant.
- **Original audio package v1.0:** soft 18-second garden music, an additional 9-second monster chase loop, 9-second forest ambience, fifteen original sound effects (including cartoon record scratch, funny meow, tiny-violin fail and drum sting), plus the earlier cat purr. WAVs are in GitHub; actual Roblox playback requires owner-uploaded asset IDs. The game crossfades from calm music to chase music when the giant wakes, with independent music and effects mute buttons.
- **Analytics hooks:** first feed, first seed, first planting, recipe discovery, first survival and 10-minute participation (real data only after publishing).
- The player's recipe book **starts empty**. Mixing 2–3 harvested ingredients discovers new formulas, and successful discoveries persist. Failed mixes create funny edible Oops Soup. No ingredient formulas are exposed in the client before discovery.
- Four earnable fertilizer types speed up growth; two premium seed types and one premium fertilizer remain disabled previews.
- **Living Pets v0.6**: every owned animal receives its own saved personality, not merely a species-wide type. 12 temperaments (from Kind to Grumpy and Wild), 12 habits, 7 fears, 7 ways of showing affection, favorite/disliked foods and six numerical character traits.
- Pets respond to snacks, petting, play, calming and the monster; their changing happiness, energy, hunger, friendship level and current mood affect reactions. Two kittens of the same species may act completely differently.
- **Cuddle & Purr Panic v0.8**: pick up a pet in the avatar's arms, stroke by HOLDING a touch/mouse button, and watch individually tempered cats become louder and louder. A cat's escalating purr contributes real server noise and can wake Giggles. Moody felines may suddenly hiss, swat or wriggle out of the player's arms.
- **Original purr WAV** is packaged in `assets/audio/original-cat-purr-loop.wav`. Audible playback is OFF until the creator uploads it to Roblox and configures `Config.PurrSoundId`; purring animations, gameplay noise and UI already work without it.
- **12 social encounter types** when nearby animals from different players meet, including dance-offs, friendships, pranks, arguments, hide-and-seek and naps. Social meetings can increase the shared noise gauge.
- Smartphone **PET DIARY** reveals character traits, trust, moods and unlockable food tastes. Temperament-based accessories and 3D idle behavior offer visible differences.
- Four mobile-friendly feed buttons, **12 reaction types**, food combos, and six spontaneous island-wide surprises.
- Shared noise meter, randomized monster attacks, three-hit survival, and coins for surviving rounds.
- **Co-op rescue challenge** every time Giggles wakes: race around the island to rescue runaway animals (2–5 target by player count). Server checks proximity, awards 8 free coins for a rescue, and pays participating survivors a 30-coin completion bonus.
- **First-play tutorial** on mobile and desktop explains the main gameplay loop; a ? button reopens it.
- Starter quests, reaction discovery album, daily in-game coin treat, a collection/inventory screen and pet swapping.
- Persistent coins, owned pets, equipped pet, discovered reactions and quest progress (when Roblox DataStore works).
- Responsive touchscreen controls and keyboard support.
- Automatic Luau compilation, Rojo `.rbxlx` build and source/invariant checks through GitHub Actions.

**Status: v1.0 source-code MVP. GitHub CI compiles, runs pure-Luau garden + personality tests and builds a .rbxlx; actual Roblox Studio runtime, appearance and multiplayer testing have NOT yet been performed.** Procedural art is a placeholder for final optimized meshes and animations. NO real Robux payments or marketplace product IDs are connected. In-game coin prices are not Robux prices. Cross-server persistence needs session-lock hardening before public release.

## No-computer workflow

1. Open the repository's **Actions** tab and select **Build Roblox place**.
2. Open the latest completed run, download its `roblox-place` artifact (`.rbxlx` inside a zip).
3. Open the place in Roblox Studio on Windows/macOS or a remote PC for an actual playtest. GitHub builds do not execute the game engine.
4. An optional **manual**, Saved-by-default upload workflow now exists: see [docs/PUBLISHING.md](docs/PUBLISHING.md). It only updates an existing Roblox place after a secret API key and Place ID are configured. No GitHub push publishes to Roblox. Never put the key in source, issues or chat.

## Source layout

- `src/shared/Config.luau`: balance, feed items, creature types and reaction catalog.
- `src/server/World.luau`: procedural world and monster art.
- `src/server/CottageGardenStyle.luau`: original warm landscaping, orchard, berry patches, fencing, lighting and crop details.
- `src/client/CottageCamera.client.luau`: 3/4 garden view with optional third-person toggle.
- `src/server/Game.server.luau`: authoritative multiplayer game loop, hearts, boss damage, pet effects and saving.
- `src/server/Progression.luau`: catalog, buying/equipping pets, daily rewards, gardening persistence and per-pet personality save migration.
- `src/shared/PetPersonality.luau`: unique seeded genetics, mood, individual preferences, social scenes and bonding.
- `src/shared/ExpeditionConfig.luau`, `src/server/SeedHunt.luau`: 3 biomes, 9 caches, weather and foraging.
- `src/server/ForestWorld.luau`, `src/client/SeedExplorer.client.luau`: procedural forest graphics, physical pickup prompts, tracking and album UI.
- `src/shared/AudioConfig.luau`, `src/client/Soundscape.client.luau`: audio ID mapping, event-driven SFX, fade/mute controls.
- `assets/audio/`: 13 original music and SFX WAVs, awaiting Roblox audio import.
- `src/shared/PetAffection.luau`: real-time cat purring, stroke tolerance, random overstimulation and global noise.
- `src/client/PetCare.client.luau`: touch hold/pick-up controls, R/C shortcuts, purr volume meter and arms pose.
- `assets/audio/original-cat-purr-loop.wav`: an original synthesized 4-second purr loop, pending authorized Roblox asset upload.
- `scripts/test_affection.py`: real Luau runtime tests for cat stroking, purr noise, refusals and bounds.
- `src/client/PetDiary.client.luau`: touch-friendly detailed personality journal and pet/play/comfort actions.
- `scripts/test_personality.py`: real Luau execution tests for deterministic temperament variety, bonding, food preferences and social outcomes.
- `src/shared/GardenConfig.luau`: crop catalog, recipes and disabled premium product definitions.
- `src/server/Garden.luau`: authoritative farming, hidden-recipe discovery and crafting.
- `src/server/RecipeCatalog.luau`: **server-only** secret formulas, never replicated to the client.
- `src/client/Garden.client.luau`: mobile garden, seed shop, ingredient mixer and personal recipe book.
- `scripts/test_garden.py`: isolated Luau runtime tests for farming, hidden recipes, discoveries, persistence and anti-exploit rules.
- `src/client/HUD.client.luau`: controls, notifications, noise, survival and live rescue objective progress.
- `src/server/RescueObjective.luau`: server-side co-op mission with animal rescue prompts, distance validation and rewards.
- `src/client/HowToPlay.client.luau`: first-play instruction overlay and help button.
- `src/client/Collection.client.luau`: pet inventory, shop and quest tracking.
- `scripts/validate_project.py`: offline source-structure and economy checks.
- `scripts/publish_roblox.py` and `.github/workflows/upload-roblox.yml`: optional, manually triggered place upload (not currently connected).
- `default.project.json`: Rojo build manifest.
- `.github/workflows/build.yml`: safe build-only CI pipeline.

## First launch without owning a PC

**Android setup and first authorized Studio playtest:** [Russian step-by-step guide](docs/START_FROM_ANDROID.md). Build-only GitHub CI has passed; this does not substitute for a real Roblox Studio test.

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

See the [Secret Seed Forest guide](docs/SEED_FOREST.md), [original soundtrack setup](docs/AUDIO.md), [cuddling and purring guide](docs/PET_CARE.md), [visual direction and competitor audit](docs/VISUAL_DIRECTION.md), [Living Pets character system](docs/PERSONALITIES.md), [Gardening guide](docs/GARDENING.md), [Changelog](docs/CHANGELOG.md) and [Roadmap](docs/ROADMAP.md).
