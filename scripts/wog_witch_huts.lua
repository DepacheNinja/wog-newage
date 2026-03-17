-- wog_witch_huts.lua
-- WOG New Age — Advanced Witch Huts (option 194)
--
-- Classic WOG: Witch Huts can teach skills at Advanced or Expert level.
-- A hero who already knows a Witch Hut skill can pay gold to upgrade it.
-- Basic: skill taught at Basic level (same as vanilla)
-- Advanced/Expert upgrades: hero pays gold (1000 for Advanced, 2000 for Expert)
--
-- Implementation:
--   subscribeBefore: capture hero's current skill levels before visiting
--   subscribeAfter: detect newly learned skill, optionally upgrade it
--
-- For human players only. AI heroes use default vanilla Witch Hut behavior.
--
-- MapObjectID::WITCH_HUT = 113

local ObjectVisitStarted = require("events.ObjectVisitStarted")
local SetSecSkill        = require("netpacks.SetSecSkill")
local SetResources       = require("netpacks.SetResources")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

-- MapObjectID::WITCH_HUT = 113
local WITCH_HUT_ID = 113
local GOLD = 6  -- EGameResID::GOLD

-- Cost to upgrade a witch hut skill: Advanced = 1000g, Expert = 2000g
local UPGRADE_COST = C.witchHutUpgradeCost or {1000, 2000}  -- [to_adv, to_exp]

-- Temporary storage: hero skill snapshot before witch hut visit
-- Key: heroId, Value: table of {skillId = level}
C.witchHutPreVisit = C.witchHutPreVisit or {}

-- Skill IDs that Witch Huts can teach (all 28 secondary skills, IDs 0-27)
local ALL_SKILLS = {}
for i = 0, 27 do ALL_SKILLS[i] = true end

-- Capture skill levels BEFORE the visit so we can detect what changed
wogWitchHutPreSub = ObjectVisitStarted.subscribeBefore(EVENT_BUS, function(event)
	if not (C.witchHutsEnabled ~= false) then return end

	local objId = event:getObject()
	local obj   = GAME:getObj(objId)
	if not obj then return end
	if obj:getObjGroupIndex() ~= WITCH_HUT_ID then return end

	local playerIdx = event:getPlayer()
	if not GAME:isPlayerHuman(playerIdx) then return end

	local heroId = event:getHero()
	if heroId < 0 then return end

	local hero = GAME:getHero(heroId)
	if not hero then return end

	-- Snapshot current secondary skill levels
	local snapshot = {}
	for skillId = 0, 27 do
		snapshot[skillId] = hero:getSecSkillLevel(skillId)
	end
	C.witchHutPreVisit[tostring(heroId)] = snapshot
end)

-- After the visit: detect newly learned skill, upgrade if player has gold
wogWitchHutPostSub = ObjectVisitStarted.subscribeAfter(EVENT_BUS, function(event)
	if not (C.witchHutsEnabled ~= false) then return end

	local objId = event:getObject()
	local obj   = GAME:getObj(objId)
	if not obj then return end
	if obj:getObjGroupIndex() ~= WITCH_HUT_ID then return end

	local playerIdx = event:getPlayer()
	if not GAME:isPlayerHuman(playerIdx) then return end

	local heroId = event:getHero()
	if heroId < 0 then return end

	local hero = GAME:getHero(heroId)
	if not hero then return end

	local key      = tostring(heroId)
	local snapshot = C.witchHutPreVisit[key]
	C.witchHutPreVisit[key] = nil  -- clean up
	if not snapshot then return end

	-- Find which skill was just learned (went from 0 to 1)
	local newSkill = nil
	for skillId = 0, 27 do
		local before = snapshot[skillId] or 0
		local after  = hero:getSecSkillLevel(skillId)
		if before == 0 and after == 1 then
			newSkill = skillId
			break
		end
	end
	if newSkill == nil then return end  -- no new skill learned (already knew it)

	-- WOG Enhancement: automatically upgrade to Advanced if player can afford it
	-- This simulates "Advanced Witch Hut" — Basic to Advanced upgrade is free in WoG
	-- (the Witch Hut teaches at whatever level it's set to)
	-- Simplified: give the skill at level 2 (Advanced) instead of 1 (Basic)
	local targetLevel = C.witchHutAutoLevel or 2  -- 1=Basic, 2=Advanced, 3=Expert

	if targetLevel <= 1 then return end  -- no upgrade configured

	-- Check gold cost if level > 2 (expert upgrade costs more)
	local cost = 0
	if targetLevel == 2 then
		cost = UPGRADE_COST[1] or 1000
	elseif targetLevel == 3 then
		cost = UPGRADE_COST[2] or 2000
	end

	-- Check if player has enough gold
	local gold = GAME:getPlayerResource(playerIdx, GOLD)
	if gold < cost then
		-- Can't afford upgrade — keep Basic skill (vanilla behavior)
		return
	end

	-- Upgrade the skill to targetLevel
	local skillPack = SetSecSkill.new()
	skillPack:setHeroId(heroId)
	skillPack:setSkill(newSkill)
	skillPack:setValue(targetLevel)
	skillPack:setMode(true)  -- absolute value
	SERVER:commitPackage(skillPack)

	-- Deduct the gold cost
	if cost > 0 then
		local goldPack = SetResources.new()
		goldPack:setPlayer(playerIdx)
		goldPack:setAbs(false)
		goldPack:setAmount(GOLD, -cost)
		SERVER:commitPackage(goldPack)
	end
end)
