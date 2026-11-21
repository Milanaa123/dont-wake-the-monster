#!/usr/bin/env python3
"""Run the real ProfileStore module with failing/yielding stores in Luau.

These test persistence coordination, not the Roblox engine or live DataStore.
"""
from pathlib import Path
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
module = (root / "src/server/ProfileStore.luau").read_text(encoding="utf-8")
suite = r'''
local warnings = {}
local function warn(message) table.insert(warnings, message) end
local task = {wait = function() coroutine.yield("waiting") end}
local ProfileStore = (function()
MODULE
end)()
local function serialize(p) return {coins = p.coins} end
local function profile()
    return {coins = 10, loaded = true, dirty = true, revision = 1}
end

local offline = ProfileStore.new({GetDataStore = function() error("unpublished") end}, "test", serialize)
assert(not offline:load(7), "initialization failure must degrade to session-only")
assert(offline:save(7, profile()), "offline sessions must not crash on leave")

local writes = {}
local backend = {
    GetAsync = function(_, key) assert(key == "player_7"); return {coins = 42} end,
    UpdateAsync = function(_, key, update)
        assert(key == "player_7")
        table.insert(writes, update(nil))
    end,
}
local persistence = ProfileStore.new({GetDataStore = function() return backend end}, "test", serialize)
local loaded, data = persistence:load(7)
assert(loaded and data.coins == 42, "existing save must load")
backend.GetAsync = function() return nil end
loaded, data = persistence:load(7)
assert(loaded and data == nil, "new accounts are available, not load failures")
backend.GetAsync = function() error("load failed") end
assert(not persistence:load(7), "failed reads must never authorize saving defaults")
local p = profile()
p.loaded = false
assert(persistence:save(7, p) and #writes == 0, "unloaded defaults must never overwrite a save")
p.loaded = true
assert(persistence:save(7, p) and not p.dirty and writes[1].coins == 10)
assert(persistence:save(7, p) and #writes == 1, "clean profiles need no extra write")

backend.UpdateAsync = function() error("throttled") end
p.dirty = true
assert(not persistence:save(7, p) and p.dirty, "failed saves remain dirty for retry")
assert(persistence.saving[p] == nil, "failure must release save lock")

-- Deterministically interleave autosave and player-leave saves.
local inFlight = 0
local snapshots = {}
backend.UpdateAsync = function(_, _, update)
    inFlight += 1
    assert(inFlight == 1, "two writes for one profile overlapped")
    local snapshot = update(nil)
    coroutine.yield("writing")
    assert(update({coins = 0}) == snapshot, "UpdateAsync retries must reuse the immutable snapshot")
    table.insert(snapshots, snapshot.coins)
    inFlight -= 1
end
local autosave = coroutine.create(function() assert(persistence:save(7, p)) end)
local leave = coroutine.create(function() assert(persistence:save(7, p)) end)
local ok, status = coroutine.resume(autosave)
assert(ok and status == "writing")
p.coins = 99
p.revision += 1
ok, status = coroutine.resume(leave)
assert(ok and status == "waiting", "leave must wait instead of skipping final progress")
assert(coroutine.resume(autosave))
assert(p.dirty, "changes during autosave must stay dirty")
ok, status = coroutine.resume(leave)
assert(ok and status == "writing", "leave must start a fresh snapshot after autosave")
assert(coroutine.resume(leave))
assert(snapshots[1] == 10 and snapshots[2] == 99 and not p.dirty, "newest snapshot must win")

local broken = ProfileStore.new({GetDataStore = function() return backend end}, "test", function() error("bad save data") end)
p.dirty = true
assert(not broken:save(7, p) and broken.saving[p] == nil, "serializer failure must release lock")
assert(#warnings == 3)

-- Cross-server session ownership: two servers share a single DataStore key,
-- but only the first one is allowed to save that player's live progress.
local records = {player_7 = {coins = 45}}
local concurrentStore = {
    UpdateAsync = function(_, key, callback)
        local replacement = callback(records[key])
        if replacement ~= nil then records[key] = replacement end
        return replacement
    end,
}
local service = {GetDataStore = function() return concurrentStore end}
local first = ProfileStore.new(service, "test", serialize, "server-uuid-A")
local second = ProfileStore.new(service, "test", serialize, "server-uuid-B")
local third = ProfileStore.new(service, "test", serialize, "server-uuid-C")
local claimed, restored = first:load(7)
assert(claimed and restored.coins == 45)
assert(records.player_7._dwtmLease.token == "server-uuid-A")
assert(not second:load(7), "second server must never load writeable duplicate progress")
assert(second.lastLoadError == "This profile is still open on another server")
local active = {coins = 151, loaded = true, dirty = true, revision = 1}
assert(first:save(7, active) and not active.dirty)
assert(records.player_7.coins == 151 and records.player_7._dwtmLease.token == "server-uuid-A")
assert(first:save(7, active), "clean profiles must renew their ownership lease")
assert(not second:load(7), "refresh must keep the profile locked")
assert(first:release(7, active))
assert(records.player_7._dwtmLease == nil, "graceful leave must release the lock")
claimed, restored = second:load(7)
assert(claimed and restored.coins == 151)
active.loaded = true
active.dirty = true
active.coins = 999
active.revision += 1
assert(not first:save(7, active), "old server must refuse to overwrite fresh owner")
assert(not active.loaded and records.player_7.coins == 151)
local successor = {coins = 208, loaded = true, dirty = true, revision = 1}
assert(second:save(7, successor) and second:release(7, successor))
claimed, restored = third:load(7)
assert(claimed and restored.coins == 208)
-- A crashed server does not hold the profile forever after lease timeout.
records.player_7._dwtmLease.expiresAt = os.time() - 1
claimed, restored = first:load(7)
assert(claimed and restored.coins == 208)
assert(first:release(7, {loaded = true, revision = 1}))
print("PASS: cross-server acquisition, conflict rejection, lease renewal, release, stale-write protection and timeout recovery")
print("PASS: unavailable/new/failed loads, no writes from unloaded profiles, save retry, autosave/leave ordering, dirty revisions and serializer recovery")
'''.replace("MODULE", module)
with tempfile.TemporaryDirectory() as folder:
    path = Path(folder) / "persistence.luau"
    path.write_text(suite, encoding="utf-8")
    subprocess.run([sys.argv[1] if len(sys.argv) > 1 else "luau", str(path)], check=True)
