--!strict
-- Client-only cozy audio mix with an accessible mute button.
-- The offline Studio kit resolves the same originals from its local content directory.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Config = require(ReplicatedStorage:WaitForChild("AudioConfig"))
local remote = ReplicatedStorage:WaitForChild("MonsterRemote") :: RemoteEvent
local AudioSource = require(ReplicatedStorage.AudioSource)
local player = Players.LocalPlayer

local soundGroup = Instance.new("SoundGroup")
soundGroup.Name = "DWTMMusicMix"
soundGroup.Volume = 1
soundGroup.Parent = SoundService
local effectsGroup = Instance.new("SoundGroup")
effectsGroup.Name = "DWTMEffectsMix"
effectsGroup.Volume = 1
effectsGroup.Parent = SoundService

local music: Sound? = nil
local chase: Sound? = nil
local ambience: Sound? = nil
local musicEnabled = true
local effectsEnabled = true
local phase = "SLEEP"
local lastStirWake: number? = nil
local recent: {[string]: number} = {}

local gui = Instance.new("ScreenGui")
gui.Name = "AudioSettings"
gui.ResetOnSpawn = false
gui.DisplayOrder = 7
gui.Parent = player:WaitForChild("PlayerGui")

local musicButton = Instance.new("TextButton")
musicButton.Name = "MusicToggle"
musicButton.Position = UDim2.new(1, -164, 0, 290)
musicButton.Size = UDim2.fromOffset(152, 33)
musicButton.BackgroundColor3 = Color3.fromRGB(244, 239, 229)
musicButton.TextColor3 = Color3.fromRGB(72, 50, 92)
musicButton.TextScaled = true
musicButton.Font = Enum.Font.GothamBlack
musicButton.Text = "🎵 MUSIC ON"
musicButton.Parent = gui
local c = Instance.new("UICorner")
c.CornerRadius = UDim.new(0, 12)
c.Parent = musicButton

local fxButton = Instance.new("TextButton")
fxButton.Name = "EffectsToggle"
fxButton.Position = UDim2.new(1, -164, 0, 329)
fxButton.Size = UDim2.fromOffset(152, 33)
fxButton.BackgroundColor3 = Color3.fromRGB(244, 239, 229)
fxButton.TextColor3 = Color3.fromRGB(72, 50, 92)
fxButton.TextScaled = true
fxButton.Font = Enum.Font.GothamBlack
fxButton.Text = "🔊 EFFECTS ON"
fxButton.Parent = gui
local d = Instance.new("UICorner")
d.CornerRadius = UDim.new(0, 12)
d.Parent = fxButton

local function refreshButtons()
    musicButton.Text = if musicEnabled then "🎵 MUSIC ON" else "🔇 MUSIC OFF"
    fxButton.Text = if effectsEnabled then "🔊 EFFECTS ON" else "🔇 EFFECTS OFF"
    if not music and not chase then musicButton.Text = "🎵 AUDIO PENDING" end
end
local function loopTrack(assetId: number?, file: string, name: string, volume: number, group: SoundGroup): Sound?
    local uri=AudioSource.resolve(assetId,file)
    if not uri then return nil end
    local sound = Instance.new("Sound")
    sound.Name = name
    sound.SoundId = uri
    sound.Volume = volume
    sound.Looped = true
    sound.SoundGroup = group
    sound.Parent = SoundService
    sound:Play()
    return sound
end
music = loopTrack(Config.MusicAssetId,"calm-garden-theme","OriginalCozyGardenTheme",Config.MusicVolume,soundGroup)
chase = loopTrack(Config.ChaseMusicAssetId, "monster-chase-theme", "OriginalMonsterChaseTheme", 0, soundGroup)
ambience = loopTrack(Config.AmbienceAssetId, "sleepy-forest-ambience", "OriginalSleepyForestAmbience",
    if musicEnabled then Config.AmbienceVolume else 0, soundGroup)

local function crossfadeMusic()
    local calmVolume = if musicEnabled and phase ~= "AWAKE" then Config.MusicVolume else 0
    local chaseVolume = if musicEnabled and phase == "AWAKE" then Config.ChaseMusicVolume else 0
    local ambientVolume = if musicEnabled and phase == "SLEEP" then Config.AmbienceVolume else 0
    for _, item in ipairs({
        {sound = music, target = calmVolume},
        {sound = chase, target = chaseVolume},
        {sound = ambience, target = ambientVolume},
    }) do
        if item.sound then
            TweenService:Create(item.sound, TweenInfo.new(1.1, Enum.EasingStyle.Quad), {Volume = item.target}):Play()
        end
    end
end

musicButton.MouseButton1Click:Connect(function()
    musicEnabled = not musicEnabled
    crossfadeMusic()
    refreshButtons()
end)
fxButton.MouseButton1Click:Connect(function()
    effectsEnabled = not effectsEnabled
    refreshButtons()
end)

local cueFiles: {[string]: string} = {TinyViolin="tiny-violin-fail", SuspiciousMeow="suspicious-meow",
    RecordScratch="cartoon-record-scratch", ComedySting="comedy-drum-sting"}
local function playCue(id: string)
    if not effectsEnabled then return end
    local assetId = Config.Cues[id]
    if assetId==nil then return end
    local uri=AudioSource.resolve(assetId,cueFiles[id] or id)
    if not uri then return end
    local now = os.clock()
    if now - (recent[id] or -100) < 0.35 then return end
    recent[id] = now
    local effect = Instance.new("Sound")
    effect.Name = "Original_" .. id
    effect.SoundId = uri
    effect.Volume = Config.CueVolume
    effect.SoundGroup = effectsGroup
    effect.Parent = SoundService
    effect:Play()
    Debris:AddItem(effect, 12)
end

remote.OnClientEvent:Connect(function(event: any)
    if typeof(event) ~= "table" then return end
    if event.type == "soundCue" and type(event.cue) == "string" then
        playCue(event.cue)
    elseif event.type == "state" then
        local nextPhase = event.phase or phase
        if nextPhase == "SLEEP" and event.warning and lastStirWake ~= event.wakes then
            lastStirWake = event.wakes
            playCue("SleepyGrumble")
        end
        if nextPhase ~= phase then
            phase = nextPhase
            crossfadeMusic()
        end
    end
end)
refreshButtons()
