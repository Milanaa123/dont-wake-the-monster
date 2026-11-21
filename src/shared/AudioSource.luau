--!strict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local AudioSource={}

function AudioSource.resolve(id: number?, filename: string): string?
    if id and id>0 and id==math.floor(id) then return "rbxassetid://"..id end
    local kit=ReplicatedStorage:FindFirstChild("StudioContentFolder")
    if RunService:IsStudio() and kit and kit:IsA("StringValue") then
        return "rbxasset://"..kit.Value.."/"..filename..".wav"
    end
    return nil
end

return AudioSource
