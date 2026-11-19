# Roblox publishing using GitHub only (manual)

**Important:** This workflow is READY TO CONFIGURE but has not been connected to a
Roblox account or run. It cannot create a new Roblox universe/place, and it does not
test Roblox engine behavior. It updates an **existing** place.

## Setup from phone (one time)

1. Create an empty private Roblox experience/place first. If your account cannot
   create an experience from mobile, a remote computer with Roblox Studio may be
   needed ONCE for this step.
2. In Roblox Creator Dashboard, open the experience -> Places -> target place.
   Copy the numeric **Place ID** from the configuration page URL.
3. On Roblox Creator Dashboard, create a **dedicated Open Cloud API key** with
   Assets API access: **Read + Write** for the specific experience. Limit its
   scope and expiry. Keep it secret.
4. In GitHub repository -> Settings -> Secrets and variables -> Actions ->
   **New repository secret**, add exactly `ROBLOX_API_KEY`. Never paste it into
   a README, source code, issue or chat.
5. On GitHub -> Actions -> **Upload Roblox place (manual)** -> Run workflow.
   Enter the **existing Place ID**. Start with **Saved**. This uploads a new
   unpublished place version; it does not make it publicly playable.
6. Once a remote Studio test confirms that gameplay works, you can trigger
   the same workflow and deliberately choose **Published** to publish that
   place version. Roblox visibility/access settings are separate.

No GitHub push automatically publishes. The workflow only runs when manually
triggered. It refuses to run from branches other than main.

## How the API works

The workflow builds `dist/dont-wake-the-monster.rbxlx`, then makes a PATCH request
to the current Roblox Assets API:

`PATCH https://apis.roblox.com/assets/v1/assets/{placeId}`

The multipart fields are:
- `request`: JSON `{"assetId":123,"assetType":"Place","published":false}`
  (or `published:true` after choosing Published).
- `fileContent`: the Rojo-created `.rbxlx`, MIME `application/xml`.

It then polls `GET /assets/v1/operations/{operationId}` until Roblox confirms the
operation succeeded or fails. The API key is read from GitHub Secrets.

Roblox's current official reference:
https://create.roblox.com/docs/cloud/guides/usage-place-publishing

## Known blockers

- **No Roblox place has been linked to this repo yet.**
- Automatic GitHub tests cannot catch engine runtime errors, bad animations,
  camera issues, mobile UI collisions or multiplayer race conditions.
- Publishing by Assets API can require Studio for certain asset types;
  check Roblox's documented limitations.
- Before public publishing: runtime QA, production-safe DataStore session locks,
  creator eligibility, content policy checks, and all relevant Roblox settings.
- No paid products are currently connected; the pet shop uses free coins only.
