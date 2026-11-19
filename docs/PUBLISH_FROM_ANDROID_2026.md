# Roblox publication without a PC — verified paths (19 November 2026)

**Project:** [Don't Wake the Monster!](../README.md)  
**Status:** `main` compiles and produces `dont-wake-the-monster.rbxlx` in GitHub Actions. **The game is NOT yet owned by a Roblox experience/place, uploaded, tested live or publicly released.** This guide does not require handing over a Roblox password, 2FA code, browser cookie or an Open Cloud API key.

## Two separate operations, often confused

1. **Create the experience and its starting Place ID in the creator's Roblox account.** Roblox currently does **not** document a standard Open Cloud endpoint to create a brand-new Universe/Place using a GitHub API key.
2. **Upload the existing built 3D place** to that Place ID and publish its *version* using Roblox Open Cloud. This can be automated fully by GitHub Actions, **without Roblox Studio**. It does NOT automatically change the Roblox experience's public audience.

The [official Roblox Assets API](https://create.roblox.com/docs/cloud/guides/usage-place-publishing) and the older [Place Publishing API](https://create.roblox.com/docs/cloud/guides/usage-place-publishing) both update existing places. The legacy Universes endpoint is documented at [Roblox's OpenAPI reference](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/cloud/universes-api/v1.json).

## First attempt: check for an existing place on your Android phone

1. Open [Creator Dashboard — Creations](https://create.roblox.com/dashboard/creations) in Chrome and log in directly to Roblox yourself.
2. Open **Experiences**. If your account already has an experience (perhaps a default place), open it → **Places**.
3. Tap its starting-place tile to open the place configuration. The **Place ID** is the number after `/places/` in its URL, e.g. `.../experiences/222222/places/333333/configure` means **Place ID = 333333**, **Universe ID = 222222**.
4. If you have any existing unneeded place, **back it up or create a new test place before uploading**. Uploading the GitHub file replaces the place's contents. Never overwrite a place that contains important unrelated work.

**If an existing spare/test place exists, skip the Build/Studio steps below entirely.** No Roblox Studio is needed to deploy our already-built source.

## If the new account has no experience/place

Pick exactly one creation method (these create a *starting place*, NOT our final game's actual code):

### A. Official Build tab on Android (only if available)

- Roblox app → **Build** → type `Create a private test game named Don't Wake the Monster! with an empty island`. Let the app create a game.
- **Do not automatically tap Publish/public release**; use the available private/preview experience path first.
- Open the game in Creator Dashboard and obtain the Place ID. Then try the GitHub **Saved** upload below.
- **Not yet verified:** Open Cloud `.rbxlx` replacement of a Build-created place. It is technically a Roblox place and Roblox says Build games can be opened in Studio, but the combined Open Cloud overwrite flow is **not directly confirmed by Roblox documentation**.
- Modifying a Build creation outside Build can remove its automatic Moderate content rating; you then need to complete the Roblox Content Ratings Questionnaire.
- **Availability:** Roblox says the Build rollout is regional and age-checked. Its October 2026 earnings transcript names tests in New Zealand, Singapore, Serbia and Thailand and says broader U.S. rollout is planned for December 2026 and global rollout for 2027. Do not assume this feature appears in Poland or elsewhere.
- References: https://en.help.roblox.com/hc/en-us/articles/51824773718932-Creating-with-Build ; https://www.sec.gov/Archives/edgar/data/1315098/000162828026068235/ex991-q32026earningsshar.htm

### B. Studio Lite inside Roblox (third-party experience, Android-friendly)

- Open https://www.roblox.com/games/10959918411/Studio-Lite with the **official Roblox app**.
- This is a **user-created Roblox game**, not the official Roblox Studio. It can create and publish a basic Roblox experience from the phone. Follow its current in-experience publishing instructions; it may require a Roblox Open Cloud API key.
- After a real game/Place ID exists, **do not try to paste the entire repo into Studio Lite manually**. Instead use our own GitHub Open Cloud upload workflow below.
- Source: the actual Roblox game's description and developer's guide: https://devforum.roblox.com/t/studio-lite-tips-and-faq/3191419/

### C. Cloud Windows desktop with Roblox Studio (full compatibility)

- Use a real Windows desktop, ideally with GPU, under your control. The official Studio supports Windows and macOS, **not Android**.
- Roblox login and age/2FA confirmations must be completed by the account owner. Do not share credentials.
- In Studio open the `.rbxlx` from our GitHub artifact; publish as **private** first, creating an actual place and obtaining its Place ID.
- Remote desktops such as airgpu or Shadow advertise a complete Windows environment accessible from Android. **Roblox Studio compatibility, virtual-machine restrictions, region availability and cost must be verified before paying**.
- Studio: https://create.roblox.com/docs/studio/setup ; Roblox VM restrictions: https://en.help.roblox.com/hc/en-us/articles/24275616578708-Anti-cheat-Messages

### D. One-time access to an allowed ordinary PC

- A borrowed Windows/Mac computer is enough for a first Place creation and a genuine Studio F5 playtest; subsequent GitHub uploads don't require Studio.
- Official first publish: https://create.roblox.com/docs/production/publishing/publish-games-and-places

## Upload our actual existing 3D game (GitHub, Android browser)

After the game has an **existing Place ID**:

1. Roblox [Creator Dashboard](https://create.roblox.com/dashboard/creations) → **Open Cloud → API Keys** → create a dedicated key restricted to this target game:
   - For **backend `assets`** (recommended): grant **Assets API → Read + Write**.
   - For **backend `universes`** (alternate): grant **universe-places → Write**.
   - Limit expiry and permissions; never paste the key in a chat/README/issue.
2. GitHub repo → [Settings → Actions secrets](https://github.com/Milanaa123/dont-wake-the-monster/settings/secrets/actions) → **New repository secret**:
   - Name: `ROBLOX_API_KEY`
   - Value: your **private** Roblox Open Cloud key.
   The assistant cannot read or reconstruct this secret.
3. GitHub [Actions variables](https://github.com/Milanaa123/dont-wake-the-monster/settings/variables/actions), optional:
   - `ROBLOX_PLACE_ID`: numeric ID from Creator Dashboard;
   - `ROBLOX_UNIVERSE_ID`: necessary only for the alternate Universe backend.
   **Neither ID is a password.** You can instead enter them directly in the manual run dialog.
4. Open [Upload Roblox place (manual)](https://github.com/Milanaa123/dont-wake-the-monster/actions/workflows/upload-roblox.yml) → **Run workflow** with:
   - Branch: `main`
   - `backend`: `assets` (normal) or `universes` (alternate)
   - `upload_mode`: **Saved** to upload a non-playing, unpublished test revision first.
   - `place_id`: number, or leave empty if stored as GitHub variable;
   - `universe_id`: only for Universes backend, or leave empty if stored as variable.
5. If GitHub reports **SUCCESS**, check Creator Dashboard → your game's **Places → Version History**. A green GitHub build alone is **not** proof Roblox accepted a publish — the *Upload Roblox place* workflow must succeed and the version must appear on Roblox.
6. To **play our game privately through the Roblox app**, after verifying the right target and uploaded file, rerun the manual workflow using `upload_mode = Published`. This publishes a *place version*, but **does not make the entire experience Public**.
7. Open Roblox app while logged in as the creator to play the private experience. Record **actual game footage** on the phone using Android screen recording if it plays successfully. If the game crashes or buttons fail, report the error and revert using Roblox Version History.

**Security:**
- This workflow does not auto-run after pushes. The `Published` choice is always an explicit action.
- GitHub Actions logs don't expose the key; avoid printing it yourself.
- Uploads are allowed only on `main`; the script checks numeric IDs and denies missing credentials.
- There is no uncontrolled fallback between API endpoints; choose an alternate backend yourself only after examining errors. Uploading the same version twice can create an extra revision.

## Making the game publicly discoverable

Publishing the **place version** is not the same as releasing the **experience**. To become publicly discoverable, use Creator Dashboard → **Audience → Reach / Manage Audience** as permitted for the account. Publishing requirements as of **November 2026**:

- For an audience aged **16+ and trusted friends**: Roblox account **at least 2 days old**, good standing, Roblox facial age check or ID verification, and the required content question/rating.
- To reach **all ages including kids/Select**: additional verification and 2FA, content review/evaluation and either 2 consecutive months of Roblox Plus/Premium **or** a one-time refundable **1,000 Robux** fee (50,000 Robux expedited option is unnecessary).
- A brand-new account created on **19 November 2026** cannot meet the 2-day minimum until **21 November 2026**, assuming its exact creation time and all other requirements are satisfied.
- The user's actual Roblox account age/verification/access status **has not been read or verified**.
- Official requirements: https://create.roblox.com/docs/production/publishing/publish-games-and-places ; https://en.help.roblox.com/hc/en-us/articles/203313890-How-to-Publish-Games-on-Roblox

**Do not spend Robux or release publicly until the place has been tested and the account owner approves.** No in-game premium seed purchases are enabled.

## What the assistant can and cannot do independently

**Already done:** all source code in GitHub; the GitHub build; 2 alternate official Roblox Open Cloud upload backends and a manual upload workflow that works without local Roblox Studio once configured.

**Not done:** no credential-authorized Roblox Place ID exists in this repository, no Roblox API key has been linked through the owner's private GitHub Secret, no authenticated Play session, no live recording, no Roblox public release.

The assistant has GitHub access but **no Roblox OAuth connection or interactive authenticated Roblox browser** in this chat. It cannot use a user's verbal consent to create an account session, bypass 2FA, create an API key or see the owner's private dashboard. If the owner supplies a **non-secret Place ID** and stores the API key directly in GitHub Secrets, the existing workflow is prepared for uploading without exposing credentials.

## Checkpoints

- ✅ Latest **Build Roblox place** GitHub workflow finishes successfully.
- ⬜ The Roblox account has a real test **Place ID**.
- ⬜ The owner has securely stored `ROBLOX_API_KEY` in GitHub Actions.
- ⬜ **Upload Roblox place** returns a real Roblox revision ID.
- ⬜ The version has been **Published**, still with the experience set to private.
- ⬜ The real game successfully opens in the Roblox mobile app.
- ⬜ Only afterward: confirm content rating, publication eligibility, audience and release.
