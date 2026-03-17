-- wog_replace_dragon_fly.lua
-- WOG New Age — Replace Dragon Fly (option 165)
--
-- On day 1, replaces creature dwellings that contain Dragon Fly
-- (core:serpentFly) or Fire Dragon Fly (core:fireDragonFly) with
-- Wyvern (core:wyvern) dwellings. This follows the WOG 3.58f behavior
-- of substituting the Dragon Fly line with the Wyvern line in neutral
-- dwellings on the adventure map.
--
-- Obj::CREATURE_GENERATOR1 = 17  (non-town creature dwellings)
-- Obj::CREATURE_GENERATOR2 = 20  (horde dwellings)
-- Obj::CREATURE_GENERATOR3 = 32
-- Obj::CREATURE_GENERATOR4 = 153

local TurnStarted         = require("events.TurnStarted")
local SetAvailableCreatures = require("netpacks.SetAvailableCreatures")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.replaceDragonFlyEnabled = C.replaceDragonFlyEnabled ~= false

-- Obj type groups for creature dwellings (adventure map generators)
local DWELLING_OBJ_TYPES = {17, 20, 32, 153}

local applied = false

wogReplaceDragonFlySub = TurnStarted.subscribeAfter(EVENT_BUS, function(event)
	if not C.replaceDragonFlyEnabled then return end

	local totalDay = GAME:getDate(0)
	if totalDay ~= 1 then return end
	if applied then return end
	applied = true

	-- Resolve creature IDs dynamically (mod-safe)
	local serpentFlyId    = GAME:getCreatureIdByIdentifier("core:serpentFly")
	local fireDragonFlyId = GAME:getCreatureIdByIdentifier("core:fireDragonFly")
	local wyvernId        = GAME:getCreatureIdByIdentifier("core:wyvern")

	if not serpentFlyId or not wyvernId or serpentFlyId < 0 or wyvernId < 0 then return end

	for _, objType in ipairs(DWELLING_OBJ_TYPES) do
		local ids = GAME:getMapObjectIds(objType)
		if ids then
			for _, dwellId in ipairs(ids) do
				local creatureId = GAME:getDwellingCreatureId(dwellId, 0)
				if creatureId == serpentFlyId or creatureId == fireDragonFlyId then
					local count = GAME:getDwellingCreatureCount(dwellId, 0) or 0
					local pack = SetAvailableCreatures.new()
					pack:setDwellingId(dwellId)
					pack:setCreature(0, wyvernId, count)
					SERVER:commitPackage(pack)
				end
			end
		end
	end
end)
