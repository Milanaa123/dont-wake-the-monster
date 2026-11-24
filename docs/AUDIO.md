# Original music & comedy sound effects — v1.0

**Implementation status (2026-11-19):** Source code and the original WAV library
are committed to this repository. They pass audio-integrity checks and the
Roblox source bundle builds. **They will not play inside Roblox until the
experience owner uploads them as Roblox audio assets and configures IDs.**

## Files included in `assets/audio/`

| File | Intended use |
|---|---|
| `calm-garden-theme.wav` | Gentle 18-second background music on the island |
| `monster-chase-theme.wav` | Faster 9-second loop while the giant is awake |
| `sleepy-forest-ambience.wav` | Quiet 9-second breeze/birds ambience |
| `original-cat-purr-loop.wav` | Original 4-second sound for a contented cat, with dynamic 3D volume |
| `PuppyYip.wav` and `BirdEcho.wav` | A warned puppy bark and bird answer. Rebuild with `python3 scripts/companion_calls.py`. Both public IDs are zero. |
| `SeedFind.wav` | Picking up a seed cache |
| `RareDiscovery.wav` | Rare seed found |
| `WeatherChime.wav` | Weather shift / pet helping |
| `Boing.wav` | Cartoon bounce |
| `MonsterWake.wav` | Giggles wakes |
| `Victory.wav` | Round survival |
| `Festival.wav` | Cooperative seed festival |
| `SillyStorm.wav` | Magical weather surprise |
| `HarvestPop.wav` | Harvesting |
| `MutationSparkle.wav` | Special crop mutation |
| `CatSwat.wav` | Grumpy cat reaction |
| `tiny-violin-fail.wav` | Dramatic vegetable incident |
| `suspicious-meow.wav` | Unexpected pet/crop reaction |
| `cartoon-record-scratch.wav` | Pranks, sudden embarrassing moments |
| `comedy-drum-sting.wav` | Silly harvests and social dance scenes |

All are synthesized for this game, not excerpts from commercial meme sounds.
The project does not claim that Roblox moderation has approved these assets.

## Activate playback

1. Create an experience using the account that will own the game.
2. Open Roblox Creator Dashboard / asset manager and upload the individual WAV files.
3. Check Roblox moderation, audio availability and experience permissions.
4. In `src/shared/AudioConfig.luau` replace **only** the numeric `0`
   values with the actual allowed asset IDs: `MusicAssetId`,
   `ChaseMusicAssetId`, `AmbienceAssetId`, and the **15** `Cues`.
5. Set `Config.PurrSoundId` in `src/shared/Config.luau` to the separately
   uploaded `original-cat-purr-loop.wav` audio ID.
6. Rebuild the place file and check real playback in an authorized Roblox
   Studio session. Never post a Roblox password, login cookie or security code.

## In-game mix

- Calm garden music plays while the monster sleeps, and crossfades into the
  chase loop when it wakes. Forest ambience is most audible while sleeping.
- The user can turn **music** and **sound effects** on/off independently.
- Audio includes client-side repetition protection for event cues.
- Sounds and visuals continue to work even if no audio ID is available, but
  the game remains *silent* until the uploads are configured.
- Sound assets have not been listened to or quality-tested in Roblox Studio.
  Loop seams, levels, mobile speaker mix and permissions require real tests.

Roblox references:
- https://create.roblox.com/docs/sound/objects
- https://create.roblox.com/docs/audio/assets
