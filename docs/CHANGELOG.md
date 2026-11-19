# Changelog

## v1.0.1 — Local playtest and save fixes (2026-11-19)
- Catch DataStore initialization failures so an unpublished/local session can continue without saving; failed reads never authorize overwriting saved data.
- Expose profiles to gameplay only after loading completes, and ignore disconnected players after a pending read returns.
- Serialize autosave and leave writes per profile. A leave save waits and takes a fresh snapshot, preserving changes made while autosave was yielding.
- Save different players concurrently at shutdown; stop accepting gameplay requests during shutdown.
- Disable Studio analytics calls, which cannot provide meaningful published-game metrics.
- Move the camera toggle below the seed journal in the left column; the previous right-column coordinates overlapped the audio controls.
- Studio diagnostic attempts now fail when execution is unverified; login/error screenshots are never encoded as gameplay.
- Added deterministic Luau persistence tests. Engine, visual and multiplayer verification remain pending.

## v1.0 — Living Seed Merchant & Comedy Soundscape (2026-11-19)
- Added four rotating merchant offers every 12 minutes, priced in regular coins only. One purchase per offer per player; purchased slots and rotation persist across rejoins.
- Each offer contains two seeds. The merchant cycles through all 28 earnable crops across rotations, with no paid random loot.
- Added merchant stock and next-restock display in the Garden Seeds tab, plus automatic refresh.
- Harvesting now has a temperament-sensitive chance to trigger a funny crop incident; a singing wheat, laughing pumpkin, pet sneeze or dramatic vegetable adds noise and can wake Giggles.
- Social pet meetings and sudden cat reactions trigger additional original comedy cues.
- Composed six more original WAVs: cozy forest ambience, chase music, suspicious meow, tiny violin fail, record scratch and comedy sting.
- Client audio mixer now crossfades between calm/chase music and controls ambience with the music toggle.
- Sound IDs remain **0** until the Roblox account owner uploads and authorizes audio assets; code alone does not make them audible in Roblox.
- Added merchant Luau tests, source and WAV integrity checks, and CI packaging.
- No Roblox Studio playtest or device QA has yet been performed.

## v0.9 — Secret Seed Forest & Original Music (2026-11-19)
- Built 3 original fairytale biomes, nine physically searchable seed caches, a mobile seed journal, server distance checks and per-player 4-minute cache respawns.
- All 28 ordinary seed species can be discovered without Robux; rare seed and pet curiosity chances are server-owned.
- Four weather phases modify growing-time and create visibly glowing Golden/Dewy/Moonlit/Giggly mutations (fixed 2x yield).
- Pets can help with gardening, while singing plants, dancing vegetables and sneezing carrots may add noise and wake the giant.
- Added a daily five-find explorer reward and a server-wide 12-find Seed Festival with cooperative coin bonuses.
- Updated tutorial to include exploration, alchemy, cuddle-noise and rescues.
- Created original ~18-second gentle background loop and 11 original sound-effects WAVs, a Roblox client sound mixer and mute buttons.
- Audio assets remain disabled until uploaded to the creator's Roblox account and IDs are configured; GitHub WAV sources alone are not audible in Roblox.
- Added official Roblox AnalyticsService custom events for basic first-session funnels; only report data after an experience is published.
- Luau compilation, seed/weather/cat rules tests, audio integrity checks and Rojo packaging are automated. In-engine Roblox Studio gameplay is still untested.

## v0.8 — Cuddle & Purr Panic (2026-11-19)
- Added tap-to-carry companions in the avatar's arms and local raised-arm pose (for supported humanoid rigs).
- Added hold-to-stroke input for mobile touch/mouse and R/C keyboard controls.
- Cats Pip and Zuzu can gradually purr more loudly depending on individual temperament, mood, bond and stroke duration.
- The louder a contented cat purrs, the more server-side noise accumulates; excessive purring may wake Giggles.
- Cats can suddenly reject petting (hiss, swipe, hide or get the zoomies); carrying can be refused by grumpy or shy animals.
- Added real-time purr volume bar, animated mood bubbles and soft particle effects; all controls validate distance, duration and action state on the server.
- Generated an original `assets/audio/original-cat-purr-loop.wav` for creator upload. Audio ID deliberately remains 0 until ownership/permission is configured.
- Added harvest baskets, watering cans and extra flowers to the cozy garden environment.
- Added pure Luau affection/noise tests, automatic compilation and refreshed anti-exploit/source checks.
- **No authenticated Roblox Studio playtest or recording yet**. Actual mobile animation/sound still need in-engine testing.

