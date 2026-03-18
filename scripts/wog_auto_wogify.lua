-- wog_auto_wogify.lua
-- WOG New Age — Auto-WoGification (option 1 / "Replace Objects During WoGification")
--
-- On Day 1 of a new game (after the setup screen), if C.autoWogifyEnabled is true,
-- scatter WOG/WOG-mapObjects across the map scaled to map size.
--
-- Placement list: {scope, type, subtype, small_count, medium_count, large_count}
--   small  = map area < 72×72
--   medium = map area < 144×144
--   large  = map area ≥ 144×144
--
-- SERVER:spawnObject(scope, type, subtype, x, y, z [, initiatorPlayer])
-- is implemented in FCMI. Objects are placed at random surface tiles,
-- avoiding a 10-tile border around the edges.

local TurnStarted = require("events.TurnStarted")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.autoWogifyEnabled = C.autoWogifyEnabled ~= false

-- ---------------------------------------------------------------------------
-- Object placement list: {scope, type, subtype, small, medium, large}
-- ---------------------------------------------------------------------------
local PLACEMENT_LIST = {
	-- wog-newage custom objects
	{"wog-newage.objects", "wogArtificer",          "wogArtificer",          1,  2,  4},
	{"wog-newage.objects", "wogDeathChamber",        "wogDeathChamber",       2,  4,  8},
	{"wog-newage.objects", "wogPowerStones",         "wogPowerStones",        3,  6, 12},
	{"wog-newage.objects", "wogTreasureChest2",      "wogTreasureChest2",     4,  8, 16},
	-- wake-of-gods.mapObjects
	{"wake-of-gods.mapObjects", "arcaneTower",          "arcaneTower",          0,  1,  2},
	{"wake-of-gods.mapObjects", "junkMerchant",         "junkMerchant",         1,  2,  3},
	{"wake-of-gods.mapObjects", "waterMagicMushroom",   "waterMagicMushroom",   1,  2,  3},
	{"wake-of-gods.mapObjects", "airMagicMushroom",     "airMagicMushroom",     1,  2,  3},
	{"wake-of-gods.mapObjects", "earthMagicMushroom",   "earthMagicMushroom",   1,  2,  3},
	{"wake-of-gods.mapObjects", "fireMagicMushroom",    "fireMagicMushroom",    1,  2,  3},
	{"wake-of-gods.mapObjects", "mirrorOfTheHomeWay",   "mirrorOfTheHomeWay",   0,  1,  1},
	{"wake-of-gods.mapObjects", "almsHouse",            "almsHouse",            0,  1,  1},
	{"wake-of-gods.mapObjects", "palaceOfDreams",       "palaceOfDreams",       0,  0,  1},
	{"wake-of-gods.mapObjects", "zsphnx10",             "zsphnx10",             1,  1,  2},
	{"wake-of-gods.mapObjects", "zsphnx13",             "zsphnx13",             0,  1,  2},
	{"wake-of-gods.mapObjects", "corefountainOfFortune","fountainOfFortune",    1,  2,  3},
	{"wake-of-gods.mapObjects", "valhallasFountain",    "valhallasFountain",    0,  1,  2},
}

-- Tier index: small=4, medium=5, large=6 in each PLACEMENT_LIST entry
local TIER_IDX = {small = 4, medium = 5, large = 6}

local function getMapTier()
	local w = GAME:getMapWidth()
	local h = GAME:getMapHeight()
	if not w or not h then return "medium" end
	local area = w * h
	if area < (72 * 72)   then return "small"
	elseif area < (144*144) then return "medium"
	else                       return "large"
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
local function placeN(scope, typ, subtype, n, w, h, playerIdx)
	for i = 1, n do
		local x, y, z = randomTile(w, h)
		pcall(function()
			SERVER:spawnObject(scope, typ, subtype, x, y, z, playerIdx)
		end)
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

	local w    = GAME:getMapWidth()  or 144
	local h    = GAME:getMapHeight() or 144
	local tier = getMapTier()
	local tidx = TIER_IDX[tier]

	-- Guard: need at least a 22×22 map for the 10-tile border to work
	if w < 22 or h < 22 then return end

	-- Place all objects
	local total = 0
	for _, obj in ipairs(PLACEMENT_LIST) do
		local scope, typ, subtype, cnt = obj[1], obj[2], obj[3], obj[tidx]
		if cnt and cnt > 0 then
			placeN(scope, typ, subtype, cnt, w, h, playerIdx)
			total = total + cnt
		end
	end

	-- Notify player
	local InfoWindow = require("netpacks.InfoWindow")
	local iw = InfoWindow.new()
	iw:setPlayer(playerIdx)
	iw:addText("{WOG New Age — Auto-WoGification}\\n\\n"
	        .. "This map has been WoGified! " .. tostring(total) .. " WOG objects\\n"
	        .. "have been scattered across the " .. tier .. " map,\\n"
	        .. "including Artificers, Death Chambers, Power Stones,\\n"
	        .. "Special Chests, Arcane Towers, Magic Mushrooms,\\n"
	        .. "Sphinxes, Fountains, and more.")
	SERVER:commitPackage(iw)
end)
