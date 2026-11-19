# Changelog

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
