--!strict
-- Studio CLI smoke test. This is NOT a playtest unless an actual running simulation is launched.
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
print("DWTM_STUDIO_CLI_BEGIN")
print("PlaceName:", game.Name)
print("WorkspaceCount:", #workspace:GetChildren())
for _, name in ipairs({"Game", "World", "Garden", "RescueObjective"}) do
    local inst = ServerScriptService:FindFirstChild(name)
    print("SERVER_" .. name, inst and inst.ClassName or "NOT_FOUND")
end
for _, name in ipairs({"Config", "GardenConfig", "PetPersonality", "PetAffection"}) do
    local inst = ReplicatedStorage:FindFirstChild(name)
    print("SHARED_" .. name, inst and inst.ClassName or "NOT_FOUND")
end
local ok, err = pcall(function()
    local config = require(ReplicatedStorage:WaitForChild("Config"))
    print("DWTM_PETS", #config.Pets, "REACTIONS", #config.Reactions)
end)
print("DWTM_MODULE_LOAD", ok, tostring(err))
print("DWTM_STUDIO_CLI_FINISHED")
