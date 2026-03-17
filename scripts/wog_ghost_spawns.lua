-- wog_ghost_spawns.lua
-- WOG New Age — Some Level 3s → Ghosts (option 242)
--
-- On day 1, a fraction of neutral tier-3 creature dwellings on the
-- adventure map are replaced with WOG Ghost (wake-of-gods.creatures:ghost)
-- dwellings. This follows WOG 3.58f option 242's behavior of introducing
-- Ghost spawns into the world.
--
-- Replaces approx. 1 in 3 tier-3 neutral dwellings (those not belonging
-- to any town faction) with Ghost dwellings.
--
-- Obj::CREATURE_GENERATOR1 = 17  (adventure map non-town dwellings)

local TurnStarted         = require("events.TurnStarted")
local SetAvailableCreatures = require("netpacks.SetAvailableCreatures")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.ghostSpawnsEnabled   = C.ghostSpawnsEnabled ~= false
C.ghostSpawnFraction   = C.ghostSpawnFraction or 3   -- replace 1 in N tier-3 dwellings

local DWELLING_OBJ_TYPES = {17, 20, 32, 153}

-- Tier-3 creatures in vanilla H3 factions (base and upgrade):
-- These creature IDs are the tier-3 pairs from all 8 factions + Conflux
-- We identify tier-3 dwellings by checking creature level = 3.

local applied = false

wogGhostSpawnsSub = TurnStarted.subscribeAfter(EVENT_BUS, function(event)
	if not C.ghostSpawnsEnabled then return end

	local totalDay = GAME:getDate(0)
	if totalDay ~= 1 then return end
	if applied then return end
	applied = true

	local ghostId = GAME:getCreatureIdByIdentifier("wake-of-gods.creatures:ghost")
	if not ghostId or ghostId < 0 then return end

	local replaced = 0

	for _, objType in ipairs(DWELLING_OBJ_TYPES) do
		local ids = GAME:getMapObjectIds(objType)
		if ids then
			for _, dwellId in ipairs(ids) do
				local creatureId = GAME:getDwellingCreatureId(dwellId, 0)
				if creatureId and creatureId >= 0 then
					-- Check if this creature is tier-3 (level == 3 in VCMI)
					local creature = SERVICES:creatures():getByIndex(creatureId)
					if creature and creature:getLevel() == 3 then
						replaced = replaced + 1
						-- Replace every Nth tier-3 dwelling with ghost
						if replaced % (C.ghostSpawnFraction or 3) == 0 then
							local count = GAME:getDwellingCreatureCount(dwellId, 0) or 0
							local pack = SetAvailableCreatures.new()
							pack:setDwellingId(dwellId)
							pack:setCreature(0, ghostId, count)
							SERVER:commitPackage(pack)
						end
					end
				end
			end
		end
	end
end)
