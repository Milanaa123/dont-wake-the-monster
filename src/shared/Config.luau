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
    {name = "Pip", color = Color3.fromRGB(253, 132, 193), ear = "round", price = 0},
    {name = "Mochi", color = Color3.fromRGB(103, 223, 242), ear = "pointy", price = 90},
    {name = "Pickle", color = Color3.fromRGB(155, 224, 110), ear = "round", price = 190},
    {name = "Bloop", color = Color3.fromRGB(200, 163, 255), ear = "pointy", price = 340},
    {name = "Nugget", color = Color3.fromRGB(255, 196, 108), ear = "round", price = 540},
    {name = "Zuzu", color = Color3.fromRGB(255, 104, 145), ear = "pointy", price = 790},
    {name = "Tofu", color = Color3.fromRGB(245, 241, 202), ear = "round", price = 1100},
    {name = "Wobble", color = Color3.fromRGB(125, 150, 252), ear = "pointy", price = 1500},
    {name = "Spark", color = Color3.fromRGB(255, 234, 102), ear = "pointy", price = 2050},
    {name = "Gloop", color = Color3.fromRGB(90, 228, 184), ear = "round", price = 2700},
}

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
