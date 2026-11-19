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
    Starbloom   = {name = "Starbloom",     seconds = 195, coins = 0,   yield = 4, color = Color3.fromRGB(255, 229, 132), icon = "⭐", kind = "premium", productId = 0},
    AuroraMelon = {name = "Aurora Melon",  seconds = 260, coins = 0,   yield = 5, color = Color3.fromRGB(116, 232, 230), icon = "🌈", kind = "premium", productId = 0},
}
G.Order = {"Berry", "Carrot", "Corn", "Tomato", "Pepper", "Sunflower", "Moonshroom", "CrystalMint", "Dragonfruit", "Jellybean", "Starbloom", "AuroraMelon"}
G.Fertilizers = {
    Compost = {name = "Compost", modifier = 0.65, description = "Remaining growth time -35%"},
    Starlight = {name = "Starlight Fertilizer", modifier = 0.4, description = "Remaining growth time -60%"},
    AuroraDust = {name = "Aurora Dust", modifier = 0.2, description = "Remaining growth time -80%", kind = "premium", productId = 0},
}
-- The ID fields must be populated from Creator Dashboard later. No real-money
-- purchase prompts or receipts are active in this codebase.
G.PremiumProducts = {
    StarbloomSeeds = {productId = 0, item = "Starbloom", itemType = "seed", amount = 3, suggestedRobux = 49},
    AuroraMelonSeeds = {productId = 0, item = "AuroraMelon", itemType = "seed", amount = 3, suggestedRobux = 79},
    AuroraDust = {productId = 0, item = "AuroraDust", itemType = "fertilizer", amount = 5, suggestedRobux = 69},
}
-- Output is deterministic and all items are earned from gameplay.
G.Recipes = {
    BerryMash = {name = "Bubbleberry Mash", icon = "🍧", produces = 2, ingredients = {Berry = 2, Tomato = 1}, type = "feed", baseFood = "Candy", extraNoise = 6},
    SpicySoup = {name = "Screaming Soup", icon = "🥣", produces = 2, ingredients = {Pepper = 2, Carrot = 1}, type = "feed", baseFood = "Pepper", extraNoise = 12},
    MoonCandy = {name = "Moon Candy", icon = "🌙", produces = 2, ingredients = {Moonshroom = 1, CrystalMint = 2}, type = "feed", baseFood = "Star", extraNoise = 11},
    BubbleTea = {name = "Bouncy Bubble Tea", icon = "🧋", produces = 2, ingredients = {Jellybean = 1, Berry = 2}, type = "feed", baseFood = "Bubble", extraNoise = 8},
    SillyLure = {name = "Silly Creature Bait", icon = "🪤", produces = 1, ingredients = {Corn = 2, Sunflower = 1}, type = "lure"},
    MonsterLure = {name = "Monster Snack Lure", icon = "🍔", produces = 1, ingredients = {Dragonfruit = 1, Moonshroom = 2}, type = "lure"},
    Compost = {name = "Compost", icon = "🌱", produces = 2, ingredients = {Carrot = 1, Tomato = 1}, type = "fertilizer"},
    Starlight = {name = "Starlight Fertilizer", icon = "✨", produces = 1, ingredients = {CrystalMint = 2, Sunflower = 2}, type = "fertilizer"},
}
G.RecipeOrder = {"BerryMash", "SpicySoup", "MoonCandy", "BubbleTea", "SillyLure", "MonsterLure", "Compost", "Starlight"}
return G