## v0.7 — Cottage Garden Art & Camera (2026-11-19)
- Acted on the user's uploaded game-art reference **in the Roblox source**, not by producing a separate image.
- Warm outdoor color grading, sunlight, gentle bloom, atmosphere and soft-shadow settings.
- Original procedurally built orange orchard, strawberry berry bushes, wheat clumps, melons, flower beds, warm soil paths and cottage fences.
- Greener and less neon island landscaping, reduced older candy-like decorations.
- Growth-stage crop embellishments for strawberries, tomatoes, peppers, carrots and melon types.
- Toggleable 3/4 camera on mobile/desktop to help view the gardens from an elevated angle.
- All scenery remains anchored/non-colliding; the visual changes remain placeholder primitives pending final low-poly meshes.
- GitHub build + Luau static syntax passed. Visual result and mobile performance have NOT been observed in authenticated Roblox Studio.

## v0.6 — Living Personalities (2026-11-19)
- Gave every owned animal a unique, saved identity instead of using only one species-wide behavioral label.
- 12 possible temperaments, 12 habits, seven fears, seven preferred kinds of affection, four snack tastes with a different favorite and disliked one, six independently varying traits.
- Kittens Pip and Zuzu have cat whiskers and tails; two players' cats can be Grumpy, Kind, Wild, Curious, etc.
- Real server behavior: feeding affects happiness and monster noise, 3 repeatable friendship interactions, mood-dependent idle animation, pet personality effects on weighted chaos reactions, fear response when the giant wakes.
- Social pet meetings cause one of 12 kinds of spontaneous interactions and sometimes raise the noise meter; no repeatable money farming.
- Introduced friendship ranks and a trust threshold for revealing a pet's food preferences.
- The smartphone PET DIARY exposes the pet's changing needs, permanent traits, fears and habits.
- Added pure Luau personality tests for seed reproducibility, 12x12 catalog variety, save restoration and social behavior. All paid products remain disabled.
- Requires authorized Roblox Studio 3D/multiplayer testing and production DataStore safeguards before launch.

## v0.5 — Active Co-op Rescue (2026-11-19)
- Each monster wake-up now spawns seven rescueable stray creatures around the island.
- Players must rescue a server-population-scaled goal of two to five before the round ends.
- In-world E/touch ProximityPrompts show SAVE ME! and require real player proximity, a living character, and an active boss phase.
- Each animal rescued earns 8 free coins. Participants who meet the team goal and survive receive an extra 30 coins.
- Live rescue progress shows above the feeding controls; tutorial explains grow–mix–feed–rescue.
- No fake Roblox Studio video has been produced. A previous Windows-hosted Studio attempt reached the account login screen; actual runtime capture requires an authorized session.
- Luau syntax and Rojo build checks are automatic; multiplayer, difficulty, on-device appearance and DataStore performance still require Studio testing.

## v0.4 — More Creatures & Secret Recipe Book (2026-11-19)
- Expanded animal collection from 10 to **30** species, adding unique decorative features and six comedy temperaments.
- Expanded crop catalog from 12 to **30** plants: 28 obtainable with in-game coins, 2 disabled premium designs.
- Expanded the personal farm from 6 to **9** beds, with varied blossom, fungus, cactus, grain and fruit visuals.
- Moved all **26** secret alchemy recipes to ServerScriptService; no formulas are sent to new players.
- Blank personal book at the start; players experiment with 2–3 crops, unlock successful recipes, and save discoveries. Known formulas can be recreated from the book.
- Failed experiments consume ingredients but always produce edible **Oops Soup**; six bait types now have distinct visitor/noise effects.
- Added validation and real Luau execution tests for discovery, recipe secrecy, crafting, save migration and input sanitization.
- Roblox Studio gameplay, performance and DataStore concurrency still require actual runtime testing.

## v0.3 — Gardening & Alchemy (2026-11-19)
- Six personal garden beds, up to 12 physical gardens, offline crop growth and visible growth stages.
- Twelve crop types (ten ordinary seed packets, two disabled premium seed previews).
- Eight deterministic recipes: four pet feeds, two wild visitor baits, two fertilizers.
- Aurora Dust premium fertilizer design preview; no Robux checkout is active.
- Mobile seed shop, crop inventory, craft list, fertilizer and real-time garden timers.
- Garden state saved with existing prototype player profile; save concurrency needs hardening.
- Luau runtime tests of growing/harvesting/crafting and GitHub Actions checks.
- Roblox Studio gameplay still untested.

## v0.2 — Creatures & progression (2026-11-19)
- 10 procedural creatures with a coin-based collection and equip screen.
- 12 chaos reactions, 6 island-wide surprises, disco/rainbow effects and bubble visuals.
- Three starter missions, unique-reaction discoveries and a once-per-UTC-day coin gift.
- Three-heart boss fight, survival/failure results, mobile heart HUD.
- Progress persistence expanded beyond coins; fixed previous max-coin save logic (which was incompatible with spending).
- Luau compilation and Rojo builds checked by GitHub Actions; structural regression checks added.
- Still requires Roblox Studio gameplay/device tests and production DataStore hardening.

## v0.1 — Initial prototype (2026-11-19)
- Procedural island, sleeping boss, basic companion pets, noise and feed controls.
- Server-authoritative chaos effects, waves, shared wake round, initial coin persistence.
- GitHub Actions automated .rbxlx artifact build.
