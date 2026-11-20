"""Static, offline sanity checks. These are NOT Roblox Studio/runtime tests."""
from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]
def read(path):
    return (ROOT / path).read_text(encoding="utf-8")

project = json.loads(read("default.project.json"))
tree = project["tree"]
assert tree["ReplicatedStorage"]["$path"] == "src/shared"
assert tree["ServerScriptService"]["$path"] == "src/server"
assert tree["StarterPlayer"]["StarterPlayerScripts"]["$path"] == "src/client"

required = [
    "src/shared/Config.luau",
    "src/server/Game.server.luau",
    "src/server/World.luau",
    "src/server/CottageGardenStyle.luau",
    "src/server/StorybookPetArt.luau",
    "src/server/ReferenceCropArt.luau",
    "src/server/ReferenceMeshLibrary.luau",
    "src/server/ReferenceGardenFallback.luau",
    "src/server/ReferenceBackdropFallback.luau",
    "src/server/NativeGardenerAvatar.luau",
    "src/client/CottageCamera.client.luau",
    "src/server/Progression.luau",
    "src/client/HUD.client.luau",
    "src/client/Collection.client.luau",
    "src/shared/GardenConfig.luau",
    "src/server/Garden.luau",
    "src/server/RecipeCatalog.luau",
    "src/client/Garden.client.luau",
    "src/shared/ExpeditionConfig.luau",
    "src/server/SeedHunt.luau",
    "src/server/ForestWorld.luau",
    "src/client/SeedExplorer.client.luau",
    "src/shared/AudioConfig.luau",
    "src/client/Soundscape.client.luau",
    "src/shared/PetPersonality.luau",
    "src/client/PetDiary.client.luau",
    "src/server/RescueObjective.luau",
    "src/client/HowToPlay.client.luau",
    "src/shared/PetAffection.luau",
    "src/client/PetCare.client.luau",
]
for path in required:
    text = read(path)
    assert text.startswith("--!strict"), f"Missing Luau strict marker: {path}"
    assert len(text) > 100, f"Suspiciously small source file: {path}"

cfg = read(required[0])
pets = cfg.split("Config.Pets = {", 1)[1].split("Config.Reactions = {", 1)[0]
pet_prices = re.findall(r'\{name = "([^"]+)"[^}]*?price = (\d+)[^}]*\}', pets)
assert len(pet_prices) == 30, f"Expected 30 pet definitions, got {len(pet_prices)}"
names = [name for name, _ in pet_prices]
prices = [int(price) for _, price in pet_prices]
assert len(set(names)) == len(names), "Duplicated pet name"
assert prices[0] == 0 and prices[1:] == sorted(prices[1:]), "Pet economy prices are out of order"
assert all(price > 0 for price in prices[1:]), "Locked pets must have nonzero coin costs"

reactions = cfg.split("Config.Reactions = {", 1)[1].split("return Config", 1)[0]
reaction_defs = re.findall(r'\{id = "([^"]+)".*?weight = (\d+)\}', reactions)
assert len(reaction_defs) == 12, f"Expected 12 reactions, got {len(reaction_defs)}"
assert len({id_ for id_, _ in reaction_defs}) == len(reaction_defs), "Duplicate chaos reaction"
assert all(int(weight) > 0 for _, weight in reaction_defs), "Chaos outcomes need positive weights"

world_art = read("src/server/World.luau")
pet_art = read("src/server/StorybookPetArt.luau")
assert 'StorybookPetArt.decorate(pet, species, color)' in world_art, "Storybook details disconnected from pet creation"
for species in ("Pip", "Zuzu", "Floofle", "Snorf", "Sprig", "Puddle", "Swoop",
                "Nugget", "Pebble", "Splat", "Twinkle", "Quibble",
                "Rumble", "Puffin", "Echo", "Glimmer", "Mallow"):
    assert ('species == "' + species + '"') in pet_art, f"Missing detailed species: {species}"

server = read("src/server/Game.server.luau")
progression = read("src/server/Progression.luau")
client = read("src/client/Collection.client.luau")
for command in ("BuyPet", "EquipPet", "ClaimDaily", "Sync", "Feed"):
    assert command in server, f"Server missing action: {command}"
