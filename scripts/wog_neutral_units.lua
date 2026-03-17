-- wog_neutral_units.lua
-- WOG New Age — Neutral Units (option 57)
--
-- Controls the size of wandering monster stacks on the map.
-- WOG option 57 scales neutral stack sizes up or down based on difficulty.
-- Classic WOG default: +50% stack size for all neutral creatures on maps.
--
-- This fires once at game start (day 1, TurnStarted) to scale all
-- Obj::MONSTER (type group 54) objects to the configured size multiplier.
--
-- Uses FCMI APIs:
--   GAME:getMapObjectIds(54) — enumerate all wandering monster objects
--   GAME:getMonsterCreatureId(id) — get creature ID from monster object
--   GAME:getMonsterCount(id) — get current stack count
--   ChangeStackCount netpack — set absolute count on the monster object

local TurnStarted   = require("events.TurnStarted")
local ChangeStackCount = require("netpacks.ChangeStackCount")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.neutralUnitsEnabled  = C.neutralUnitsEnabled ~= false
C.neutralSizeMultPct   = C.neutralSizeMultPct or 150  -- percent of base count (150 = +50%)

-- Obj::MONSTER type group integer value (from EntityIdentifiers.h)
local OBJ_MONSTER = 54

-- Only run once at game start
local scaled = false

wogNeutralUnitsSub = TurnStarted.subscribeAfter(EVENT_BUS, function(event)
	if not C.neutralUnitsEnabled then return end
	if scaled then return end

	-- Only apply on day 1 (very first turn)
	local totalDay = GAME:getDate(0)
	if totalDay ~= 1 then return end

	scaled = true

	local monsterIds = GAME:getMapObjectIds(OBJ_MONSTER)
	if not monsterIds then return end

	local multPct = C.neutralSizeMultPct or 150

	for i = 1, #monsterIds do
		local objectId = monsterIds[i]
		local currentCount = GAME:getMonsterCount(objectId)
		if currentCount and currentCount > 0 then
			local newCount = math.floor(currentCount * multPct / 100)
			if newCount < 1 then newCount = 1 end
			if newCount ~= currentCount then
				local pack = ChangeStackCount.new()
				pack:setArmyId(objectId)
				pack:setSlot(0)
				pack:setCount(newCount)
				pack:setMode(true)  -- absolute mode
				SERVER:commitPackage(pack)
			end
		end
	end
end)
