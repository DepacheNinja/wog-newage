-- wog_creature_relations.lua
-- WOG New Age — Creature Relationships (option 47)
--
-- Some creatures have special relationships with others:
--   Allied (same army): bonus XP to the winner for each active pair
--   Hated (opposing armies): +15% damage when attacker targets hated creature
--
-- Classic WOG relationships (from script47.erm):
--   Angels ally with Archons (Paladins) — holy bond
--   Undead with Liches — undead synergy
--   Dwarves with Elves — forest kin
--   Titans vs Black Dragons — mutual rivalry
--   Pegasi with Cavaliers — speed synergy
--   Angels/Archangels hate Liches/Power Liches — holy vs undead conflict
--   Tower genies hate Inferno demons
--
-- VCMI implementation:
--   BattleStarted: scan hero armies, build army creature ID sets
--   BattleEnded: award 5% synergy XP per active allied pair in winner's army
--   ApplyDamage: +15% damage when attacker is a hated creature type (hate pairs)

local BattleStarted     = require("events.BattleStarted")
local BattleEnded       = require("events.BattleEnded")
local ApplyDamage       = require("events.ApplyDamage")
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

-- Opposite-army hatred: {attackerCreatureId, targetCreatureId, description}
-- When attacker creature hits the target creature type, deal +HATE_BONUS_PCT damage.
-- Pairs are bidirectional — both {A,B} and {B,A} are handled.
local HATE_BONUS_PCT = 15  -- +15% damage on hate attacks

-- Build a fast lookup map: hatePairs[attackerCreatureId][targetCreatureId] = true
local hatePairDefinitions = {
	{14, 78},   -- Angel → Lich
	{15, 79},   -- Archangel → Power Lich
	{78, 14},   -- Lich → Angel
	{79, 15},   -- Power Lich → Archangel
	{50, 56},   -- Genie → Imp (Tower vs Inferno tier 1)
	{51, 57},   -- Master Genie → Familiar
	{56, 50},   -- Imp → Genie
	{57, 51},   -- Familiar → Master Genie
	{107, 110}, -- Behemoth → Dragon (Stronghold vs Dungeon)
	{108, 111}, -- Ancient Behemoth → Black Dragon
}

local hateLookup = {}
for _, pair in ipairs(hatePairDefinitions) do
	local a, b = pair[1], pair[2]
	hateLookup[a] = hateLookup[a] or {}
	hateLookup[a][b] = true
end

-- For backward compat, keep HATE_PAIRS for display
local HATE_PAIRS = hatePairDefinitions

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

-- ApplyDamage: +HATE_BONUS_PCT% damage when attacker is a hated creature of the target type
-- Uses the new getAttacker() and getCreatureId() FCMI API additions
wogCreatureHateSub = ApplyDamage.subscribeBefore(EVENT_BUS, function(event)
	if not C.creatureRelationsEnabled then return end

	local attacker = event:getAttacker()
	if not attacker then return end
	local target   = event:getTarget()
	if not target then return end

	local attackerCreatureId = attacker:getCreatureId()
	local targetCreatureId   = target:getCreatureId()
	if attackerCreatureId == nil or targetCreatureId == nil then return end

	-- Check if attacker hates this target type
	local attackerHates = hateLookup[attackerCreatureId]
	if not attackerHates then return end
	if not attackerHates[targetCreatureId] then return end

	-- Apply hate damage bonus: +HATE_BONUS_PCT% of current damage
	local current = event:getDamage()
	if current <= 0 then return end
	local bonus = math.floor(current * HATE_BONUS_PCT / 100)
	if bonus < 1 then return end
	event:setDamage(current + bonus)
end)
