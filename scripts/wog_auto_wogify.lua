-- wog_auto_wogify.lua
-- WOG New Age — Auto-WoGification (option 1 / "Replace Objects During WoGification")
--
-- On Day 1 of a new game (after the setup screen), if C.autoWogifyEnabled is true
-- and the map has no existing WOG adventure objects, automatically scatter WOG objects
-- at random locations scaled to map size.
--
-- Objects placed (from wog-newage mod):
--   Artificers        : upgrade equipped artifacts for gold
--   Death Chambers    : grant exactly 1 hero level
--   Power Stones      : +1 primary stat collectibles
--   Special Chests    : mine deeds / Tomes of Knowledge / gold+spell
--
-- Object counts (scaled to map area):
--   Small  (< 72×72)   : 1 Artificer, 2 Death Chambers, 3 Power Stones, 4 Chests
--   Medium (< 144×144) : 2 Artificers, 4 Death Chambers, 6 Power Stones, 8 Chests
--   Large  (≥ 144×144) : 4 Artificers, 8 Death Chambers, 12 Power Stones, 16 Chests
--
-- SERVER:spawnObject(scope, type, subtype, x, y, z [, initiatorPlayer])
-- is now implemented in FCMI. Objects are placed at random surface tiles,
-- avoiding a 10-tile border around the edges.

local TurnStarted = require("events.TurnStarted")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.autoWogifyEnabled = C.autoWogifyEnabled ~= false

-- ---------------------------------------------------------------------------
-- WOG object definitions: {scope, type, subtype}
-- ---------------------------------------------------------------------------
local WOG_OBJECTS = {
	artificer   = {"wog-newage.objects", "wogArtificer",    "wogArtificer"},
	deathChamber= {"wog-newage.objects", "wogDeathChamber", "wogDeathChamber"},
	powerStone  = {"wog-newage.objects", "wogPowerStones",  "wogPowerStones"},
	chest2      = {"wog-newage.objects", "wogTreasureChest2","wogTreasureChest2"},
}

-- Obj type groups for our custom objects (used to detect existing WoGification)
-- These correspond to the VCMI object groups our objects register under
local WOG_DETECT_OBJ_TYPES = {17, 54, 76}  -- creature generators, mines, resources (approx)

-- Object counts by map tier
local COUNTS = {
	small  = {artificer = 1, deathChamber = 2, powerStone = 3,  chest2 = 4},
	medium = {artificer = 2, deathChamber = 4, powerStone = 6,  chest2 = 8},
	large  = {artificer = 4, deathChamber = 8, powerStone = 12, chest2 = 16},
}

local function getMapTier()
	local w = GAME:getMapWidth()
	local h = GAME:getMapHeight()
	if not w or not h then return "medium" end
	local area = w * h
	if area < (72 * 72)     then return "small"
	elseif area < (144*144) then return "medium"
	else                         return "large"
	end
end

-- ---------------------------------------------------------------------------
-- Generate a random tile avoiding map edges (10-tile border)
-- ---------------------------------------------------------------------------
local function randomTile(w, h)
	local x = math.random(10, w - 11)
	local y = math.random(10, h - 11)
	return x, y, 0   -- z=0 = surface
end

-- ---------------------------------------------------------------------------
-- Place N copies of an object at random tiles
-- ---------------------------------------------------------------------------
local function placeN(scope, type, subtype, n, w, h, playerIdx)
	for i = 1, n do
		local x, y, z = randomTile(w, h)
		local ok, err = pcall(function()
			SERVER:spawnObject(scope, type, subtype, x, y, z, playerIdx)
		end)
		if not ok then
			-- Log failure but continue placing others
		end
	end
end

-- ---------------------------------------------------------------------------
-- TurnStarted Day 1: run auto-wogify after setup screen completes
-- ---------------------------------------------------------------------------
wogAutoWogifySub = TurnStarted.subscribeAfter(EVENT_BUS, function(event)
	if not C.autoWogifyEnabled then return end
	if C.autoWogifyDone        then return end

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

	local w      = GAME:getMapWidth()  or 144
	local h      = GAME:getMapHeight() or 144
	local tier   = getMapTier()
	local counts = COUNTS[tier]

	-- Guard: need at least a 22×22 map for the 10-tile border to work
	if w < 22 or h < 22 then return end

	-- Place objects
	local art = WOG_OBJECTS.artificer
	local dc  = WOG_OBJECTS.deathChamber
	local ps  = WOG_OBJECTS.powerStone
	local ch  = WOG_OBJECTS.chest2

	placeN(art[1], art[2], art[3], counts.artificer,    w, h, playerIdx)
	placeN(dc[1],  dc[2],  dc[3],  counts.deathChamber, w, h, playerIdx)
	placeN(ps[1],  ps[2],  ps[3],  counts.powerStone,   w, h, playerIdx)
	placeN(ch[1],  ch[2],  ch[3],  counts.chest2,       w, h, playerIdx)

	-- Notify player
	local total = counts.artificer + counts.deathChamber + counts.powerStone + counts.chest2
	local InfoWindow = require("netpacks.InfoWindow")
	local iw = InfoWindow.new()
	iw:setPlayer(playerIdx)
	iw:addText("{WOG New Age — Auto-WoGification}\\n\\n"
	        .. "This map has been WoGified! " .. tostring(total) .. " WOG objects\\n"
	        .. "have been scattered across the " .. tier .. " map:\\n"
	        .. tostring(counts.artificer) .. " Artificer(s), "
	        .. tostring(counts.deathChamber) .. " Death Chamber(s),\\n"
	        .. tostring(counts.powerStone) .. " Power Stone(s), "
	        .. tostring(counts.chest2) .. " Special Chest(s).")
	SERVER:commitPackage(iw)
end)
