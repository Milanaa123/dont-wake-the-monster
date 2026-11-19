# The Secret Seed Forest — v0.9

**Status:** implemented in the Roblox source and checked by GitHub CI. The Roblox Studio runtime, collision/accessibility of paths, playtesting, mobile frame rate and audio playback have **not** yet been verified.

## Main gameplay

1. Open **🧭 FIND SEEDS** (top-left on mobile; J on a computer).
2. Choose one of the 3 exploration zones, tap **TRACK** next to a seed cache. The journal tracks distance and locally highlights the chosen seed cache.
3. Walk to the golden seed marker in the 3D world. Hold the game's **FIND SEEDS** ProximityPrompt (touch or E). This is a real *physical* server-created interaction, not a free seed button in a menu.
4. You receive 1–2 ordinary seeds. Every cache has a **240-second personal cooldown**, saved in your player profile. Other players can collect their own finds without stealing yours.
5. Plant the seeds in your 9 garden beds, grow crops, investigate secret recipes, feed animals and cause fun trouble.

**No premium/paid seed can appear from a wild cache.** The basic public free-to-play odds are 65% common (2 seeds), 28% uncommon (1 seed), 7% rare (1 seed), before the pet's curiosity adjustment (up to +5 percentage points added to the roll; this shifts probabilities). For the rare Lava Melon at one specific ruin cache, part of the rare category has an extra special case. These are gameplay tuning values, not paid loot odds.

## Expedition zones

| Region | Seed cache 1 | Cache 2 | Cache 3 |
|---|---|---|---|
| 🌼 Whispering Meadow | Daisy Trail | Bumblebee Bush | Golden Hollow |
| 🌙 Moonlit Marsh | Mushroom Footprint | Foggy Stump | Bubble Pools |
| 🗿 Giggle Ruins | Old Idol | Crystal Tablet | Secret Gateway |

The 9 physical caches collectively offer all **28 freely obtainable plant species** in the prototype. They have glowing objects, individual zone signs and procedural scenery using soft foliage, flowers, wooden stumps, slate ruins and bright mushrooms.

## Weather, unusual harvests and animal help

Every ~100 seconds, the server switches one of four weather conditions:

| Weather | Growth remaining-time multiplier | Mutation name | Chance |
|---|---:|---|---:|
| ☀️ Golden Sunshine | ×0.94 | Golden | 12% |
| 🌧️ Sparkling Rain | ×0.82 | Dewy | 18% |
| 🌙 Moonflower Mist | ×0.90 | Moonlit | 22% |
| 🌪️ Giggle Pollen Storm | ×0.88 | Giggly | 28% |

Weather's **growth acceleration applies to active plots once per planted crop**; a crop can still acquire its first mutation in a later weather event. A mutated crop gives a **fixed 2× yield** (no paid randomness). Mutation collections persist. Gardening times continue to elapse offline using real UTC timestamps, but **new live weather events only affect players present on a server**.

**🐾 Pet Gardener:** when standing in your personal garden, tap **ASK PET TO HELP GROW** for a growing plot. A pet with higher curiosity shortens the remaining growth time by 12–30%. Each plant can receive this help once, and the request is validated on the server. This complements existing pet personalities, cuddling, fears and funny reactions.

## New surprise gardening events

Roughly once per minute while the giant sleeps, a planted garden can trigger a gentle ridiculous mishap:
- A plant starts singing opera.
- Vegetables have a dance-off.
- A giant carrot sneezes.
- A watermelon meows.
- Sunflowers gossip about Giggles.

These events add some **shared noise** (potentially waking the boss), particle effects and original silly sound cues when the appropriate Roblox audio ID is configured. Surprise events **never delete** purchased seeds or harvested crops.

## Exploration album and group goals

- The **Seed Hunter's Journal** tracks 28 seed species, four weather variants, found caches, countdowns and a tracked destination.
- **Daily free quest:** find 5 caches, earn a one-time 45 in-game coin reward (UTC day).
- **Cooperative Seed Festival:** 12 collected seed caches across the server triggers an island celebration and 35 free coins for each participating online player. No rewards are sold or made exclusive.
- **Pet personality advantage:** curiosity raises the odds of a rare find modestly (server-calculated, not client-editable), creating reasons to care for different pets.

## Testing and safety

- `SeedHunt.collect` validates cache IDs, inventory capacity, cooldowns, date, drop tables and a server-generated RNG roll.
- `Game.server.luau` also verifies that the live player character is alive, the giant sleeps, and the player is physically within 16 studs of the correct cache.
- `Garden.weather` and `Garden.assist` validate plant state and prevent stacking boosts.
- Existing save data is migrated: collections, creature personalities, crops, recipes and currency are kept.
- Pure Luau unit tests execute via GitHub Actions: cooldown, rare items, daily quest, weather mutation and pet-tending cases are tested.
- Production DataStore session locking, authenticated Roblox Studio integration, security review, multi-device QA and actual recording remain release blockers.

These features are original implementations of inspiration from farming, exploration and pet-care games, not copied code or game assets.
