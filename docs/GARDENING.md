# Gardening & Alchemy — v0.3 prototype

The 2026-11-19 source release adds **12 plant types**, **6 farming plots per
player**, **8 recipes**, free-coin seed packs, staged crops in the 3D world, offline
growth and a smartphone-accessible garden UI.

**Status: compiled and rule-tested, NOT yet played in Roblox Studio.**
These are procedural placeholder models, not final mesh artwork.

## How to play

1. Tap **MY GARDEN (G)** on mobile (or press G on desktop).
2. Open **SEEDS**. Buy a packet of **3** ordinary seeds using the coins earned
   from your pet's chaos. Beginner seeds are already in your bag.
3. In **PLOTS**, select a seed by cycling the seed selector. Tap **PLANT** on an
   empty bed, then optionally **USE FERTILIZER**. Growth counts real time even
   when the player is offline.
4. Once ripe, tap **HARVEST** to collect crops. There are also physical beds
   around the island: **VISIT MY PHYSICAL GARDEN** teleports you to yours.
   Teleporting is blocked while Giggles is attacking.
5. Open **CRAFT** to turn crops into new pet food, monster/creature bait and
   fertilizer. Feed crafted snacks or throw bait from this screen.

## Crop catalog

| Seed | Growth | Yield | Coin price for 3 seeds |
|---|---:|---:|---:|
| Bubbleberry | 45s | 3 | 9 |
| Rocket Carrot | 65s | 3 | 15 |
| Popcorn Corn | 90s | 4 | 25 |
| Blush Tomato | 75s | 3 | 20 |
| Screamer Pepper | 125s | 3 | 38 |
| Sunshine Bloom | 115s | 3 | 42 |
| Moonshroom | 180s | 3 | 65 |
| Crystal Mint | 155s | 3 | 55 |
| Gigglefruit | 245s | 4 | 110 |
| Jellybean Vine | 225s | 4 | 95 |
| Starbloom | 195s | 4 | Premium preview ONLY |
| Aurora Melon | 260s | 5 | Premium preview ONLY |

The ten regular crops are obtainable with in-game coins. The two premium
variants are defined in source, but have no Robux store ID and **cannot be
purchased** in the current build.

## Recipes

| Recipe | Ingredients | Result |
|---|---|---|
| Bubbleberry Mash | 2 Bubbleberry + 1 Tomato | 2 crafted feeds (Candy type) |
| Screaming Soup | 2 Screamer Pepper + 1 Carrot | 2 crafted feeds (Pepper type) |
| Moon Candy | 1 Moonshroom + 2 Crystal Mint | 2 crafted feeds (Star type) |
| Bouncy Bubble Tea | 1 Jellybean Vine + 2 Bubbleberry | 2 crafted feeds (Bubble type) |
| Silly Creature Bait | 2 Popcorn Corn + 1 Sunshine Bloom | 1 lure: 1 temporary wild visitor, +8 earned coins, +11 noise |
| Monster Snack Lure | 1 Gigglefruit + 2 Moonshroom | 1 lure: 3 temporary wild visitors, +20 earned coins, +28 noise |
| Compost | 1 Carrot + 1 Tomato | 2 fertilizers: 35% off remaining growth time |
| Starlight Fertilizer | 2 Crystal Mint + 2 Sunshine Bloom | 1 fertilizer: 60% off remaining growth time |

Bait summons **temporary visual wild visitors**, not collectible pets, and
the reward is deterministic. The animals disappear after a few seconds.
Only one fertilizer dose is allowed per plot. The third fertilizer,
**Aurora Dust**, is a paid-content *design placeholder* (80% off remaining
growth time); it is not available for purchase or crafting yet.

## Premium product concepts — NOT ACTIVE

Suggested catalog concepts (not actual Roblox prices):

| Item | Deterministic purchase content | Suggested default price |
|---|---|---:|
| Starbloom seed packet | 3 Starbloom seeds | 49 Robux |
| Aurora Melon packet | 3 Aurora Melon seeds | 79 Robux |
| Aurora Dust pack | 5 Aurora Dust fertilizers | 69 Robux |

Source: `src/shared/GardenConfig.luau -> PremiumProducts` (all
`productId=0`). The UI says **COMING SOON**. **No checkout, charging, or
delivery of paid items is enabled**. Actual pricing is set by the creator
in Roblox Creator Dashboard and may vary by product/region.

We will only turn these on once:

- A Roblox experience exists under the creator's own account.
- Actual developer product IDs are supplied **without sharing account
  credentials**.
- Server-side `MarketplaceService.ProcessReceipt` validates Product ID,
  user, purchase ID, delivery and idempotency. A purchase callback/event from
  the client is **never** proof of payment.
- A production-safe, session-locked DataStore design is added to avoid lost
  entitlements during simultaneous sessions or server crashes.
- A paid purchase is **not** converted into a random egg, crop, mutation,
  gacha or unknown reward. Premium seeds always grow the listed crop with a
  deterministic fixed yield; fertilizer reduces growth time by a fixed
  percentage. Any future paid randomness would need policy review,
  published numerical odds and regional restrictions.

Official developer references:

- https://create.roblox.com/docs/production/monetization/developer-products
- https://create.roblox.com/docs/production/monetization/paid-random-items
- https://create.roblox.com/docs/scripting/security/client-server-boundary
- https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing

## Technical implementation

- `GardenConfig.luau`: crop catalog, crafting recipes, premium placeholders.
- `Garden.luau`: deterministic buy/plant/harvest/fertilize/craft/consume,
  input validation and serialization.
- `Game.server.luau`: authoritative actions and rewards; protects premium
  inventory from client requests.
- `World.luau`: up to 12 per-player farm zones, 6 beds per zone, growth
  stages and colored crop models.
- `Garden.client.luau`: touch UI, timing, crafting, collection and inventory.
- `Progression.luau`: one saved player profile including the garden.

Static source checks, the Luau compiler, and a **real Luau execution test**
validate the garden rules in GitHub Actions. The execution tests cover seed
purchases, planting, premature harvest rejection, growth acceleration,
deterministic harvests, recipes, lures, inventory persistence and invalid
input rejection.

**Limitations:** GitHub Actions isn't Roblox Studio: gameplay/physics/mobile
performance and DataStore integration remain unverified. The existing
prototype DataStore currently lacks distributed session locks and is not
production-ready for paid inventories.
