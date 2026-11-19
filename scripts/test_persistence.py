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
print("PASS: unavailable/new/failed loads, no writes from unloaded profiles, save retry, autosave/leave ordering, dirty revisions and serializer recovery")
'''.replace("MODULE", module)
with tempfile.TemporaryDirectory() as folder:
    path = Path(folder) / "persistence.luau"
    path.write_text(suite, encoding="utf-8")
    subprocess.run([sys.argv[1] if len(sys.argv) > 1 else "luau", str(path)], check=True)