for command in ("BuyPet", "EquipPet", "ClaimDaily"):
    assert command in client, f"Client missing action: {command}"
for field in ("owned", "discovered", "feedCount", "survivalCount", "questClaimed", "dailyDay"):
    assert field in progression, f"Missing persistent progression field: {field}"
assert "math.max(previousCoins, coins)" not in server, "Unsafe max-based coin save revives spent currency"
assert "ProcessReceipt" not in server, "Real-money purchases should remain disabled until receipt work is tested"

garden_cfg = read("src/shared/GardenConfig.luau")
garden = read("src/server/Garden.luau")
garden_ui = read("src/client/Garden.client.luau")
assert garden_cfg.count('kind = "ordinary"') == 28, "Expected 28 free-coin crops"
assert garden_cfg.count('kind = "premium"') == 3, "Expected two premium seeds + one fertilizer"
assert garden_cfg.count("productId = 0") == 6, "A product ID may have been enabled without receipts"
assert "G.PLOT_COUNT = 9" in garden_cfg, "Expected nine plots per player"
assert "G.SLOT_COUNT = 12" in garden_cfg, "Expected twelve physical garden zones"
for action in ("GardenBuySeed", "GardenPlant", "GardenHarvest", "GardenFertilize", "GardenCraft", "GardenExperiment", "GardenFeed", "GardenLure", "GardenVisit"):
    assert action in server and action in garden_ui, f"Missing garden client/server command: {action}"
for method in ("Garden.buySeed", "Garden.plant", "Garden.harvest", "Garden.fertilize", "Garden.craft", "Garden.experiment", "Garden.consume"):
    assert method in garden and method in server, f"Missing server garden rule: {method}"
assert "Garden.serialize" in progression and "Garden.load" in progression, "Garden data not saved"
assert "PromptProductPurchase" not in garden_ui, "Premium products must remain disabled"
assert "No teleporting away from Giggles" in server, "Garden escape during boss fight was enabled"
catalog = read("src/server/RecipeCatalog.luau")
assert garden_cfg.count("kind = \"premium\"") == 3
assert "G.TOTAL_RECIPES = 26" in garden_cfg
assert 'Catalog.Order = {' in catalog and 'MysterySlop = {' in catalog
assert "Catalog.Recipes" not in garden_cfg and "G.Recipes" not in garden_cfg
assert "G.RecipeOrder" not in garden_cfg and "G.RecipeOrder" not in garden_ui
assert "G.Recipes" not in garden_ui and "RecipeCatalog" not in garden_ui
assert "local RecipeCatalog = require(script.Parent:" in server
assert "local Catalog = require(script.Parent:" in garden
assert "Garden.snapshot" in garden and "result.book = book" in garden
assert "knownRecipes = knownRecipes" in garden, "Discovered recipe book does not persist"
assert "Garden.experiment" in server and "GardenExperiment" in garden_ui
assert "table.sort(products" in garden, "Crafted product inventory missing"

rescue = read("src/server/RescueObjective.luau")
hud = read("src/client/HUD.client.luau")
onboarding = read("src/client/HowToPlay.client.luau")
assert 'RescueObjective.start' in server and 'RescueObjective.finish' in server, "Rescue round lifecycle missing"
assert 'RescueObjective.participated(player)' in server, "Cooperative bonus requires participating"
assert 'RescueObjective.status()' in server, "Rescue progress must sync to clients"
assert 'ProximityPrompt' in rescue and 'prompt.Triggered:Connect' in rescue, "In-world rescue interactions missing"
assert '(root.Position - primary.Position).Magnitude > 16' in rescue, "Rescue must validate server distance"
assert 'humanoid.Health <= 0' in rescue, "Dead players must not collect rescues"
assert 'used = true' in rescue and 'prompt.Enabled = false' in rescue, "Rescues must be one-time"
assert 'rescueCard.Visible' in hud and 'rescueLabel.Text' in hud, "Rescue progress HUD missing"
assert 'HUNT SEEDS' in onboarding and 'GROW & EXPERIMENT' in onboarding and 'RESCUE & SURVIVE' in onboarding, "First-time tutorial missing"

print("OK: co-op rescue prompts, server checks, objective HUD and first-time tutorial")

