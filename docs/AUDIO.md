# Original music & comedy sounds — v0.9

The source repository contains **13 original WAV files**:
- **calm-garden-theme.wav** — soft original ~18-second looping music for the sunny island.
- **SeedFind.wav** — gentle three-step bell pickup.
- **RareDiscovery.wav** — more elaborate magical rare-seed discovery.
- **WeatherChime.wav** — short weather transition cue.
- **Boing.wav** — exaggerated, original springy "meme" reaction.
- **MonsterWake.wav** — funny low-pitched monster warning.
- **Victory.wav** — short survival celebration.
- **Festival.wav** — friendly cooperative seed-festival fanfare.
- **SillyStorm.wav** — comical warbling weather/garden mishap.
- **HarvestPop.wav** — happy crop-harvest pop.
- **MutationSparkle.wav** — shiny mutation reward.
- **CatSwat.wav** — comical hiss/swipe response.
- **original-cat-purr-loop.wav** — original ~4-second synthetic cat purring loop, authored earlier.

All sounds are original synthetic compositions/effects authored for this project; no copyrighted songs or meme samples have been copied. WAVs are mono, 16-bit PCM at 9 kHz (garden theme and new effects) or 12 kHz (cat purr), so Roblox may resample/compress them on import.

**Important: audio playback in Roblox is currently disabled.** WAV files placed in GitHub **are not Roblox audio assets**. They cannot play simply because a project builds successfully.

## Enabling legitimate playback

1. Create your Roblox experience/place and configure ownership in Creator Dashboard.
2. Upload each WAV from `assets/audio/` to Roblox's official audio asset manager; check your account's permissions and moderation outcome.
3. Copy the actual numeric audio asset ID for each uploaded file.
4. Open `src/shared/AudioConfig.luau`, insert the relevant IDs for `MusicAssetId` and the 11 entries in `Cues`.
5. For the cat's spatial purr, set `Config.PurrSoundId` in `src/shared/Config.luau`.
6. Rebuild and test in an authenticated Roblox Studio session. Sound IDs need permission for the game/universe; inspect output logs if a cue doesn't play.

No account password, login cookie or 2FA code should go in this repo or chat.

## In-game playback controls

- **MUSIC ON/OFF** and **EFFECTS ON/OFF** buttons appear on the right.
- The theme fades to a quieter volume during monster attacks.
- Triggered sounds have short client-side repetition cooldowns and independent volumes.
- Sounds occur on seed finds, rare discoveries, weather changes, festival completion, crop harvest, mutation, pet-food combos, funny garden incidents, giant wake-up, survival and angry cat swats.
- The HUD and physical animations still work if the user mutes sounds or audio IDs are not yet configured.
- The system does **not** auto-load or play arbitrary asset IDs from remote users.

References:
- https://create.roblox.com/docs/sound/objects
- https://create.roblox.com/docs/audio/assets
- https://create.roblox.com/docs/production/monetization/virtual-items
