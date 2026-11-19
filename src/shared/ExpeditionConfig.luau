--!strict
-- Public, free-to-play exploration rules. Only ordinary seeds can be found.
-- No Robux, paid randomness, loot boxes, or event exclusivity.
local X = {}
X.NodeCooldown = 240
X.PersonalDailyQuest = 5
X.FestivalGoal = 12
X.FestivalRewardCoins = 35
X.SeedCap = 500
X.NodesPerZone = 3
X.Zones = {
    Meadow = {
        name = "Whispering Meadow", icon = "🌼", hint = "Follow the glowing wildflowers!",
        color = Color3.fromRGB(251, 218, 130),
        nodes = {
            {id = "meadow_1", x = -88, z = 28, label = "Daisy Trail", loot = {"Berry", "Sunflower", "HoneyPear"}},
            {id = "meadow_2", x = -98, z = -18, label = "Bumblebee Bush", loot = {"Carrot", "WhisperWheat", "RainbowRadish"}},
            {id = "meadow_3", x = -78, z = -59, label = "Golden Hollow", loot = {"Tomato", "CandyCane", "CloudCotton"}},
        },
    },
    Marsh = {
        name = "Moonlit Marsh", icon = "🌙", hint = "Blue mushrooms reveal hidden caches.",
        color = Color3.fromRGB(164, 188, 249),
        nodes = {
            {id = "marsh_1", x = 82, z = -66, label = "Mushroom Footprint", loot = {"Moonshroom", "CrystalMint", "MoonLotus"}},
            {id = "marsh_2", x = 99, z = -16, label = "Foggy Stump", loot = {"FrostBerry", "NeonMushroom", "ThunderPlum"}},
            {id = "marsh_3", x = 92, z = 37, label = "Bubble Pools", loot = {"Jellybean", "BubbleCabbage", "MarshmallowRoot"}},
        },
    },
    Ruins = {
        name = "Giggle Ruins", icon = "🗿", hint = "Ancient stones hum when the giant snores.",
        color = Color3.fromRGB(235, 167, 212),
        nodes = {
            {id = "ruins_1", x = -23, z = -101, label = "Old Idol", loot = {"Pepper", "GlowPumpkin", "Dragonfruit", "LavaMelon"}},
            {id = "ruins_2", x = 23, z = -101, label = "Crystal Tablet", loot = {"Corn", "StardustRice", "JellyCactus"}},
            {id = "ruins_3", x = 7, z = 102, label = "Secret Gateway", loot = {"GummyGrape", "Peppermint", "CaramelApple"}},
        },
    },
}
X.ZoneOrder = {"Meadow", "Marsh", "Ruins"}
-- Public discovery odds per free node before pet-trait adjustments.
X.LootWeights = {common = 65, uncommon = 28, rare = 7}
X.Weather = {
    Sunny = {name = "Golden Sunshine", icon = "☀️", speed = 0.94, mutation = "Golden", chance = 0.12, color = Color3.fromRGB(255, 229, 175), noise = 0},
    Rain = {name = "Sparkling Rain", icon = "🌧️", speed = 0.82, mutation = "Dewy", chance = 0.18, color = Color3.fromRGB(163, 222, 255), noise = 0},
    MoonFog = {name = "Moonflower Mist", icon = "🌙", speed = 0.90, mutation = "Moonlit", chance = 0.22, color = Color3.fromRGB(184, 177, 255), noise = 0},
    GiggleStorm = {name = "Giggle Pollen Storm", icon = "🌪️", speed = 0.88, mutation = "Giggly", chance = 0.28, color = Color3.fromRGB(255, 181, 218), noise = 7},
}
X.WeatherOrder = {"Sunny", "Rain", "MoonFog", "GiggleStorm"}
X.MutationBonus = 2 -- Fixed, non-paid harvest multiplier.
return X
