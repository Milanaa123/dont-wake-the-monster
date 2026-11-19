# Soundtrack, comedy effects and Roblox release checklist (v1.0)

**Source status:** these are original, algorithmically synthesized WAV files committed to this repository. None were copied from copyrighted viral meme clips. They are **not audible in Roblox until creator-owned audio IDs are uploaded and configured**. GitHub Actions cannot bypass Roblox moderation or grant audio permissions.

## Audio package

| File in `assets/audio` | Role | AudioConfig field |
|---|---|---|
| `calm-garden-theme.wav` | Gentle looping garden melody | `MusicAssetId` |
| `sleepy-forest-ambience.wav` | Quiet nature atmosphere | `AmbienceAssetId` |
| `monster-chase-theme.wav` | Faster music when Giggles wakes | `ChaseMusicAssetId` |
| `SeedFind.wav` | Found ordinary seeds | `Cues.SeedFind` |
| `RareDiscovery.wav` | Found a rare seed or recipe | `Cues.RareDiscovery` |
| `WeatherChime.wav` | Weather changes | `Cues.WeatherChime` |
| `Boing.wav` | Silly chaos reaction | `Cues.Boing` |
| `MonsterWake.wav` | Monster awakens | `Cues.MonsterWake` |
| `Victory.wav` | Round survived | `Cues.Victory` |
| `Festival.wav` | Seed festival | `Cues.Festival` |
| `SillyStorm.wav` | Giggle storm | `Cues.SillyStorm` |
| `HarvestPop.wav` | Harvest a crop | `Cues.HarvestPop` |
| `MutationSparkle.wav` | Mutated crop harvested | `Cues.MutationSparkle` |
| `CatSwat.wav` | Sudden cat behavior | `Cues.CatSwat` |
| `tiny-violin-fail.wav` | Dramatic vegetable fail | `Cues.TinyViolin` |
| `suspicious-meow.wav` | Laughing pumpkin / feline joke | `Cues.SuspiciousMeow` |
| `cartoon-record-scratch.wav` | Unexpected prank or slapstick | `Cues.RecordScratch` |
| `comedy-drum-sting.wav` | Silly duet / special merchant purchase | `Cues.ComedySting` |
| `original-cat-purr-loop.wav` | Spatial, increasingly loud kitten purr | `Config.PurrSoundId` |

The client script `src/client/Soundscape.client.luau` manages looping music, 3D-independent event cues, per-cue cooldowns, music/FX mute and calm/chase crossfades. Cat purrs are separate 3D sounds attached to the pet, currently controlled by the effects code in `src/server/World.luau`.

## Enabling audible music (creator account required)

1. Open your Roblox Creator Dashboard with the account that owns the experience.
2. Upload each WAV as a Roblox audio asset, subject to current file limits, permissions and moderation. Verify the account/experience is permitted to use it.
3. Copy the numeric asset IDs into `src/shared/AudioConfig.luau` for the music, ambience and 15 cues.
4. Copy the purr asset ID into `src/shared/Config.luau` (`Config.PurrSoundId`).
5. Build the place using GitHub Actions, then test the result inside authenticated Roblox Studio on mobile emulation and at least two real clients.
6. Lower music/effects volumes if they are too loud. Do not claim that an upload was completed until Roblox Creator Dashboard confirms it.

Docs: https://create.roblox.com/docs/sound/objects

## Game systems available in v1.0

- 30 crops, nine farm plots, 26 secret recipes and four craftable fertilizing options.
- Three physical seed-hunting biomes, nine searchable caches, rare seeds, a personal album and daily search quest.
- Four weather types, four crop mutations, pet gardening assistance and a cooperative Seed Festival.
- A traveling merchant with four coin-only offers that rotate every 12 minutes. Bought slots persist.
- Funny harvest incidents and pet-to-pet social interactions that raise the monster noise meter.
- Unique pet personalities, carrying, continuous petting and unpredictable cat purring.
- All premium product IDs remain 0; **no real-money purchase functionality is enabled**.

## Remaining blockers to public release

- In-engine visual and audio QA, especially on Android/iOS.
- Production DataStore safety/session-lock design, crash recovery and receipt handling before monetization.
- A real first-session usability test; check if players understand how to find a seed, plant it, feed a pet and survive a wake without instructions.
- Profiling parts/particles and tuning the number of rendered gardens for lower-end phones.
- Actual player retention metrics after a private test, rather than guessing that virality is guaranteed.
