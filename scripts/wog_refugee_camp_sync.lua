-- wog_refugee_camp_sync.lua
-- WOG New Age — Refugee Camp Sync (option 200)
--
-- At the start of each week (and on day 1), synchronizes all Refugee Camps
-- on the map so they all offer the same creature type. The first camp's
-- creature is used as the reference for all others. This prevents different
-- players from having camps with different creatures, making the feature
-- consistent across the map.
--
-- Classic WOG behavior: all refugee camps offer the same creature each week
-- (the one set by the map or randomized consistently for all players).
--
-- Obj::REFUGEE_CAMP = 78  (from EntityIdentifiers.h)
-- Refugee camps have one creature level (index 0).

local TurnStarted         = require("events.TurnStarted")
local SetAvailableCreatures = require("netpacks.SetAvailableCreatures")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.refugeeCampSyncEnabled = C.refugeeCampSyncEnabled ~= false

local REFUGEE_CAMP_OBJ_TYPE = 78  -- Obj::REFUGEE_CAMP

wogRefugeeCampSyncSub = TurnStarted.subscribeAfter(EVENT_BUS, function(event)
	if not C.refugeeCampSyncEnabled then return end

	-- Run at the start of week (day 1, 8, 15, 22, ...) — specifically day 1 of any week
	local totalDay = GAME:getDate(0)
	if (totalDay - 1) % 7 ~= 0 then return end

	-- Get all refugee camp object IDs
	local campIds = GAME:getMapObjectIds(REFUGEE_CAMP_OBJ_TYPE)
	if not campIds or #campIds < 2 then return end

	-- Read reference creature from first camp (level 0)
	local refCreatureId = GAME:getDwellingCreatureId(campIds[1], 0)
	local refCount      = GAME:getDwellingCreatureCount(campIds[1], 0)

	if not refCreatureId or refCreatureId < 0 then return end
	refCount = refCount or 0

	-- Sync all other camps to the same creature
	for i = 2, #campIds do
		local campId = campIds[i]
		local currentCreature = GAME:getDwellingCreatureId(campId, 0)
		-- Only update if different
		if currentCreature ~= refCreatureId then
			local pack = SetAvailableCreatures.new()
			pack:setDwellingId(campId)
			pack:setCreature(0, refCreatureId, refCount)
			SERVER:commitPackage(pack)
		end
	end
end)
