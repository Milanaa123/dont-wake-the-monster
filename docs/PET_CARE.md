# Cuddle & Purr Panic — v0.8

**Implemented in repository source on 19 November 2026.** GitHub CI compiles Luau and executes the pet-affection rule tests, but no authenticated Roblox Studio gameplay or mobile recording has been completed yet.

## How the game plays

1. Stand near your current pet. Tap **🤲 PICK UP** to cradle it against the avatar's chest. Tap **👐 PUT DOWN** to release it. A grumpy, shy or wild companion can occasionally wriggle out and refuse the cuddle.
2. **Hold 💗 HOLD TO PET** with your finger or mouse (keyboard **R**) to continuously stroke the companion. Release to stop. On desktop, press **C** to pick up or put down.
3. The cat species **Pip (pastel kitten)** and **Zuzu (fire kitten)** have the most dramatic reactions. A cat that *likes* being stroked can begin quietly purring and grow progressively louder. The pink **purr-volume gauge** shows the level. When a cat dislikes the interaction or becomes overstimulated, it may suddenly **hiss, swat, hide or get zoomies**; these reactions end the session and can drop the pet from the player's arms.
4. As a contented cat purrs more loudly, its **server-computed noise rises**, filling the global monster-wake meter. If the accumulated global noise reaches 100, **Giggles wakes up** and everyone must dodge attacks and rescue runaway pets. The purring noise is not client-authoritative.
5. Any species can be carried and petted. Non-feline creatures gain friendship/happiness from attention but don't use the special cat-purring mechanic.

The rules depend on the cat's unique saved character: temperament, preferred affection, trust, happiness, hunger and sensitivity. There are limited sessions, refusal chances and dynamic visual response; not every cat behaves identically.

## Audio — included source file, not activated yet

**Original WAV in the repository:** [original-cat-purr-loop.wav](../assets/audio/original-cat-purr-loop.wav) (4 seconds, 12 kHz, 16-bit, mono). This file was algorithmically synthesized for this project; it is not sourced from another game.

**What works today:** the petting loop, volume gauge, mood and 3D effects, shared noise meter and monster wake-up rules all exist in Luau and are tested offline.

**What is not audible yet:** the actual purring sound **inside Roblox**. `src/shared/Config.luau` deliberately sets `Config.PurrSoundId = 0`; a GitHub WAV file is not automatically a permitted Roblox asset ID.

To enable sound when an experience exists:

1. From the Roblox Creator Dashboard, upload `assets/audio/original-cat-purr-loop.wav` as a permitted audio asset. Follow current Roblox audio uploading, moderation and asset-permission rules.
2. Copy the numeric audio asset ID from its asset page. Do not share Roblox passwords or cookies.
3. Replace `Config.PurrSoundId = 0` with that number in the project's `src/shared/Config.luau`.
4. Build and test in **authenticated Roblox Studio**. Check permissions on the place, looping seamlessness, volume, 3D distance rolloff and actual audible purring. Do not enable production publishing before tests.

Roblox sound documentation:
- https://create.roblox.com/docs/sound/objects
- https://create.roblox.com/docs/audio/assets

## Implementation and safety

- `src/shared/PetAffection.luau`: pure affection and purr intensity rules, enjoyment/overstimulation, and fractional noise accumulator.
- `src/server/Game.server.luau`: validates player, real character health, pet ownership, in-world distance, cooldowns, active round and keepalive, then applies noise. The server ends abandoned strokes within 4 seconds and forcibly ends a session after 30 seconds.
- `src/server/World.luau`: 3D carried pose, floating mood/purr badges, particles and optional distance-attenuated Sound object.
- `src/client/PetCare.client.luau`: touch/mouse hold and release, C/R shortcuts, avatar shoulder posing and purr meter.
- `scripts/test_affection.py`: actually executes the Luau rules in CI: escalating purr, global noise contribution, grumpy swat, non-cat cuddles, duration limit.

### Acceptance criteria requiring Roblox Studio

- Carry pose looks believable on **R15** and **R6** avatars and shoulders return to normal.
- Touch hold/release works on Android and iOS; no runaway petting after screen focus loss or disconnection.
- Noise from one happy kitten can contribute to or cause an actual boss wake.
- Both humans and other players see the cat being held; camera and HUD remain usable.
- Server rejects spoofed remote commands, giant distances, duplicate actions and inactive phase abuse.
- Audio is **actually audible and allowed** only after an authorized asset upload.
- Mobile frame rate remains acceptable when 12 player gardens and multiple pets appear.

**No Robux transaction or premium chance mechanic was added in this feature.** The existing in-game coin purchases remain free-to-play.
