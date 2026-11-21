--!strict
-- Cross-server session-locked profile persistence.
-- The UpdateAsync lease prevents two server instances overwriting the same
-- player's inventory/progress. Legacy profiles are claimed in-place.
-- If the database is unavailable or a different live server owns the key,
-- gameplay degrades to an explicitly non-saving session.
local ProfileStore = {}
ProfileStore.__index = ProfileStore

local LEASE_SECONDS = 240
local LEASE_FIELD = "_dwtmLease"

function ProfileStore.new(service: any, name: string, serialize: (any) -> any,
    serverToken: string?)
    local self: any = setmetatable({
        serialize = serialize,
        saving = {},
        serverToken = serverToken,
        lastLoadError = nil,
    }, ProfileStore)
    local ok, result = pcall(function() return service:GetDataStore(name) end)
    if ok then
        self.store = result
    else
        warn("DWTM: persistence initialization unavailable. Progress is session-only: " .. tostring(result))
    end
    return self
end

local function ours(self: any, snapshot: any): boolean
    return type(snapshot) == "table"
        and type(snapshot[LEASE_FIELD]) == "table"
        and snapshot[LEASE_FIELD].token == self.serverToken
end

local function withLease(self: any, state: any): any
    local saved = table.clone(state)
    saved[LEASE_FIELD] = {token = self.serverToken, expiresAt = os.time() + LEASE_SECONDS}
    return saved
end

function ProfileStore.load(self: any, userId: number): (boolean, any)
    self.lastLoadError = nil
    if not self.store then
        self.lastLoadError = "DataStore unavailable"
        return false, nil
    end
    local key = "player_" .. userId
    if not self.serverToken then
        -- Legacy opt-out is retained only for local/mock tests. Production Game
        -- always passes its unique server GUID and uses atomic lease acquisition.
        local ok, result = pcall(function() return self.store:GetAsync(key) end)
        if not ok then self.lastLoadError = tostring(result) end
        return ok, if ok then result else nil
    end
    local locked = false
    local ok, record = pcall(function()
        return self.store:UpdateAsync(key, function(previous: any)
            local data = if type(previous) == "table" then previous else {}
            local lease = data[LEASE_FIELD]
            if type(lease) == "table" and lease.token ~= self.serverToken
                and type(lease.expiresAt) == "number"
                and lease.expiresAt > os.time() then
                locked = true
                return nil
            end
            locked = false
            return withLease(self, data)
        end)
    end)
    if not ok then
        self.lastLoadError = "DataStore load/lease failed: " .. tostring(record)
        return false, nil
    end
    if locked or not ours(self, record) then
        self.lastLoadError = "This profile is still open on another server"
        return false, nil
    end
    return true, record
end

function ProfileStore.save(self: any, userId: number, profile: any): boolean
    -- A leave/shutdown save waits for autosave and creates its own snapshot.
    -- Otherwise an overlapping leave could skip the final few actions.
    while self.saving[profile] do task.wait() end
    if not self.store or not profile.loaded then return true end
    if not profile.dirty and not self.serverToken then return true end
    self.saving[profile] = true
    local revision = profile.revision
    local wrote = false
    local lostLease = false
    local ok, err = pcall(function()
        -- Important: serialize ONCE outside UpdateAsync; Roblox can call the
        -- transform multiple times. The result must be immutable per attempt.
        local snapshot = if profile.dirty then self.serialize(profile) else nil
        self.store:UpdateAsync("player_" .. userId, function(previous: any)
            if self.serverToken then
                if not ours(self, previous) then
                    lostLease = true
                    return nil
                end
                lostLease = false
                wrote = true
                return withLease(self, snapshot or previous)
            end
            wrote = true
            return snapshot
        end)
    end)
    self.saving[profile] = nil
    if ok and wrote and not lostLease then
        if profile.revision == revision then profile.dirty = false end
        return true
    end
    if lostLease then
        -- Never overwrite a newer server's progress. Rejoin is required.
        profile.loaded = false
        warn("DWTM: session ownership lost for " .. userId .. ". Saving disabled for this session.")
    elseif not ok then
        warn("DWTM: data save failed for " .. userId .. ": " .. tostring(err))
    end
    return false
end

function ProfileStore.release(self: any, userId: number, profile: any): boolean
    if not self.store or not profile.loaded or not self.serverToken then return true end
    while self.saving[profile] do task.wait() end
    self.saving[profile] = true
    local owned = false
    local ok, err = pcall(function()
        self.store:UpdateAsync("player_" .. userId, function(previous: any)
            if not ours(self, previous) then return nil end
            owned = true
            local nextState = table.clone(previous)
            nextState[LEASE_FIELD] = nil
            return nextState
        end)
    end)
    self.saving[profile] = nil
    if not ok then warn("DWTM: lease release failed for " .. userId .. ": " .. tostring(err)) end
    return ok and owned
end

return ProfileStore