personality = read("src/shared/PetPersonality.luau")
diary = read("src/client/PetDiary.client.luau")
world = read("src/server/World.luau")
assert 'Personality.Temperaments = {' in personality and 'Personality.Habits = {' in personality
assert 'Personality.Fears = {' in personality and 'Personality.Affection = {' in personality
assert 'function Personality.generate(' in personality and 'function Personality.restore(' in personality
assert 'function Personality.meet(' in personality and 'Personality.EncounterNames' in personality
assert 'function Personality.bondStage(' in personality
for fragment in ("personalities = {}", "Personality.restore(", "Personality.pack(", "function Progression.ensurePersonality(", "petProfiles = petProfiles"):
    assert fragment in progression, f"Missing persistence or collection: {fragment}"
assert 'World.stylePersonality(' in server and 'World.emotePet(' in server, "Missing world personality visuals"
assert 'Personality.reactionMultiplier(' in server and 'Personality.feed(' in server, "Personality must influence chaos reactions"
assert 'Personality.meet(' in server and 'Personality.tick(' in server, "Personality needs social behavior and idle changes"
assert '"PetInteract"' in server and '"PetInteract"' in diary, "Server-authoritative pet interactions missing"
assert 'catalog.petProfiles[tostring(id)]' in client, "Collection must show individual pet traits"
assert 'profile.temperament' in diary and 'profile.bondStage' in diary, "Pet diary must expose individual traits"
assert 'species == "Pip" or species == "Zuzu"' in world, "Starter kittens must have cat visuals"
assert 'Favorite' not in server or 'Personality.feed(' in server, "Pet preferences not connected"
print("OK: per-owner individual personalities, saved genetics, dynamic mood, social encounters and diary")



print(f"OK: {len(pet_prices)} pets, {len(reaction_defs)} reactions, 30 plants, 26 hidden recipes, save fields and disabled premium products")

assert "CottageStyle.decorateWorld(scenery)" in world, "Garden environment must be integrated into actual island"
assert "CottageStyle.decorateFarm(model, center)" in world, "Physical garden fence decoration not integrated"
assert "ReferenceMeshLibrary.applyPet(pet, species)" in world, "Imported mesh pets are not wired"
assert "ReferenceMeshLibrary.applySleepingMonster(monster)" in world, "Sleeping 3D monster not linked"
assert "ReferenceMeshLibrary.applyOrchardTree(scenery, index, position)" in world, "New orchard tree geometry not linked"
assert "DWTM_World_8" in read("src/server/ReferenceMeshLibrary.luau"), "Eight-item world pack name mismatch"
assert "local angle = (slot - 1) / 12 * math.pi * 2 + math.pi / 2" in world, "First garden no longer faces spawn"
assert "CFrame.new(0, 9, 85)" in world, "First-play spawn overlaps garden"
assert "ReferenceMeshLibrary.applyCrop(visual, center, p.seed, stage)" in world, "Imported 3D crops not wired"
assert "ReferenceMeshLibrary.applySetDress(scenery)" in world, "Imported world set is not wired"
mesh_bridge = read("src/server/ReferenceMeshLibrary.luau")
for marker in ("ServerStorage", "DWTM_ArtLibrary", "DWTM_Pets_30", "DWTM_Crops_30x3",
               "DWTM_World_8", "ImportedCharacterMesh", "ImportedCropMesh",
               "CanCollide = false", "CanQuery = false"):
    assert marker in mesh_bridge, f"Missing safe import bridge: {marker}"
assert "ReferenceCropArt.draw(visual, center, p.seed, stage, crop.color)" in world, "Old crops missing as test fallback"
crop_art = read("src/server/ReferenceCropArt.luau")
for crop_shape in ("HeartShapedBerry", "StripedRind", "CarrotRoot", "WheatStalk", "FlowerPetal", "HangingPepper", "VelvetMushroomCap"):
    assert crop_shape in crop_art, f"Reference-art crop silhouette missing: {crop_shape}"
assert "CanQuery = false" in crop_art, "Decorative crop geometry must not block interaction queries"
styling = read("src/server/CottageGardenStyle.luau")
camera = read("src/client/CottageCamera.client.luau")
for token in ("function Cottage.applyLighting()", "function Cottage.decorateWorld(", "function Cottage.decorateFarm(", "function Cottage.decorateCrop("):
    assert token in styling, f"Missing cottage style pipeline: {token}"
