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
- Coins persist across rejoins in a published test experience.
- No purchases are charged before receipts and policy compliance are implemented.

## Next development targets

1. Studio/runtime QA and fix all reported errors.
2. Replace primitive monsters with original optimized mesh models and animations.
3. Expand to 8-12 collectible creatures, creature inventory and unlock progression.
4. Add multiple environment zones and social group activities.
5. Record telemetry: first action, playtime, D1, rounds survived, session failures.
6. Implement purchase products through server-side receipt handling, after user provides Roblox creator IDs.
7. Soft launch in a private test environment; optimize mobile performance before promotion.

## Anti-exploit approach

- Clients only request feed item names; server checks known items, live character position, proximity, phase and request rate.
- Reward amounts and chaos outcomes are calculated on the server.
- Data is saved with UpdateAsync in guarded calls; failed reads do not overwrite existing data.
- Project does not contain any Roblox credentials, webhook addresses or live product IDs.
