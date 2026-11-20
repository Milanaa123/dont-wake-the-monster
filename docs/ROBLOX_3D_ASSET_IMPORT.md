# Don’t Wake the Monster! — 3D asset replacement (20 November 2026)

This is an actual 3D-model pipeline, not an AI illustration or gameplay recording.
The source generator is scripts/generate_reference_glb.py.
Each build produces 4 importable GLB packs:
- DWTM_Pets_30.glb — 30 individually named animal meshes.
- DWTM_Crops_30x3.glb — 30 crop species at three growth stages (90 meshes).
- DWTM_World_8.glb — orchard tree, wood fence, cottage, stone path,
  pond, sleeping monster, toucan and flowering hedge (8 meshes).
- DWTM_Gardener_Avatar_15.glb — original 15-part moving-body chibi gardener with flower clips and blue overalls.
- manifest.json — hashes, mesh counts, triangle counts.

All art is original procedural 3D geometry with a UV color-atlas texture;
it does not retexture the supplied reference image.

## Install in Roblox Studio — four GLB imports, no API key

1. Download the "dwtm-original-3d-art" ZIP artifact from the GitHub
   "Build original 3D art library" workflow and extract it.
2. Open the newest game .rbxlx in an authenticated Roblox Studio session.
3. In Studio select File > Import. Select all four GLB files.
   Keep "Import Only As Model" enabled. Leave resulting imported models in Workspace.
   Their names must begin with DWTM_Pets_30, DWTM_Crops_30x3, DWTM_World_8, and DWTM_Gardener_Avatar_15.
4. To make mesh resources usable by a published experience, use the experience
   owner/group under Creator and enable Upload to Roblox. Upload requires a
   signed-in creator and is subject to asset moderation.
5. Play. The server module ReferenceMeshLibrary.luau automatically stages
   recognized imported meshes into ServerStorage/DWTM_ArtLibrary/{Pets,Crops,World,Avatar},
   and World.luau clones them into real animals, cultivated plants and scenery.
   Gameplay ownership, personality and economy systems are not replaced.
6. In Explorer, verify ImportedCharacterMesh under the equipped pet,
   ImportedCropMesh under cultivated plots, and ImportedGardenCottage
   or ImportedWaterPond in the environment. Also check the player character's
   StorybookGardener folder, with 15 welded MeshParts attached to R15 animated limbs.
7. If Studio changes imported model names, manually move the named meshes
   into ServerStorage/DWTM_ArtLibrary with subfolders Pets, Crops, World, Avatar.
   Individual mesh names must match the manifest: e.g. Pet_Pip,
   Crop_Berry_S3, Environment_GardenCottage, Avatar_Head.

Roblox official importer information:
https://create.roblox.com/docs/studio/importer
https://create.roblox.com/docs/art/modeling

## Actual progress and limits

- The source generator and GLB integrity tests run in GitHub Actions.
- New mesh geometry is generated for all 30 animals, 90 crop stages, 8 environment props, and 15 character-body segments (143 source meshes).
- Pet meshes remain static visuals, NOT rigged animated animal characters. The new gardener outfit attaches to Roblox R15 limbs, so Roblox's stock walk/jump animations can drive the body pieces. Actual alignment and animation are not yet verified in Studio.
- If the art has not been imported, the game explicitly falls back to its
  original placeholder spheres/parts. A GitHub build alone cannot display
  the GLB in Roblox.
- Lighting, palette, meshes and size on real devices are not validated in
  Roblox Studio. There is no authentic gameplay screenshot/video.
- Existing paid purchase buttons are still disabled; never publish untested
  real-money purchases or enter Roblox credentials in source code.
- Final quality matching the supplied reference cannot be claimed until
  verified with actual in-engine captures and performance tests.

## Release acceptance gate

1. Import and confirm the mesh library under signed-in Roblox Studio.
2. Start an actual Play session, inspect Output, take in-engine screenshots
   of the garden, each animal family, the monster and a chase.
3. Correct visibly mismatched proportions, lighting, textures and camera;
   add a proper animation rig for animal locomotion, idle, stroking and carrying.
4. Measure GPU/frame time, memory and network/replication on mobile devices.
5. Test 2+ players, 3 crop stages, interaction, saving and survival together.
6. Add cosmetic monetization only after product IDs, receipts, duplication
   protection, save robustness and explicit owner approval.

A green GitHub build validates source and mesh-file structure, NOT rendered
reference fidelity or Roblox engine behavior.

## 2026-11-20 art integration update

- Import packs now include a 15-piece gardener avatar and 128 other meshes.
- The first garden area is composed with planted berry, wheat and melon models when all packs are imported. It leaves the main walking path free.
- Client-side ambient visual movement adds subtle plants/trees sway, pet bobbing, toucan nodding and sleeping-monster breathing. This is not skeletal pet walking.
- If the 15 Avatar_ meshes are all present and player rig is R15, the game welds the parts to Roblox's existing animated bones, then hides default R15 geometry for a unified character. If a part is missing, it retains the normal Roblox avatar.
- The 3D importer is a necessary authorized Studio step; source compilation cannot upload or convert these meshes automatically. See the official importer documentation linked above.
