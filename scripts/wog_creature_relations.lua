-- wog_creature_relations.lua
-- WOG New Age — Creature Relationships (option 47)
--
-- Some creatures have special relationships with others, granting
-- bonus XP when they fight together, plus future morale/luck effects.
--
-- Classic WOG relationships (from script47.erm):
--   Angels ally with Archons (Paladins) → +1 morale for whole army
--   Undead with Liches → morale synergy
--   Dwarves with Elves → +1 luck (forest kin)
--   Titans vs Black Dragons → mutual +1 attack
--   Pegasi with Cavaliers → speed synergy
--
-- VCMI current implementation:
--   BattleStarted: scan hero armies, build army creature ID sets
--   BattleEnded: if both sides had relationship creatures, award synergy XP
--   Synergy XP = 5% extra to winner for each active relationship found
--
-- Future: Apply morale/attack bonuses mid-battle when battle API allows.

local BattleStarted     = require("events.BattleStarted")
local BattleEnded       = require("events.BattleEnded")
local SetHeroExperience = require("netpacks.SetHeroExperience")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.creatureRelationsEnabled = C.creatureRelationsEnabled ~= false

-- Post-battle synergy XP bonus: 5% extra per active relationship
local SYNERGY_BONUS_PCT = 5

-- Creature relationships: {creatureIdA, creatureIdB, description}
-- Relationship triggers when BOTH creatures are in the SAME army
local ALLIED_PAIRS = {
	{2, 3, "Archer/Marksman synergy"},        -- both archer upgrades together
	{8, 9, "Paladin/Crusader alliance"},       -- Castle tier 5 together
	{14, 15, "Angel/Archangel holy bond"},     -- both angel types
	{21, 22, "Centaur kin"},                   -- both centaur types
	{27, 28, "Pegasi wings"},                  -- both pegasi types
	{29, 30, "Dendroid guardians"},            -- both dendroid types
	{42, 43, "Gremlin brotherhood"},           -- both gremlin types
	{56, 57, "Imp/Familiar bond"},             -- imp family
	{70, 71, "Skeleton warriors"},             -- both skeleton types
	{76, 77, "Vampire lords"},                 -- both vampire types
	{78, 79, "Lich dominion"},                 -- both lich types
	{84, 85, "Troglodyte tribe"},              -- both troglodyte types
}

-- Opposite-army hatred: {creatureIdA (attacker), creatureIdB (defender)}
-- When A's army and B's army oppose each other in battle
local HATE_PAIRS = {
	{14, 78, "Angels vs Liches"},    -- holy vs undead
	{15, 79, "Archangels vs Power Liches"},
	{50, 51, "Genie vs Genie Master vs Demon"},  -- Tower vs Inferno
}

-- Per-battle tracking: hero -> set of creature IDs in their army
-- Key: battleId (using attacker+defender hero combo as string key)
C.battleArmyCreatures = C.battleArmyCreatures or {}

local function getHeroCreatureSet(heroId)
	if heroId < 0 then return {} end
	local hero = GAME:getHero(heroId)
	if not hero then return {} end
	local creatures = {}
	for slot = 0, 6 do
		local stack = hero:getStack(slot)
		if stack then
			local creatureType = stack:getType()
			if creatureType then
				local creatureIdx = creatureType:getIndex()
				if creatureIdx ~= nil then
					creatures[creatureIdx] = true
				end
			end
		end
	end
	return creatures
end

local function countSynergyBonuses(armyCreatures)
	local count = 0
	for _, pair in ipairs(ALLIED_PAIRS) do
		if armyCreatures[pair[1]] and armyCreatures[pair[2]] then
			count = count + 1
		end
	end
	return count
end

-- Battle key for tracking: combine hero IDs
local function battleKey(attackerHeroId, defenderHeroId)
	return tostring(attackerHeroId) .. "_" .. tostring(defenderHeroId)
end

-- At battle start: capture army composition for later XP calculation
wogCreatureRelationsBattleStartSub = BattleStarted.subscribeAfter(EVENT_BUS, function(event)
	if not C.creatureRelationsEnabled then return end

	local attackerHeroId = event:getAttackerHeroId()
	local defenderHeroId = event:getDefenderHeroId()

	local key = battleKey(attackerHeroId, defenderHeroId)

	C.battleArmyCreatures[key] = {
		attacker = getHeroCreatureSet(attackerHeroId),
		defender = getHeroCreatureSet(defenderHeroId),
	}
end)

-- At battle end: award synergy XP based on army composition
wogCreatureRelationsSub = BattleEnded.subscribeAfter(EVENT_BUS, function(event)
	if not C.creatureRelationsEnabled then return end

	local exp = event:getExpAwarded()
	if exp <= 0 then return end

	local winnerHeroId = event:getWinnerHeroId()
	local loserHeroId  = event:getLoserHeroId()
	if winnerHeroId < 0 then return end

	-- Try both key orderings (attacker=winner or attacker=loser)
	local keyWinFirst  = battleKey(winnerHeroId, loserHeroId)
	local keyLoseFirst = battleKey(loserHeroId,  winnerHeroId)
	local battleData   = C.battleArmyCreatures[keyWinFirst]
	local winnerIsAttacker = (battleData ~= nil)
	if not battleData then
		battleData = C.battleArmyCreatures[keyLoseFirst]
	end

	-- Clean up stored data
	C.battleArmyCreatures[keyWinFirst]  = nil
	C.battleArmyCreatures[keyLoseFirst] = nil

	-- Count synergy bonuses in winner's army
	local winnerArmy = {}
	if battleData then
		winnerArmy = winnerIsAttacker and (battleData.attacker or {}) or (battleData.defender or {})
	end
	local synergyCount = countSynergyBonuses(winnerArmy)

	if synergyCount <= 0 then return end

	local bonus = math.floor(exp * SYNERGY_BONUS_PCT * synergyCount / 100)
	if bonus < 1 then return end

	local pack = SetHeroExperience.new()
	pack:setHeroId(winnerHeroId)
	pack:setValue(bonus)
	pack:setMode(false)
	SERVER:commitPackage(pack)
end)