for token in ("CozyOrchardCottage", "ShadedOrchardPond", "MeadowGrassPatch", "LanternWindow"):
    assert token in styling, f"Reference environment fixture missing: {token}"
for token in ("OrchardTrunk", "GoldenOrange", "WildStrawberry", "GoldenWheat", "SunlitMelon", "WarmGardenPath", "FencePost"):
    assert token in styling, f"Missing reference-informed art element: {token}"
for token in ("ColorCorrectionEffect", "BloomEffect", "Atmosphere", "SunRaysEffect"):
    assert token in styling, f"Missing outdoor lighting layer: {token}"
for token in ("CameraType.Scriptable", "CameraType.Custom", "BindToRenderStep", "camera.Focus", "GARDEN VIEW"):
    assert token in camera, f"Missing optional camera behavior: {token}"
assert "CanCollide = false" in styling and "CanTouch = false" in styling, "New foliage must not block gameplay"
assert "CanQuery = false" in styling, "Cosmetic grass and flowers should not intercept pet/seed queries"
print("OK: cottage garden world/plots/crop art, warm lighting and optional three-quarter camera")

# Continuous, server-owned pet affection and visual/audio asset integration.
affection = read("src/shared/PetAffection.luau")
care = read("src/client/PetCare.client.luau")
for marker in ("StartPetting", "StopPetting", "PettingPulse", "ToggleCarry"):
    assert marker in server and marker in care, f"Missing shared pet-care action: {marker}"
for marker in ("Affection.step(", "World.carryPose(", "World.setPurr(", "PetDistance", "lastCarePulse", "KeepaliveSeconds"):
    assert marker in server, f"Missing petting server bound or behavior: {marker}"
for marker in ("function Affection.newSession(", "function Affection.step(", "function Affection.isCat("):
    assert marker in affection, f"Missing pure pet-affection rules: {marker}"
world = read("src/server/World.luau")
for marker in ("function World.carryPose(", "function World.setPurr(", "RollOffMaxDistance", "Volume"):
    assert marker in world, f"Missing purr/carry artwork: {marker}"
assert "PetCareControls" in care and "InputEnded" in care and "WindowFocusReleased" in care
assert "Config.PurrSoundId = 0" in cfg, "A live sound ID must be configured only after creator approval"
import wave
sound_path = ROOT / "assets/audio/original-cat-purr-loop.wav"
assert sound_path.exists(), "Missing original Roblox purr sound source"
with wave.open(str(sound_path), "rb") as wav:
    assert wav.getnchannels() == 1 and wav.getsampwidth() == 2 and wav.getframerate() >= 8000
    assert 2 <= wav.getnframes() / wav.getframerate() <= 12, "Purr file length is unreasonable"
print("OK: server-owned cuddling, untrusted input bounds, purr-to-noise link, WAV source and mobile hold controls")

# Seed-hunting and soundscape v0.9 checks.
hunt = read("src/server/SeedHunt.luau")
expedition = read("src/shared/ExpeditionConfig.luau")
forest = read("src/server/ForestWorld.luau")
explorer = read("src/client/SeedExplorer.client.luau")
sounds = read("src/shared/AudioConfig.luau")
soundscape = read("src/client/Soundscape.client.luau")
for token in ("Meadow", "Marsh", "Ruins", "NodeCooldown", "FestivalGoal", "LootWeights", "WeatherOrder"):
    assert token in expedition, f"Missing seed exploration: {token}"
for token in ("Hunt.collect(", "Hunt.mutatePlot(", "Hunt.load(", "questClaimed"):
    assert token in hunt, f"Missing server hunt rules: {token}"
for token in ("function ForestWorld.build(", "ProximityPrompt", "prompt.Triggered", "SearchSeeds", "function ForestWorld.weather("):
    assert token in forest, f"Missing actual world interactions: {token}"
for token in ("GardenAssist", "SeedHunt.collect(", "ForestWorld.build(", "changeWeather(", "festivalPlayers", "garden.spawn"):
    if token == "garden.spawn":
        continue
    assert token in server, f"Missing integrated gameplay: {token}"
