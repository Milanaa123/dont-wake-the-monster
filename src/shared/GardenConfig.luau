--!strict
-- ALL premium product IDs are disabled (0) until a Roblox place and receipts exist.
-- "Premium" crops have deterministic yields, not paid random loot.
local G = {}
G.PLOT_COUNT = 6
G.SLOT_COUNT = 12
G.SEED_PACK_SIZE = 3
G.MAX_STACK = 500
G.DEFAULT_SEEDS = {Berry = 5, Carrot = 3, Corn = 2, Tomato = 2}
G.Crops = {
    Berry       = {name = "Bubbleberry",    seconds = 45,  coins = 9,   yield = 3, color = Color3.fromRGB(255, 118, 182), icon = "🍓", kind = "ordinary"},
    Carrot      = {name = "Rocket Carrot",  seconds = 65,  coins = 15,  yield = 3, color = Color3.fromRGB(255, 171, 82),  icon = "🥕", kind = "ordinary"},
    Corn        = {name = "Popcorn Corn",   seconds = 90,  coins = 25,  yield = 4, color = Color3.fromRGB(255, 226, 98),  icon = "🌽", kind = "ordinary"},
    Tomato      = {name = "Blush Tomato",  seconds = 75,  coins = 20,  yield = 3, color = Color3.fromRGB(255, 103, 126), icon = "🍅", kind = "ordinary"},
    Pepper      = {name = "Screamer Pepper",seconds = 125, coins = 38,  yield = 3, color = Color3.fromRGB(237, 75, 90),   icon = "🌶️", kind = "ordinary"},
    Sunflower   = {name = "Sunshine Bloom",seconds = 115, coins = 42,  yield = 3, color = Color3.fromRGB(255, 209, 61),  icon = "🌻", kind = "ordinary"},
    Moonshroom  = {name = "Moonshroom",    seconds = 180, coins = 65,  yield = 3, color = Color3.fromRGB(176, 151, 251), icon = "🍄", kind = "ordinary"},
    CrystalMint = {name = "Crystal Mint",  seconds = 155, coins = 55,  yield = 3, color = Color3.fromRGB(98, 233, 202),  icon = "🌿", kind = "ordinary"},
    Dragonfruit = {name = "Gigglefruit",   seconds = 245, coins = 110, yield = 4, color = Color3.fromRGB(255, 72, 178),  icon = "🐲", kind = "ordinary"},
    Jellybean   = {name = "Jellybean Vine",seconds = 225, coins = 95,  yield = 4, color = Color3.fromRGB(107, 151, 255), icon = "🫘", kind = "ordinary"},
    GlowPumpkin = {name = "Glow Pumpkin", seconds = 280, coins = 135, yield = 4, color = Color3.fromRGB(255, 167, 85), icon = "🎃", kind = "ordinary"},
    HoneyPear = {name = "Honey Pear", seconds = 240, coins = 120, yield = 4, color = Color3.fromRGB(255, 219, 129), icon = "🍐", kind = "ordinary"},
    CandyCane = {name = "Candy Cane Tree", seconds = 290, coins = 155, yield = 4, color = Color3.fromRGB(255, 121, 148), icon = "🍭", kind = "ordinary"},
    CloudCotton = {name = "Cloud Cotton", seconds = 320, coins = 185, yield = 5, color = Color3.fromRGB(244, 244, 255), icon = "☁️", kind = "ordinary"},
    FrostBerry = {name = "Frostberry", seconds = 350, coins = 215, yield = 4, color = Color3.fromRGB(126, 211, 255), icon = "🫐", kind = "ordinary"},
    RainbowRadish = {name = "Rainbow Radish", seconds = 365, coins = 240, yield = 4, color = Color3.fromRGB(230, 122, 242), icon = "🌈", kind = "ordinary"},
    BubbleCabbage = {name = "Bubble Cabbage", seconds = 310, coins = 195, yield = 5, color = Color3.fromRGB(136, 238, 177), icon = "🥬", kind = "ordinary"},
    LavaMelon = {name = "Lava Melon", seconds = 430, coins = 310, yield = 4, color = Color3.fromRGB(255, 109, 83), icon = "🍉", kind = "ordinary"},
    WhisperWheat = {name = "Whisper Wheat", seconds = 270, coins = 145, yield = 5, color = Color3.fromRGB(250, 221, 125), icon = "🌾", kind = "ordinary"},
    GummyGrape = {name = "Gummy Grape", seconds = 325, coins = 200, yield = 5, color = Color3.fromRGB(177, 116, 245), icon = "🍇", kind = "ordinary"},
    JellyCactus = {name = "Jelly Cactus", seconds = 390, coins = 275, yield = 4, color = Color3.fromRGB(118, 235, 174), icon = "🌵", kind = "ordinary"},
    NeonMushroom = {name = "Neon Mushroom", seconds = 440, coins = 325, yield = 4, color = Color3.fromRGB(128, 167, 252), icon = "🍄", kind = "ordinary"},
    StardustRice = {name = "Stardust Rice", seconds = 420, coins = 295, yield = 5, color = Color3.fromRGB(255, 234, 176), icon = "🌟", kind = "ordinary"},
    Peppermint = {name = "Peppermint", seconds = 345, coins = 220, yield = 4, color = Color3.fromRGB(167, 245, 204), icon = "🌿", kind = "ordinary"},
    CaramelApple = {name = "Caramel Apple", seconds = 465, coins = 345, yield = 4, color = Color3.fromRGB(242, 156, 95), icon = "🍎", kind = "ordinary"},
    MoonLotus = {name = "Moon Lotus", seconds = 510, coins = 390, yield = 4, color = Color3.fromRGB(180, 165, 251), icon = "🪷", kind = "ordinary"},
    ThunderPlum = {name = "Thunder Plum", seconds = 555, coins = 440, yield = 5, color = Color3.fromRGB(142, 121, 223), icon = "⚡", kind = "ordinary"},
    MarshmallowRoot = {name = "Marshmallow Root", seconds = 590, coins = 485, yield = 5, color = Color3.fromRGB(255, 206, 228), icon = "🍡", kind = "ordinary"},
    Starbloom   = {name = "Starbloom",     seconds = 195, coins = 0,   yield = 4, color = Color3.fromRGB(255, 229, 132), icon = "⭐", kind = "premium", productId = 0},
    AuroraMelon = {name = "Aurora Melon",  seconds = 260, coins = 0,   yield = 5, color = Color3.fromRGB(116, 232, 230), icon = "🌈", kind = "premium", productId = 0},
}
G.Order = {"Berry", "Carrot", "Corn", "Tomato", "Pepper", "Sunflower", "Moonshroom", "CrystalMint", "Dragonfruit", "Jellybean", "GlowPumpkin", "HoneyPear", "CandyCane", "CloudCotton", "FrostBerry", "RainbowRadish", "BubbleCabbage", "LavaMelon", "WhisperWheat", "GummyGrape", "JellyCactus", "NeonMushroom", "StardustRice", "Peppermint", "CaramelApple", "MoonLotus", "ThunderPlum", "MarshmallowRoot", "Starbloom", "AuroraMelon"}
G.Fertilizers = {
    Compost = {name = "Compost", modifier = 0.65, description = "Remaining growth time -35%"},
    Starlight = {name = "Starlight Fertilizer", modifier = 0.4, description = "Remaining growth time -60%"},
    HoneyCompost = {name = "Honey Compost", modifier = 0.5, description = "Remaining growth time -50%"},
    FrostFertilizer = {name = "Frost Fertilizer", modifier = 0.3, description = "Remaining growth time -70%"},
    AuroraDust = {name = "Aurora Dust", modifier = 0.2, description = "Remaining growth time -80%", kind = "premium", productId = 0},
}
-- The ID fields must be populated from Creator Dashboard later. No real-money
-- purchase prompts or receipts are active in this codebase.
G.PremiumProducts = {
    StarbloomSeeds = {productId = 0, item = "Starbloom", itemType = "seed", amount = 3, suggestedRobux = 49},
    AuroraMelonSeeds = {productId = 0, item = "AuroraMelon", itemType = "seed", amount = 3, suggestedRobux = 79},
    AuroraDust = {productId = 0, item = "AuroraDust", itemType = "fertilizer", amount = 5, suggestedRobux = 69},
}
-- Secret ingredients and recipes are kept in ServerScriptService/RecipeCatalog.luau.
-- Only discovered recipe entries are sent to individual players.
G.TOTAL_RECIPES = 26
return G
