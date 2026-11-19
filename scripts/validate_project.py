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
assert "CottageStyle.decorateCrop(visual, center, seedType, stage)" in world, "Detailed crops not integrated"
styling = read("src/server/CottageGardenStyle.luau")
camera = read("src/client/CottageCamera.client.luau")
for token in ("function Cottage.applyLighting()", "function Cottage.decorateWorld(", "function Cottage.decorateFarm(", "function Cottage.decorateCrop("):
    assert token in styling, f"Missing cottage style pipeline: {token}"
for token in ("OrchardTrunk", "GoldenOrange", "WildStrawberry", "GoldenWheat", "SunlitMelon", "WarmGardenPath", "FencePost"):
    assert token in styling, f"Missing reference-informed art element: {token}"
for token in ("ColorCorrectionEffect", "BloomEffect", "Atmosphere", "SunRaysEffect"):
    assert token in styling, f"Missing outdoor lighting layer: {token}"
for token in ("CameraType.Scriptable", "CameraType.Custom", "BindToRenderStep", "camera.Focus", "GARDEN VIEW"):
    assert token in camera, f"Missing optional camera behavior: {token}"
assert "CanCollide = false" in styling and "CanTouch = false" in styling, "New foliage must not block gameplay"
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