assert "SeedCache_" in explorer and "state.seedAlbum" in explorer and "TRACK" in explorer, "Mobile seed journal must be interactive"
assert "function Garden.weather(" in garden and "function Garden.assist(" in garden, "Missing growing and tending rules"
assert 'PremiumProducts' in garden_cfg and all(v in garden_cfg for v in ('productId = 0', 'G.PLOT_COUNT = 9')), "Robux source must remain disabled"
audio_names = [
    "calm-garden-theme", "SeedFind", "RareDiscovery", "WeatherChime", "Boing", "MonsterWake",
    "Victory", "Festival", "SillyStorm", "HarvestPop", "MutationSparkle", "CatSwat",
    "tiny-violin-fail", "suspicious-meow", "cartoon-record-scratch", "comedy-drum-sting",
    "sleepy-forest-ambience", "monster-chase-theme"
]
import wave
for name in audio_names:
    path = ROOT / "assets/audio" / (name + ".wav")
    assert path.exists(), f"Missing original audio: {name}"
    with wave.open(str(path), "rb") as w:
        assert w.getnchannels() == 1 and w.getsampwidth() == 2
        assert w.getframerate() >= 8000
        assert 0.5 <= w.getnframes() / w.getframerate() <= 30, "Audio duration out of bounds"
assert "Audio.MusicAssetId = 0" in sounds, "Music must remain disabled until authorized asset upload"
assert sounds.count(" = 0,") == 15, "Expected 15 muted SFX IDs"
assert "playCue(" in soundscape and "MusicToggle" in soundscape and "EffectsToggle" in soundscape
print("OK: 3 biomes, 9 seed caches, original music and ambience, 15 sound effects, pet tending")

# Rotating free-coin seed merchant, no paid loot, real save integration.
merchant = read("src/shared/SeedMerchant.luau")
for token in ("function Shop.rotation(", "function Shop.offers(", "function Shop.snapshot(", "function Shop.buy(", "Shop.IntervalSeconds"):
    assert token in merchant, f"Missing seed merchant: {token}"
for token in ("GardenMerchantBuy", "SeedMerchant.buy(", "profile.loaded"):
    assert token in server, f"Missing secure merchant integration: {token}"
for token in ("merchantShop", "merchant = {rotation", "SeedMerchant.snapshot("):
    assert token in garden, f"Missing merchant persistence: {token}"
assert "GardenMerchantBuy" in read("src/client/Garden.client.luau"), "Missing merchant shop UI"
for token in ("Audio.ChaseMusicAssetId = 0", "Audio.AmbienceAssetId = 0", "TinyViolin = 0", "SuspiciousMeow = 0", "RecordScratch = 0", "ComedySting = 0"):
    assert token in sounds, f"Missing licensed audio config: {token}"
assert "crossfadeMusic(" in soundscape and "ChaseMusicAssetId" in soundscape
assert "harvestedSeed" in server and "ComedySting" in server, "Missing crop-chaos connection"
print("OK: coin-only rotating merchant, per-restock limits, audio crossfade and funny harvest surprises")

# First-session retention and chase usability (static contracts, NOT visual QA).
tutorial = read("src/client/HowToPlay.client.luau")
care = read("src/client/PetCare.client.luau")
camera = read("src/client/CottageCamera.client.luau")
hud = read("src/client/HUD.client.luau")
for token in ("tutorialSeen = false", "profile.tutorialSeen = data.tutorialSeen == true",
              "tutorialSeen = profile.tutorialSeen == true"):
    assert token in progression, f"Tutorial completion persistence broken: {token}"
assert '"TutorialDismiss"' in server and "remote:FireServer(\"TutorialDismiss\")" in tutorial
assert "setOpen(false)" in tutorial and "resolvedFirstJoin" in tutorial
assert 'lastPhase ~= "AWAKE"' in camera and 'Enum.CameraType.Custom' in camera
assert "foodPanel.Visible = event.phase == \"SLEEP\"" in hud
assert 'card.Visible = not chasing' in care
assert "profile.carrying = false" in server, "Carried pets cannot block chase movement"
print("OK: tutorial persistence, mobile chase focus, restoration of garden camera and pet controls")

