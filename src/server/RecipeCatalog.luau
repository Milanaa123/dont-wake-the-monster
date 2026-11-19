--!strict
-- IMPORTANT: ServerScriptService only. Secret recipes must not replicate to clients.
-- Players discover recipes by experimenting; the recipe book starts EMPTY.
local Catalog = {}
Catalog.Recipes = {
    BerryMash = {name = "Bubbleberry Mash", icon = "🍧", produces = 2, ingredients = {Berry = 2, Tomato = 1}, type = "feed", baseFood = "Candy", extraNoise = 6},
    SpicySoup = {name = "Screaming Soup", icon = "🥣", produces = 2, ingredients = {Pepper = 2, Carrot = 1}, type = "feed", baseFood = "Pepper", extraNoise = 12},
    MoonCandy = {name = "Moon Candy", icon = "🌙", produces = 2, ingredients = {Moonshroom = 1, CrystalMint = 2}, type = "feed", baseFood = "Star", extraNoise = 11},
    BubbleTea = {name = "Bouncy Bubble Tea", icon = "🧋", produces = 2, ingredients = {Jellybean = 1, Berry = 2}, type = "feed", baseFood = "Bubble", extraNoise = 8},
    SillyLure = {name = "Silly Creature Bait", icon = "🪤", produces = 1, ingredients = {Corn = 2, Sunflower = 1}, type = "lure"},
    MonsterLure = {name = "Monster Snack Lure", icon = "🍔", produces = 1, ingredients = {Dragonfruit = 1, Moonshroom = 2}, type = "lure"},
    Compost = {name = "Compost", icon = "🌱", produces = 2, ingredients = {Carrot = 1, Tomato = 1}, type = "fertilizer"},
    Starlight = {name = "Starlight Fertilizer", icon = "✨", produces = 1, ingredients = {CrystalMint = 2, Sunflower = 1}, type = "fertilizer"},

    PumpkinPunch = {name = "Pumpkin Punch", icon = "🎃", produces = 2, ingredients = {GlowPumpkin = 2, HoneyPear = 1}, type = "feed", baseFood = "Candy", extraNoise = 9},
    CloudSmoothie = {name = "Cloud Smoothie", icon = "☁️", produces = 2, ingredients = {CloudCotton = 2, FrostBerry = 1}, type = "feed", baseFood = "Bubble", extraNoise = 7},
    FrostPop = {name = "Frost Pop", icon = "❄️", produces = 2, ingredients = {FrostBerry = 2, Peppermint = 1}, type = "feed", baseFood = "Bubble", extraNoise = 12},
    LavaNoodles = {name = "Lava Noodles", icon = "🔥", produces = 2, ingredients = {LavaMelon = 1, WhisperWheat = 2}, type = "feed", baseFood = "Pepper", extraNoise = 18},
    GrapeGiggle = {name = "Grape Giggle Jelly", icon = "🍇", produces = 2, ingredients = {GummyGrape = 2, BubbleCabbage = 1}, type = "feed", baseFood = "Candy", extraNoise = 11},
    NeonNectar = {name = "Neon Nectar", icon = "💡", produces = 2, ingredients = {NeonMushroom = 1, StardustRice = 2}, type = "feed", baseFood = "Star", extraNoise = 13},
    CaramelCrunch = {name = "Caramel Crunch", icon = "🍯", produces = 2, ingredients = {CaramelApple = 2, CandyCane = 1}, type = "feed", baseFood = "Candy", extraNoise = 10},
    MoonMilk = {name = "Moon Milk", icon = "🌙", produces = 2, ingredients = {MoonLotus = 1, MarshmallowRoot = 2}, type = "feed", baseFood = "Star", extraNoise = 9},
    ThunderTonic = {name = "Thunder Tonic", icon = "⚡", produces = 2, ingredients = {ThunderPlum = 2, Peppermint = 1}, type = "feed", baseFood = "Pepper", extraNoise = 16},
    RadishFizz = {name = "Radish Fizz", icon = "🫧", produces = 2, ingredients = {RainbowRadish = 1, HoneyPear = 2}, type = "feed", baseFood = "Bubble", extraNoise = 10},
    StarlightPop = {name = "Starlight Pop", icon = "🌟", produces = 2, ingredients = {StardustRice = 1, CandyCane = 2}, type = "feed", baseFood = "Star", extraNoise = 14},
    JellyToast = {name = "Jelly Toast", icon = "🍞", produces = 2, ingredients = {JellyCactus = 1, WhisperWheat = 2}, type = "feed", baseFood = "Candy", extraNoise = 8},
    GlowLure = {name = "Glow Lure", icon = "🌕", produces = 1, ingredients = {GlowPumpkin = 1, NeonMushroom = 2}, type = "lure"},
    CloudLure = {name = "Cloud Lure", icon = "🌤️", produces = 1, ingredients = {CloudCotton = 2, MarshmallowRoot = 1}, type = "lure"},
    ThunderLure = {name = "Thunder Lure", icon = "🌩️", produces = 1, ingredients = {ThunderPlum = 2, LavaMelon = 1}, type = "lure"},
    RainbowLure = {name = "Rainbow Lure", icon = "🦋", produces = 1, ingredients = {RainbowRadish = 1, GummyGrape = 2}, type = "lure"},
    HoneyCompost = {name = "Honey Compost", icon = "🍯", produces = 2, ingredients = {HoneyPear = 1, BubbleCabbage = 1}, type = "fertilizer"},
    FrostFertilizer = {name = "Frost Fertilizer", icon = "❄️", produces = 1, ingredients = {FrostBerry = 2, MoonLotus = 1}, type = "fertilizer"},
    MysterySlop = {name = "Oops Soup", icon = "🥴", produces = 1, ingredients = {}, type = "feed", baseFood = "Bubble", extraNoise = 5},
}
Catalog.Order = {"BerryMash", "SpicySoup", "MoonCandy", "BubbleTea", "SillyLure", "MonsterLure", "Compost", "Starlight", "PumpkinPunch", "CloudSmoothie", "FrostPop", "LavaNoodles", "GrapeGiggle", "NeonNectar", "CaramelCrunch", "MoonMilk", "ThunderTonic", "RadishFizz", "StarlightPop", "JellyToast", "GlowLure", "CloudLure", "ThunderLure", "RainbowLure", "HoneyCompost", "FrostFertilizer"}
return Catalog
