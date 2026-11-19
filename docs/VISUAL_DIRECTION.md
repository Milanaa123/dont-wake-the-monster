# Cottage Garden visual direction & Roblox competitors

**Date reviewed:** 19 November 2026
**Status:** committed procedural visual changes and Rojo source compile. NOT an in-engine screenshot or finished art pass.

## What the supplied visual reference conveys

- Warm angled late-afternoon sunlight, soft shade, low-poly/painted-looking leafy trees
- Green garden ground, sandy footpaths, pale wooden fences, yellow wheat
- Recognizable ripe fruits: clustered red strawberries, big striped melons and oranges in trees
- A cheerful, cozy, readable miniature world seen from an elevated three-quarter camera
- Compact color palette: sage and yellow-green foliage, warm soil, blush/pink flowers, soft cream highlights
- No need for photorealistic assets or extreme particle effects

## What has actually been implemented

`src/server/CottageGardenStyle.luau` procedurally constructs ORIGINAL terrain-adjacent decoration:
oranges and green canopies, red berry shrubs, golden wheat, melon patches, small daisies,
warm garden soil paths, wood fences and occasional pebbles. The v0.8 style pass also adds small harvest baskets, watering cans and extra cottage flower edging beside real personal beds. It also defines Lighting
ColorCorrection, warm Atmosphere, modest Bloom, SunRays and softer shadows.
`src/server/World.luau` calls this on map generation, farm construction and crop-stage changes.
`src/client/CottageCamera.client.luau` adds optional elevated 3/4 view, on by default,
with a mobile button and V hotkey to switch back to Roblox follow-camera.

**This is not a copy of the reference asset.** The original example image is only a
style direction. The garden elements are generated from our own Luau geometry.
They are anchored and non-colliding, but still increase render workload; a
mobile Studio playtest and performance profiling are necessary.

## Relevant Roblox competition and what we can learn

We researched a *targeted sample*, **not every Roblox game**, from Roblox charts,
game pages and creator/update notes.

| Game | Documented main loop / retention hook | What to apply to our game (design proposal only) |
|---|---|---|
| Grow a Garden | Plant/harvest/grow idle crops; active Roblox gardening category | Crops should visibly mature and have a compelling reason to return |
| Adopt Me! | Pet care, houses, social pet-raising; public updates about friendship levels, pens and reward systems | Distinct creature personalities, home/garden customization, cooperative social routines |
| Steal An Egg and Collect Rare Pets | Retrieve eggs across biomes, hatch and progress a collection/index | Add earned discoverable creature variants and a meaningful collection album (without stealing others' property) |
| Plants & Brainrots | Plant seeds, then plants take part in defending/fighting enemies | Give harvested crops active utility (pet food, lures and temporarily protective items), not just money |
| 99 Nights in the Forest | Gather resources with friends and survive threatening nights | Keep short, repeatable multiplayer survival phases where pets and players affect the round |

### Sources consulted

- Roblox Charts: https://www.roblox.com/charts?SortFilter=3
- Grow a Garden current snapshot: https://roradar.info/games/grow-a-garden
- Official Adopt Me developer updates: https://www.playadopt.me/news/pet-pen-and-pet-releaser-features-notes
- Steal an Egg overview: https://bloxodes.com/wiki/steal-an-egg
- Plants & Brainrots game description: https://www.rolimons.com/game/127742093697776
- 99 Nights in the Forest overview: https://topblox.app/games/99-nights-in-the-forest
- Official Roblox outdoor lighting guidance: https://create.roblox.com/docs/environment/lighting
- Official Roblox art/performance background: https://create.roblox.com/docs/art/overview-studio

## Improvements I recommend next (NOT YET IMPLEMENTED)

1. **First 60 seconds:** a delightful guided task: plant a berry, feed your pet,
   cause one funny reaction, get to the first monster encounter. No confusing ten-button menu.
2. **Weather with consequences:** sunset rain speeds crops, thunder frightens timid pets,
   crazy pollen creates silly temporary mutations. Tell players what is happening.
3. **Dynamic recognizable animal animation:** ears, tail, eye-expression, bounce and mood
   specific behavior. Real animated models to replace procedural balls.
4. **Collection album with earned variants** and discovered food/recipe combinations.
   Avoid pay-to-win; preserve clear deterministic paid product descriptions.
5. **Co-op garden festivals and monster rescue missions:** players have a shared reason to
   play together, while their individual personalities create unpredictable situations.
6. **Cosmetic monetization after core QA:** greenhouse decorations, animated pet outfits,
   house themes and effects that don't decide who can survive.
7. **Quality gates:** real Roblox Studio playtest, mobile render profiling, verified saved
   profile session locks and receipt processing before any Robux sales.

## Current blockers

The Windows GitHub Actions attempt installed official Roblox Studio but hit
account authentication. No valid in-engine gameplay video or screenshot has
been obtained. The styles added here are code and should be assessed
**inside Studio** for camera control, mobile FPS, light effects, plant contrast and
clipping. Do not advertise these as fully visually validated.

## November 19, 2026 competitor snapshot update (independent third-party trackers)

- Roblox charts list **Steal An Egg and Collect Rare Pets** and **Adopt Me!** among the largest pet/collection-adjacent games. The pet-care loop remains a major adjacent audience: https://rivalducks.com/apps/radar/charts/top-playing-now
- **Throw Food For Animals** appeared high in the November 9–15 Roblox weekly ranking; its immediate feed-to-animal interaction is a reference for clearly visible feedback, not a feature to clone: https://rblxstat.com/blog/roblox-weekly-report-2026-11-15
- **Grow a Garden** remains an important category example for growing crops while offline, visual milestones and repeat visits: https://playsurge.gg/most-visited
- Official Roblox documentation recommends a content-update cadence across connected systems such as pets: https://create.roblox.com/docs/production/game-design/content-updates

**What we implemented instead of copying another hit:** individually temperamental purring/petting that accumulates shared noise, a cooperative consequence (monster wake), and personal garden ingredients that make the interaction loop genuinely different. These charts are time-stamped third-party observations, not proof of future virality.