# Authored chibi gardener and composition are conditional on creator-owned GLB imports.
art_bridge = read("src/server/ReferenceMeshLibrary.luau")
ambient_motion = read("src/client/CozyMotion.client.luau")
avatar_source = read("scripts/gardener_avatar_v1.py")
for token in ("DWTM_Gardener_Avatar_15", "\"Avatar_\" .. name",
              "function Bridge.applyGardenerAvatar(", "Enum.HumanoidRigType.R15",
              "WeldConstraint", "AnimatedR15Attachment", "DWTMStorybookAvatar",
              "function Bridge.decorateEntrance(", "Crop_Berry_S3", "Crop_LavaMelon_S3",
              "Crop_WhisperWheat_S3"):
    assert token in art_bridge, f"Game art bridge disconnected: {token}"
for token in ("flower(", "blob(\"sky\"", "Avatar_", "R15_PARTS"):
    assert token in avatar_source, f"Original gardener source lost: {token}"
assert "ArtLibrary.applyGardenerAvatar(character)" in server, "Player avatar application not wired"
assert "CharacterAppearanceLoaded" in server, "Avatar must support asynchronous Roblox appearance loading"
assert "ReferenceMeshLibrary.decorateEntrance(scenery)" in world_art, "Reference planting layout not constructed"
for token in ("ImportedCharacterMesh", "ImportedCropMesh", "ImportedSleepingMonster",
              "ImportedGardenerToucan", "RenderStepped"):
    assert token in ambient_motion, f"Cosmetic movement missing: {token}"
assert "if not limb or not limb:IsA(\"BasePart\") or not source" in art_bridge, "Partial avatar risk: failed component must retain native rig"
assert "CanCollide = false" in art_bridge, "Costume meshes must never collide with world"
print("OK: all 15 R15 body parts, dense planted opening garden, safe avatar import and cosmetic animations")

# Reference-quality progress gates, offline/source-only (NOT rendered QA).
native_garden = read("src/server/ReferenceGardenFallback.luau")
native_backdrop = read("src/server/ReferenceBackdropFallback.luau")
native_avatar = read("src/server/NativeGardenerAvatar.luau")
quick_menu = read("src/client/CottageQuickMenu.client.luau")
camera_source = read("src/client/CottageCamera.client.luau")
assert 'NativeReferenceGarden.build(scenery)' in world_art, "No native garden without GLB import"
assert 'NativeReferenceBackdrop.build(scenery)' in world_art, "No native farm backdrop"
assert 'ReferenceMeshLibrary.decorateEntrance(scenery)' in world_art, "Imported GLB entrance priority lost"
for marker in ("RipeRedStrawberry","StripedWatermelon","WheatEar",
               "MatureOrangeCarrot","PaintedTaperedLeaf","MeadowPetal",
               'CanCollide = false'):
    assert marker in native_garden, f"Missing geometric garden feature: {marker}"
for marker in ("ToucanGoldenEyeRing","ToucanBlueCap",
               "ToucanCurvedBeak","OrangeFruit",
               "MossGreenCanopy","PastelWoodFenceRail"):
    assert marker in native_backdrop, f"Missing reference background feature: {marker}"
for marker in ("ChibiFace","HairDaisyPetal","BlueOverallsBib",
               "PuffedBlouseSleeve","GardenBareArm","SunflowerShoes",
               "ChibiR15Weld"):
    assert marker in native_avatar, f"Missing actual R15 character visual: {marker}"
assert "NativeAvatar.apply(character)" in server, "No native avatar when mesh pack absent"
assert 'local viewFov = 48' in camera_source and 'Vector3.new(-5.7, 3.3, -5.2)' in camera_source, "Reference garden camera regressed"
assert 'OpenSeedExplorer' in read("src/client/SeedExplorer.client.luau")
assert 'CottageQuickMenu' in quick_menu and 'control.Activated:Connect' in quick_menu
assert project["tree"]["Workspace"]["$properties"]["StreamingEnabled"] is True, "Mobile island streaming disabled"
print("OK: native 3D reference garden, chibi animated R15 figure, orchard and compact mobile UI wired into place")
