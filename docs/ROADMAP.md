# MVP validation and roadmap

## The intended first play session

1. Spawn on the pastel floating island.
2. Meet your silly follower pet and read the feed controls.
3. Tap a food action; witness a random, clearly explained reaction.
4. Keep feeding to fill the server-wide noise meter.
5. See the giant monster wake, dodge telegraphed shockwaves, and survive for coins.
6. Play another round and see different outcomes.

## Prototype acceptance criteria (to verify in Studio, not merely by CI)

- Spawn and camera work on both 16:9 desktop and mobile screen layouts.
- At least two players can feed pets simultaneously without state corruption.
- All four feed choices are accepted; cooldown and proximity checks reject exploits.
- Reaction types eventually occur over repeated plays; visual effects expire.
- Noise reaches threshold, boss wakes and attacks, timer ends, rewards arrive.
- No uncontrolled part count / anchored-object physics spikes during a 20-minute run.
- Coins, purchased pets, equipped companion, daily claim and quest/discovery progress persist across rejoins in a published test experience.
- Pet purchases spend the correct number of free coins and cannot be repeated for the same pet.
- Each player has three hearts during a wake event; hits, fall-outs and death prevent the survival bonus.
- Starter missions can be earned once, do not duplicate rewards after a rejoin, and catalog tracks all 30 pets.
- New player sees feed buttons on touchscreens and collection/quest/daily interface without overlapping the HUD.
- Each player receives nine garden plots; physical farm zones do not block the main island.
- Ordinary seed packets use free coins; premium seed and fertilizer sales remain disabled until receipt verification.
- Planting, growth while offline, fertilization, harvesting and crafted food produce deterministic amounts.
- Baits create temporary wild visitors and the advertised noise/coin rewards, never random premium pets.
- Garden inventory and plots survive rejoins; no seed duplication or loss during regular sessions.
- A kitten obtained by two different players may have different seeded temperaments, habits and food tastes.
- Ownership migration preserves existing 30-species collections and adds stable personality seeds to older saves.
- Per-pet fears, mood, favorite/disliked food effects and temperament-specific reaction weighting work as expected.
- Bond is earned through valid nearby interactions, cannot be increased by invalid remote commands, and survives a rejoin.
- Social encounters only occur with two nearby players' pets; visual and noise effects are synchronized and rate-limited.
- Mood bubbles, accessories, pet diary and actions are readable and usable on real mobile screens.
- No purchases are charged before receipts and policy compliance are implemented.

## Next development targets

1. Studio/runtime QA and fix all reported errors.
2. Replace primitive monsters with original optimized mesh models and animations.
3. Move the coin/inventory DataStore to a production-safe session-lock design; conduct a two-server reconnect test.
4. Replace the placeholder creature models with original optimized assets and animations.
5. Add multiple environment zones, cooperative objectives and repeatable quests.
6. Record telemetry: onboarding completion, first feed, playtime, D1, round outcomes, purchases and errors.
7. Configure optional **deterministic** premium seed/fertilizer products and cosmetics, with server-side idempotent receipt processing, only after the Roblox experience and product IDs exist. No paid random rewards.
8. Soft launch privately; test multiple mobile devices, age/region settings, safety and moderation before promotion.

## Anti-exploit approach

- Clients only request feed item names; server checks known items, live character position, proximity, phase and request rate.
- Reward amounts and chaos outcomes are calculated on the server.
- Server validates pet ownership, spending, daily reward and quest completion; clients cannot submit coin balances.
- Server also validates seed identifiers, plot numbers, stock, fertilizer, crafting, lures and garden teleports. Clients cannot mint paid crops.
- Data is saved with UpdateAsync in guarded calls; failed reads do not overwrite existing data. Prototype still lacks a distributed session lock, so simultaneous-server writes must be addressed before release.
- Project does not contain any Roblox credentials, webhook addresses or live product IDs.
