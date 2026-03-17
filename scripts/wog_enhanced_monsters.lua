-- wog_enhanced_monsters.lua
-- WOG New Age — Enhanced Monsters (option 50)
--
-- Wandering monsters on the adventure map behave differently than vanilla:
--   1. Weekly Growth: neutral stacks that have not been defeated grow by
--      a configurable % each week (WOG default: +10% per week, capped).
--
-- Additional WOG behaviors (joining thresholds, monster abilities) are handled
-- by VCMI internally or require per-stack event hooks not yet exposed.
--
-- Implementation:
--   - On each weekly TurnStarted (game day divisible by 7), iterate all
--     Obj::MONSTER (type group 54) objects still on the map and increase
--     their stack count by C.monsterWeeklyGrowthPct percent.
--   - Stacks that have been defeated are no longer on the map (getMonsterCount
--     returns nil); they are safely skipped.
--   - A maximum cap (C.monsterMaxMultiplier × original day-1 count) prevents
--     stacks from growing indefinitely. We track original counts in a table.

local TurnStarted      = require("events.TurnStarted")
local ChangeStackCount = require("netpacks.ChangeStackCount")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.enhancedMonstersEnabled  = C.enhancedMonstersEnabled ~= false
C.monsterWeeklyGrowthPct   = C.monsterWeeklyGrowthPct or 10   -- % stack growth per week
C.monsterMaxMultiplier     = C.monsterMaxMultiplier or 3       -- max multiplier vs day-1 count

local OBJ_MONSTER = 54

-- Remember initial counts from day 1 (before option 57 scaling may have run)
-- We record them on the first TurnStarted (day 1), AFTER neutralUnits scaling.
local initialCounts = nil  -- table: objectId → day-1 count (after scaling)

local function recordInitialCounts()
	initialCounts = {}
	local monsterIds = GAME:getMapObjectIds(OBJ_MONSTER)
	if not monsterIds then return end
	for i = 1, #monsterIds do
		local objectId = monsterIds[i]
		local count = GAME:getMonsterCount(objectId)
		if count and count > 0 then
			initialCounts[objectId] = count
		end
	end
end

wogEnhancedMonstersSub = TurnStarted.subscribeAfter(EVENT_BUS, function(event)
	if not C.enhancedMonstersEnabled then return end

	local totalDay = GAME:getDate(0)

	-- Day 1: record initial stack counts (baseline for cap calculations)
	if totalDay == 1 then
		recordInitialCounts()
		return
	end

	-- Weekly growth fires on the first day of each new week (days 8, 15, 22, ...)
	-- VCMI: getDate(0) = total day count since start (1=day1, 8=week2day1, etc.)
	if (totalDay - 1) % 7 ~= 0 then return end
	if not initialCounts then return end

	local growthPct = C.monsterWeeklyGrowthPct or 10
	local maxMult   = C.monsterMaxMultiplier or 3

	local monsterIds = GAME:getMapObjectIds(OBJ_MONSTER)
	if not monsterIds then return end

	for i = 1, #monsterIds do
		local objectId = monsterIds[i]
		local currentCount = GAME:getMonsterCount(objectId)
		-- Nil means stack was defeated and no longer exists — skip
		if currentCount and currentCount > 0 then
			local baseCount = initialCounts[objectId] or currentCount
			local cap = math.floor(baseCount * maxMult)
			if currentCount < cap then
				local newCount = math.floor(currentCount * (100 + growthPct) / 100)
				if newCount > cap then newCount = cap end
				if newCount > currentCount then
					local pack = ChangeStackCount.new()
					pack:setArmyId(objectId)
					pack:setSlot(0)
					pack:setCount(newCount)
					pack:setMode(true)  -- absolute
					SERVER:commitPackage(pack)
				end
			end
		end
	end
end)
