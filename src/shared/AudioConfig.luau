--!strict
-- ORIGINAL audio sources are committed in assets/audio/*.wav.
-- Roblox SoundId values MUST be asset IDs belonging to an authorized creator.
-- Zero means muted until the WAV was uploaded/moderated in Creator Dashboard.
local Audio = {}
Audio.MusicAssetId = 0 -- assets/audio/calm-garden-theme.wav
Audio.ChaseMusicAssetId = 0 -- assets/audio/monster-chase-theme.wav
Audio.AmbienceAssetId = 0 -- assets/audio/sleepy-forest-ambience.wav
Audio.Cues = {
    SeedFind = 0,         -- assets/audio/SeedFind.wav
    RareDiscovery = 0,    -- assets/audio/RareDiscovery.wav
    WeatherChime = 0,     -- assets/audio/WeatherChime.wav
    Boing = 0,            -- assets/audio/Boing.wav
    MonsterWake = 0,      -- assets/audio/MonsterWake.wav
    Victory = 0,          -- assets/audio/Victory.wav
    Festival = 0,         -- assets/audio/Festival.wav
    SillyStorm = 0,       -- assets/audio/SillyStorm.wav
    HarvestPop = 0,       -- assets/audio/HarvestPop.wav
    MutationSparkle = 0,  -- assets/audio/MutationSparkle.wav
    CatSwat = 0,          -- assets/audio/CatSwat.wav
    TinyViolin = 0,       -- assets/audio/tiny-violin-fail.wav
    SuspiciousMeow = 0,   -- assets/audio/suspicious-meow.wav
    RecordScratch = 0,    -- assets/audio/cartoon-record-scratch.wav
    ComedySting = 0,      -- assets/audio/comedy-drum-sting.wav
}
Audio.MusicVolume = 0.18
Audio.CueVolume = 0.48
Audio.AmbienceVolume = 0.12
Audio.ChaseMusicVolume = 0.21
return Audio
