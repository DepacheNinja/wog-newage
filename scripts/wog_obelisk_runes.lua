-- wog_obelisk_runes.lua
-- WOG New Age — Obelisk Runes (option 43)
--
-- ERM script43 v1.0 by Timothy Pulver.
-- Inscribes a random spell on every obelisk at game start.
-- When a human hero visits the obelisk, they learn that spell (added to spellbook).
-- When an AI hero visits, they receive +10 spell points instead.
-- Each obelisk has one fixed spell for the entire game.
-- Each hero can receive the reward at most once per obelisk.
--
-- ERM original: human gets a free CAST of the spell at Basic mastery.
-- VCMI approximation: hero LEARNS the spell (permanently added to spellbook).
-- This gives meaningful gameplay value even without a castSpellInBattle API.
--
-- Obelisk Obj type = 57 (Obj::OBELISK)

local TurnStarted        = require("events.TurnStarted")
local ObjectVisitStarted = require("events.ObjectVisitStarted")
local ChangeSpells       = require("netpacks.ChangeSpells")
local SetMana            = require("netpacks.SetMana")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.obeliskRunesEnabled = C.obeliskRunesEnabled ~= false

-- Persistent state
C.obeliskSpells  = C.obeliskSpells  or {}   -- [objId] = spellId
C.obeliskVisited = C.obeliskVisited or {}   -- [objId.."_"..heroId] = true

local OBJ_OBELISK = 57

-- ---------------------------------------------------------------------------
-- Pick a random spell from levels 1-5 (excluding -1/invalid)
-- ---------------------------------------------------------------------------
local function randomSpell()
	local candidates = {}
	for level = 1, 5 do
		local spells = GAME:getSpellsByLevel(level)
		if spells then
			for _, sid in ipairs(spells) do
				if sid >= 0 then
					table.insert(candidates, sid)
				end
			end
		end
	end
	if #candidates == 0 then return nil end
	return candidates[math.random(1, #candidates)]
end

-- ---------------------------------------------------------------------------
-- Ensure an obelisk has a spell assigned; return the spell ID
-- ---------------------------------------------------------------------------
local function getOrAssignSpell(objId)
	if C.obeliskSpells[objId] then
		return C.obeliskSpells[objId]
	end
	local spellId = randomSpell()
	if spellId then
		C.obeliskSpells[objId] = spellId
	end
	return spellId
end

-- ---------------------------------------------------------------------------
-- TurnStarted Day 1: pre-assign spells to all obelisks on the map
-- ---------------------------------------------------------------------------
wogObeliskTurnSub = TurnStarted.subscribeAfter(EVENT_BUS, function(event)
	if not C.obeliskRunesEnabled then return end
	if C.obeliskRunesAssigned    then return end

	local day   = GAME:getDate(0)
	local week  = GAME:getDate(1)
	local month = GAME:getDate(2)
	if day ~= 1 or week ~= 1 or month ~= 1 then
		C.obeliskRunesAssigned = true
		return
	end

	local playerIdx = event:getPlayer()
	if not GAME:isPlayerHuman(playerIdx) then return end

	C.obeliskRunesAssigned = true

	-- Assign a spell to every obelisk now so they're all consistent
	local obelisks = GAME:getMapObjectIds(OBJ_OBELISK)
	if obelisks then
		for _, objId in ipairs(obelisks) do
			getOrAssignSpell(objId)
		end
	end
end)

-- ---------------------------------------------------------------------------
-- ObjectVisitStarted: hero visits an obelisk
-- ---------------------------------------------------------------------------
wogObeliskVisitSub = ObjectVisitStarted.subscribeAfter(EVENT_BUS, function(event)
	if not C.obeliskRunesEnabled then return end

	local obj = event:getObject()
	if not obj then return end
	if obj:getObjectType() ~= OBJ_OBELISK then return end

	local objId     = obj:getObjectId()
	local heroId    = event:getHero()
	local playerIdx = event:getPlayer()
	if not heroId then return end

	-- Check if this hero already received this obelisk's reward
	local visitKey = tostring(objId) .. "_" .. tostring(heroId)
	if C.obeliskVisited[visitKey] then return end
	C.obeliskVisited[visitKey] = true

	-- Get or assign spell for this obelisk
	local spellId = getOrAssignSpell(objId)
	if not spellId then return end

	if GAME:isPlayerHuman(playerIdx) then
		-- Give hero the spell (learns it permanently)
		local pack = ChangeSpells.new()
		pack:setHeroId(heroId)
		pack:addSpell(spellId)
		pack:setLearn(true)
		SERVER:commitPackage(pack)
	else
		-- AI gets +10 spell points instead (ERM faithful: "10 bonus spell points")
		local pack = SetMana.new()
		pack:setHeroId(heroId)
		pack:setValue(10)
		pack:setMode(false)   -- relative (delta)
		SERVER:commitPackage(pack)
	end
end)
