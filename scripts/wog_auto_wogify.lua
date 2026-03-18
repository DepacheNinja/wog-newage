-- wog_auto_wogify.lua
-- WOG New Age — Auto-WoGification (option 1 / "Replace Objects During WoGification")
--
-- On Day 1 of a new game (after the setup screen), if C.autoWogifyEnabled is true
-- and the map has no existing WOG adventure objects, automatically scatter WOG objects
-- at random locations scaled to map size:
--   Artificers, Death Chambers, Power Stones, Special Treasure Chests
--
-- WOG object subtype identifiers (from mod config/objects/):
--   wog-newage.objects:wog_artificer
--   wog-newage.objects:wog_death_chamber
--   wog-newage.objects:wog_power_stones
--   wog-newage.objects:wog_treasure_chest2
--
-- Object counts (scaled to map size area):
--   Small  (< 72×72 = 5184 tiles) : 1 Artificer, 2 Death Chambers, 3 Power Stones, 4 Chests
--   Medium (< 144×144)             : 2 Artificers, 4 Death Chambers, 6 Power Stones, 8 Chests
--   Large  (≥ 144×144)             : 4 Artificers, 8 Death Chambers, 12 Power Stones, 16 Chests
--
-- VCMI ENGINE NOTE: SERVER:spawnObject() is not yet implemented in FCMI.
-- This script reads map dimensions and detects whether WoGification is needed,
-- then logs its intent. Actual object placement will be activated once
-- SERVER:spawnObject(subtypeName, x, y, z) is available in the engine.

local TurnStarted = require("events.TurnStarted")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.autoWogifyEnabled = C.autoWogifyEnabled ~= false

-- WOG object type IDs used to detect existing WOG maps (Obj group IDs)
-- These are the custom object types registered by wog-newage
local WOG_OBJECT_SUBTYPES = {
	"wog-newage.objects:wog_artificer",
	"wog-newage.objects:wog_death_chamber",
	"wog-newage.objects:wog_power_stones",
	"wog-newage.objects:wog_treasure_chest2",
}

-- Obj type 16 = ARTIFACT, used by artificer/death chamber detection
-- Obj type 76 = RESOURCE (power stones/treasure chests)
-- We check for any WOG new-age map objects to skip already-WoGified maps.
-- In FCMI, getMapObjectIds takes an Obj group integer. WOG custom objects
-- register under specific Obj groups; for detection we rely on C.autoWogifyDone flag.

-- Object counts by map tier
local COUNTS = {
	small  = {artificer = 1, deathChamber = 2, powerStone = 3,  chest = 4},
	medium = {artificer = 2, deathChamber = 4, powerStone = 6,  chest = 8},
	large  = {artificer = 4, deathChamber = 8, powerStone = 12, chest = 16},
}

local function getMapTier()
	local w = GAME:getMapWidth()
	local h = GAME:getMapHeight()
	if not w or not h then return "medium" end
	local area = w * h
	if area < (72 * 72)   then return "small"
	elseif area < (144 * 144) then return "medium"
	else                      return "large"
	end
end

-- ---------------------------------------------------------------------------
-- TurnStarted Day 1: run auto-wogify after setup screen completes
-- ---------------------------------------------------------------------------
wogAutoWogifySub = TurnStarted.subscribeAfter(EVENT_BUS, function(event)
	if not C.autoWogifyEnabled  then return end
	if C.autoWogifyDone         then return end

	local day   = GAME:getDate(0)
	local week  = GAME:getDate(1)
	local month = GAME:getDate(2)
	if day ~= 1 or week ~= 1 or month ~= 1 then
		C.autoWogifyDone = true   -- loaded mid-game, skip
		return
	end

	local playerIdx = event:getPlayer()
	if not GAME:isPlayerHuman(playerIdx) then return end

	C.autoWogifyDone = true

	-- Gather map info
	local w      = GAME:getMapWidth()  or 144
	local h      = GAME:getMapHeight() or 144
	local levels = GAME:getMapLevels() or 1
	local tier   = getMapTier()
	local counts = COUNTS[tier]

	-- TODO: when SERVER:spawnObject(subtypeName, x, y, z) is available,
	-- scatter WOG objects at random passable land tiles here.
	-- For now, log intent and notify player.

	-- Count objects actually scheduled (for display)
	local total = counts.artificer + counts.deathChamber + counts.powerStone + counts.chest

	-- Only WoGify maps that need it (future: detect via getMapObjectIds)
	-- For now always offer if enabled.

	-- STUB: SERVER:spawnObject not yet available in FCMI.
	-- When implemented, call:
	--   SERVER:spawnObject("wog-newage.objects:wog_artificer",  rx, ry, rz)
	-- for each object in counts, at random passable surface tiles.
	--
	-- Until then, skip silently — the flag is set so this doesn't re-run.
	-- Remove the early return below once spawnObject is ready.
	return

	--[[ FUTURE IMPLEMENTATION (remove the 'return' above to activate):
	local placed = 0
	local rng    = GAME:getRandomGenerator and GAME:getRandomGenerator() or nil

	local function randomTile(maxX, maxY)
		local x = math.random(1, maxX - 2)
		local y = math.random(1, maxY - 2)
		return x, y, 0  -- z=0 surface
	end

	local function placeN(subtype, n)
		for i = 1, n do
			local x, y, z = randomTile(w, h)
			SERVER:spawnObject(subtype, x, y, z)
			placed = placed + 1
		end
	end

	placeN("wog-newage.objects:wog_artificer",      counts.artificer)
	placeN("wog-newage.objects:wog_death_chamber",  counts.deathChamber)
	placeN("wog-newage.objects:wog_power_stones",   counts.powerStone)
	placeN("wog-newage.objects:wog_treasure_chest2", counts.chest)
	--]]
end)
