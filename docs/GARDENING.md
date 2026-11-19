# Gardening & Secret Alchemy — v0.4 prototype

This is a **spoiler-free player guide**. The project's **26 hidden formulas**
are intentionally **NOT listed** here or shipped to clients. The recipe
catalog lives server-side in `ServerScriptService/RecipeCatalog`.

## What's available

- **30 plants**: 28 kinds of regular seeds purchasable with the in-game
  coins earned from play, plus 2 premium-only design previews which cannot
  currently be bought.
- **9 personal plots** per player on a procedural 3D garden platform.
- Crops grow by real-world time even after disconnecting; you can apply
  fertilizer once per plot. Several different plant silhouettes distinguish
  blossoms, mushrooms, cacti, grains and fruit.
- **26 secret recipes**, discovered by experimentation: animal foods, creature
  baits, monster lures and plant fertilizer.
- Three recipe tabs inside the garden: **PLOTS**, **SEEDS** and **ALCHEMY**.
- The blank personal recipe book populates **only after your own successful
  experiments**. Saved recipes are retained across sessions when the DataStore
  is available.
- Six secret bait types summon temporary wild creatures and change the chaos
  meter. No permanent pet is awarded by these baits.

## How to build your own recipe book

1. Open **MY GARDEN** (tap on mobile or press G on a keyboard).
2. Plant and harvest a few different crops. New players start with several
   beginner seed packets; more can be bought with regular coins.
3. Enter the **ALCHEMY** tab. The recipe book is **0/26** initially.
4. Tap slots **1**, **2** and optionally **3** to pick actual harvested
   ingredients from your basket. Repeats are allowed.
5. Tap **MIX INGREDIENTS**. The server checks the combination.
6. If it is a real formula, you unlock a named recipe, receive its crafted
   product and see a new page in your book. It also awards 15 game coins
   on the first discovery.
7. If the mix isn't a formula, you still get one edible **Oops Soup**.
   Ingredients are consumed on both success and failure.
8. A discovered recipe can be made again directly from its saved book page;
   an unknown recipe cannot be crafted by guessing its ID.

The formulas are not shown at the outset. Sending fake recipe IDs or fake
items via client network requests does not give the player free items.
Only the server checks combinations, stock and crafting outputs.

## Plant selection

The collection contains (names only, no recipe spoilers):

Bubbleberry, Rocket Carrot, Popcorn Corn, Blush Tomato, Screamer Pepper,
Sunshine Bloom, Moonshroom, Crystal Mint, Gigglefruit, Jellybean Vine,
Glow Pumpkin, Honey Pear, Candy Cane Tree, Cloud Cotton, Frostberry,
Rainbow Radish, Bubble Cabbage, Lava Melon, Whisper Wheat, Gummy Grape,
Jelly Cactus, Neon Mushroom, Stardust Rice, Peppermint, Caramel Apple,
Moon Lotus, Thunder Plum and Marshmallow Root.

**Premium design previews, not purchasable:** Starbloom and Aurora Melon.

Fertilizers include starting Compost plus discoverable Starlight Fertilizer,
Honey Compost and Frost Fertilizer. Aurora Dust is a premium design preview,
not available for purchase or crafting.

## Paid items — still disabled

Possible fixed-outcome products (proposed, **not actual Roblox prices**):

| Item | Fixed content | Proposed Robux |
|---|---|---:|
| Starbloom | 3 seeds | 49 |
| Aurora Melon | 3 seeds | 79 |
| Aurora Dust | 5 fertilizers | 69 |

Every Product ID is **0** and there are no Roblox purchase prompts or
receipt-processing code yet. The game will need a Roblox place, configured
Developer Products and production-safe, idempotent receipt handling BEFORE
any real purchases can be accepted. No paid random crop/gacha outcome.

## Internal layout and verification

- `src/shared/GardenConfig.luau`: public crop names, prices, starter seeds
  and disabled premium items; **no recipe ingredient combinations**.
- `src/server/RecipeCatalog.luau`: all secret formulas, server-only.
- `src/server/Garden.luau`: validates inputs; exact-match experiments; book
  discoveries; inventory; growth; farming and anti-duplication checks.
- `src/server/Game.server.luau`: rate-limited player requests, rewards,
  lure visitors, updates and server-side persistence.
- `src/client/Garden.client.luau`: secret-free ingredient mixer, personal
  book and responsive touch interface.
- `scripts/test_garden.py`: exercises real Luau rules, including blank book,
  exact-match discovery, failed mixes, known-recipes-only crafting, save/load
  and invalid request rejection.
- GitHub Actions checks Luau syntax, source invariants and assembles the
  `.rbxlx` file with Rojo.

**Current validation limitations:** this is a working source/build prototype,
not a confirmed Roblox Studio playtest. Server synchronization, avatar
movement, device UI, production persistence/session locks, physics and
performance still require testing in an authorized Studio session.
