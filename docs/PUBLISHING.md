# Roblox publishing from GitHub (Android, no local PC)

**Verified documentation as of 19 November 2026.** The source/build and two
official Roblox upload backends are implemented. The user's Roblox account
does not yet have a known linked Place ID, API key, uploaded revision or public
game. The build-only CI results are not evidence of live Roblox publication.

**START HERE: [Complete mobile-only decision tree and instructions](PUBLISH_FROM_ANDROID_2026.md).**

## What the workflow actually does

Manual workflow:
https://github.com/Milanaa123/dont-wake-the-monster/actions/workflows/upload-roblox.yml

- Triggered **manually only**, never by a regular source-code push.
- Creates a complete `dist/dont-wake-the-monster.rbxlx` file using Rojo.
- Validates code and checks for Roblox place ID and an Open Cloud API key
  stored as `ROBLOX_API_KEY` in GitHub Actions Secrets. The secret is never
  committed to GitHub.
- `backend = assets` (default): official Assets Update API
  `PATCH https://apis.roblox.com/assets/v1/assets/{placeId}`.
  API key needs **Assets → Read + Write** for the target game. The API
  asynchronously reports the actual place revision ID and whether it was published.
- `backend = universes` (fallback when chosen explicitly): official legacy
  Place Publishing API
  `POST https://apis.roblox.com/universes/v1/{universeId}/places/{placeId}/versions?versionType=Saved|Published`.
  API key needs **universe-places → Write** and BOTH numeric IDs.
  This operation returns `versionNumber` in its response.
  The legacy documented limit is 10 MiB; check limits before use.
- `place_id` and optional `universe_id` can be entered in the Run workflow
  dialog, or stored once as non-secret GitHub Actions variables
  `ROBLOX_PLACE_ID` and `ROBLOX_UNIVERSE_ID`.
- `upload_mode = Saved` adds an unpublished revision only; it is **not**
  playable even by the owner in Roblox app until the place is subsequently
  **Published**.
- `upload_mode = Published` publishes the **place version**.
  The game can and should remain **PRIVATE** while the creator playtests it.
  Making the **experience PUBLIC** is a separate Creator Dashboard
  audience/release operation with Roblox age/eligibility requirements.

## Minimum owner actions (secure, from phone)

1. In [Creator Dashboard](https://create.roblox.com/dashboard/creations),
   check for an **existing test experience / starting place** and copy the
   Place ID. If none exists, first check for **Build** in the official Roblox mobile app
   (limited countries and age verification). **Studio Lite cannot reliably
   create the first experience on an empty account** according to its own FAQ.
   Otherwise one-time official Windows/macOS Studio is necessary.
   See [all verified options](PUBLISH_FROM_ANDROID_2026.md).
2. Create a Roblox Open Cloud key in Creator Dashboard for the selected
   backend and save it in
   [GitHub Actions Secrets](https://github.com/Milanaa123/dont-wake-the-monster/settings/secrets/actions)
   as `ROBLOX_API_KEY`. NEVER send the key in chat, documents or issues.
3. Open the [manual upload action](https://github.com/Milanaa123/dont-wake-the-monster/actions/workflows/upload-roblox.yml),
   enter the appropriate place ID, choose `assets` + `Saved`,
   and click Run workflow.
4. After a successful upload and checking the target place, manually run
   `Published` while the experience is still private. Play the actual game
   from the Roblox Android app; this is a live test, **not** a simulated video.
5. Release publicly in Creator Hub only after fixing live engine bugs,
   checking ratings/eligibility, and confirming the experience is ready.

Roblox official Assets API documentation:
https://create.roblox.com/docs/cloud/guides/usage-place-publishing

Roblox Universe API reference:
https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/cloud/universes-api/v1.json

Roblox current public release requirements:
https://create.roblox.com/docs/production/publishing/publish-games-and-places

## Known limitations

- GitHub cannot, through documented Open Cloud API-key endpoints, create a
  completely new Universe / initial Place from nothing. The owner needs to
  create or use an existing place in their Roblox account first.
- **No Roblox API key or Place ID is currently connected** in this repo.
- Neither a passing GitHub Actions build nor a successful API upload proves
  that actual gameplay, HUD, saves, audio or multiplayer logic works.
- Uploaded **.rbxlx place files overwrite the contents of their targeted
  place**. Do not target any important pre-existing game without a backup.
- Roblox Build games edited outside Build can lose the automatic Moderate
  content rating and require the Content Ratings Questionnaire.
- Roblox Studio is available for Windows/macOS, not Android. Cloud Windows
  desktops are a separate, potentially paid option; Roblox may reject
  unsupported virtual machines.
- No purchased items or Robux monetization is active. Stable server-side
  session locks and `MarketplaceService.ProcessReceipt` are required before
  any monetary release.

**This project stays private by default. No automatic public release is enabled.**
