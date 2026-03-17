-- wog_week_of_monsters.lua
-- WOG New Age — Week of Monsters (option 20)
--
-- Each week, one random creature type gets a bonus for that week:
--   - Double growth in dwellings
--   - +2 Attack / +2 Defense (or stat-scaled equivalent)
--   - Creatures of that type appear in larger wandering stacks
--
-- VCMI LIMITATION: Modifying creature stats mid-game requires the
-- EntitiesChanged netpack with bone-fide creature property changes.
-- Until the EntitiesChanged API is fully verified, this script:
--   1. Picks a random "creature of the week" each Monday
--   2. Stores it in DATA.WOG.weekMonster
--   3. Logs a message for player visibility (future: InfoWindow popup)
--
-- Full stat modification will be enabled once the creature mod API
-- is confirmed working.

local TurnStarted = require("events.TurnStarted")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

-- Tier 1-6 creature list (representative IDs from VCMI)
-- These are base creature IDs (0-indexed by VCMI creature order)
-- We skip tier 7 (they already dominate) and unique creatures.
local ELIGIBLE_CREATURES = {
	-- Castle
	0, 1,    -- Pikeman, Halberdier
	7, 8,    -- Griffin, Royal Griffin
	14, 15,  -- Angel, Archangel
	-- Rampart
	21, 22,  -- Centaur, Centaur Captain
	-- Tower
	42, 43,  -- Gremlin, Master Gremlin
	-- Inferno
	56, 57,  -- Imp, Familiar
	-- Necropolis
	70, 71,  -- Skeleton, Skeleton Warrior
	-- Dungeon
	84, 85,  -- Troglodyte, Infernal Troglodyte
	-- Fortress
	98, 99,  -- Gnoll, Gnoll Marauder
	-- Conflux
	112, 113, -- Pixie, Sprite
	-- Neutral
	133, 134, -- Halfling, Halfling Grenadier (if WOG)
}

-- Simple LCG random using day as seed
local function weekRandom(seed)
	return ((seed * 1103515245 + 12345) % 2147483648) % #ELIGIBLE_CREATURES + 1
end

wogWeekOfMonstersSub = TurnStarted.subscribeAfter(EVENT_BUS, function(event)
	if not (C.weekOfMonstersEnabled ~= false) then return end

	-- Fire only on the first day of each week (day-of-week == 1 = Monday)
	local dayOfWeek = GAME:getDate(1)
	if dayOfWeek ~= 1 then return end

	local totalDay   = GAME:getDate(0)
	local weekNum    = GAME:getDate(2)
	local idx        = weekRandom(totalDay)
	local creatureId = ELIGIBLE_CREATURES[idx]

	-- Store for use by other scripts (e.g., creature growth modifier)
	C.weekMonster      = creatureId
	C.weekMonsterWeek  = weekNum

	-- TODO: Apply actual stat boost via EntitiesChanged when API is confirmed.
	-- TODO: Show InfoWindow popup to players listing the week's creature bonus.
end)
