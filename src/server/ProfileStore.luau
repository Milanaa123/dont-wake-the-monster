--!strict
-- Persistence failures must not stop an unpublished local playtest.
-- Saves for one profile are serialized, including autosave/leave overlap.
-- Cross-server ownership/session locking is still required before release.
local ProfileStore = {}
ProfileStore.__index = ProfileStore

function ProfileStore.new(service: any, name: string, serialize: (any) -> any)
    local self: any = setmetatable({serialize = serialize, saving = {}}, ProfileStore)
    local ok, result = pcall(function() return service:GetDataStore(name) end)
    if ok then
        self.store = result
    else
        warn("DWTM: persistence initialization unavailable. Progress is session-only: " .. tostring(result))
    end
    return self
end

function ProfileStore.load(self: any, userId: number): (boolean, any)
    if not self.store then return false, nil end
    return pcall(function() return self.store:GetAsync("player_" .. userId) end)
end

function ProfileStore.save(self: any, userId: number, profile: any): boolean
    -- A leave/shutdown save waits for the autosave before taking a NEW snapshot.
    -- Merely skipping an in-flight save can lose the last actions before leaving.
    while self.saving[profile] do task.wait() end
    if not self.store or not profile.loaded or not profile.dirty then return true end
    self.saving[profile] = true
    local revision = profile.revision
    local ok, err = pcall(function()
        local snapshot = self.serialize(profile)
        self.store:UpdateAsync("player_" .. userId, function(_previous: any)
            return snapshot
        end)
    end)
    self.saving[profile] = nil
    if ok then
        if profile.revision == revision then profile.dirty = false end
    else
        warn("DWTM: data save failed for " .. userId .. ": " .. tostring(err))
    end
    return ok
end

return ProfileStore
