--!strict
-- Shared game configuration. All balance values are prototypes, not validated production metrics.
local Config = {}

Config.NOISE_MAX = 100
Config.FEED_COOLDOWN = 2.2
Config.FEED_DISTANCE = 26
Config.SLEEP_MAX_SECONDS = 110
Config.WAKE_SECONDS = 32
Config.COOLDOWN_SECONDS = 12
Config.SURVIVAL_REWARD = 35
Config.FEED_REWARD = 2
Config.DATASTORE_NAME = "DWTM_Prototype_v1"
-- Set after uploading assets/audio/original-cat-purr-loop.wav as a Roblox audio asset.
-- Zero deliberately disables audible playback until creator-owned permissions are granted.
Config.PurrSoundId = 0

Config.Foods = {
    Candy = {label = "🍬 CANDY", noise = 9, color = Color3.fromRGB(255, 116, 197)},
    Pepper = {label = "🌶️ PEPPER", noise = 13, color = Color3.fromRGB(255, 102, 90)},
    Bubble = {label = "🫧 BUBBLE", noise = 7, color = Color3.fromRGB(101, 223, 255)},
    Star = {label = "⭐ STAR", noise = 11, color = Color3.fromRGB(255, 224, 99)},
}

Config.DAILY_REWARD = 60
Config.DISCOVERY_REWARD = 8
Config.QUEST_GOALS = {feeds = 5, survivals = 2, discoveries = 4}
Config.QUEST_REWARDS = {feeds = 45, survivals = 80, discoveries = 70}

-- Price is in *earned in-game coins*, never Robux.
Config.Pets = {
    {name = "Pip", color = Color3.fromRGB(253, 132, 193), ear = "pointy", price = 0, description = "pastel kitten"},
    {name = "Mochi", color = Color3.fromRGB(103, 223, 242), ear = "pointy", price = 90},
    {name = "Pickle", color = Color3.fromRGB(155, 224, 110), ear = "round", price = 190},
    {name = "Bloop", color = Color3.fromRGB(200, 163, 255), ear = "pointy", price = 340},
    {name = "Nugget", color = Color3.fromRGB(255, 196, 108), ear = "round", price = 540},
    {name = "Zuzu", color = Color3.fromRGB(255, 104, 145), ear = "pointy", price = 790, description = "fire kitten"},
    {name = "Tofu", color = Color3.fromRGB(245, 241, 202), ear = "round", price = 1100},
    {name = "Wobble", color = Color3.fromRGB(125, 150, 252), ear = "pointy", price = 1500},
    {name = "Spark", color = Color3.fromRGB(255, 234, 102), ear = "pointy", price = 2050},
    {name = "Gloop", color = Color3.fromRGB(90, 228, 184), ear = "round", price = 2700},
    {name = "Luma", color = Color3.fromRGB(255, 183, 233), ear = "round", price = 3500, description = "celestial lamb"},
    {name = "Snorf", color = Color3.fromRGB(230, 169, 126), ear = "round", price = 4300, description = "sleepy pug"},
    {name = "Floofle", color = Color3.fromRGB(255, 236, 222), ear = "pointy", price = 5300, description = "moon bunny"},
    {name = "Quibble", color = Color3.fromRGB(255, 137, 112), ear = "round", price = 6500, description = "candy crab"},
    {name = "Fizzle", color = Color3.fromRGB(253, 122, 85), ear = "pointy", price = 7900, description = "fire salamander"},
    {name = "Puddle", color = Color3.fromRGB(115, 236, 234), ear = "round", price = 9500, description = "baby axolotl"},
    {name = "Sprig", color = Color3.fromRGB(158, 211, 125), ear = "pointy", price = 11300, description = "forest deer"},
    {name = "Twinkle", color = Color3.fromRGB(214, 172, 251), ear = "pointy", price = 13400, description = "butterfly"},
    {name = "Mallow", color = Color3.fromRGB(245, 211, 243), ear = "round", price = 15800, description = "marshmallow bear"},
    {name = "Pebble", color = Color3.fromRGB(142, 219, 161), ear = "round", price = 18500, description = "little turtle"},
    {name = "Noodle", color = Color3.fromRGB(255, 201, 122), ear = "pointy", price = 21500, description = "long-eared ferret"},
    {name = "Swoop", color = Color3.fromRGB(172, 144, 226), ear = "round", price = 24800, description = "sleepy owl"},
    {name = "Rumble", color = Color3.fromRGB(119, 232, 152), ear = "pointy", price = 28400, description = "mini dinosaur"},
    {name = "Doodle", color = Color3.fromRGB(213, 213, 241), ear = "pointy", price = 32300, description = "scribble sprite"},
    {name = "Crumble", color = Color3.fromRGB(220, 162, 95), ear = "round", price = 36500, description = "cookie creature"},
    {name = "Squiggle", color = Color3.fromRGB(161, 152, 255), ear = "round", price = 41000, description = "baby octopus"},
    {name = "Glimmer", color = Color3.fromRGB(255, 207, 245), ear = "pointy", price = 46000, description = "tiny unicorn"},
    {name = "Splat", color = Color3.fromRGB(102, 234, 156), ear = "round", price = 51500, description = "frog"},
    {name = "Puffin", color = Color3.fromRGB(238, 170, 125), ear = "round", price = 57500, description = "snow bird"},
    {name = "Echo", color = Color3.fromRGB(137, 136, 230), ear = "pointy", price = 64000, description = "fruit bat"},
}

-- Each animal gets a different comedy temperament. All can trigger every
-- reaction, but their likelihoods are different, creating distinct behavior.
Config.PetQuirks = {"Trickster", "Dreamer", "Bouncer", "Sparkle", "Storm", "Gremlin"}
for index, pet in ipairs(Config.Pets) do
    pet.quirk = Config.PetQuirks[(index - 1) % #Config.PetQuirks + 1]
end

Config.Reactions = {
    {id = "Giant", title = "IT'S HUGE!", noise = 9, weight = 7},
    {id = "Mini", title = "TINY BABY!", noise = 3, weight = 7},
    {id = "Confetti", title = "CANDY EXPLOSION!", noise = 12, weight = 12},
    {id = "Disco", title = "DISCO DISASTER!", noise = 13, weight = 10},
    {id = "Bounce", title = "BOING BOING!", noise = 11, weight = 11},
    {id = "Sneeze", title = "ACHOOO!", noise = 20, weight = 8},
    {id = "Clone", title = "WHY ARE THERE THREE?!", noise = 14, weight = 8},
    {id = "Rainbow", title = "RAINBOW MODE!", noise = 7, weight = 10},
    {id = "Cloud", title = "BUBBLE STORM!", noise = 5, weight = 8},
    {id = "Spin", title = "SPINNY BEAN!", noise = 9, weight = 8},
    {id = "Hiccup", title = "UNSTOPPABLE HICCUPS!", noise = 16, weight = 8},
    {id = "Meteor", title = "JELLY METEOR!", noise = 18, weight = 5},
}

return Config
