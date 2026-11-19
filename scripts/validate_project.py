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
    "src/shared/PetPersonality.luau",
    "src/client/PetDiary.client.luau",
    "src/server/RescueObjective.luau",
    "src/client/HowToPlay.client.luau",
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
assert 'GROW & MIX' in onboarding and 'RESCUE & SURVIVE' in onboarding, "First-time tutorial missing"

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
