-- wog_creature_relations.lua
-- WOG New Age — Creature Relationships (option 47)
-- ERM script47 by Matthew Charlap, v1.3.1
--
-- ═══════════════════════════════════════════════════════════════════════════════
-- HATE MECHANIC (ERM FU13522 / FU13525):
--   Each day, if BOTH sides of a hate pair are in the SAME hero's army,
--   there is a chance of intra-army conflict. Chance formula:
--     base = 14 - (2 × Diplomacy_level)
--     multiplier = max(1, |negative_morale| + 1)  [positive morale = multiplier 1]
--     chance% = base × multiplier
--   If conflict triggers:
--     Each faction loses = floor(opposing_faction_total_HP × (10 - luck_level) / 100)
--     Minimum: 1 creature lost from each side (unless faction has < 14 total HP)
--   Applied daily via PlayerGotTurn for human players only (ERM checks AI ownership).
--
-- ALLIED MECHANIC (ERM FU13526 / FU13527):
--   Allied creatures have a daily chance to upgrade one creature to its next tier.
--   Chance = min(25%, 5 × ratio_of_supporting_faction_HP / upgradable_HP)
--   Upgrade: Mage→Archmage, Monk→Zealot, Archer→Marksman, Elf→Grand Elf,
--            Griffin→Royal Griffin, Efreet→Efreet Sultan, Fire Elem→Energy Elem.
--
--   Implementation: SetStackType netpack (equivalent to ERM HE:C) changes
--   creature type in a hero's army slot. Daily upgrade roll via PlayerGotTurn.
--   Additionally: +1 morale to battle stacks with allied pairs (BattleStarted)
--   and +5% synergy XP after won battle per allied pair (BattleEnded).
-- ═══════════════════════════════════════════════════════════════════════════════
--
-- VCMI creature indices verified from fcmi/config/creatures/*.json:
-- Castle:     pikeman=0, halberdier=1, archer=2, marksman=3, griffin=4, royalGriffin=5,
--             swordsman=6, crusader=7, monk=8, zealot=9, cavalier=10, champion=11,
--             angel=12, archangel=13
-- Rampart:    centaur=14, centaurCaptain=15, woodElf=18, grandElf=19,
--             greenDragon=26, goldDragon=27
-- Tower:      gremlin=28, mage=34, archMage=35, genie=36, masterGenie=37
-- Inferno:    imp=42, familiar=43, efreet=52, efreetSultan=53, devil=54, archDevil=55
-- Necropolis: lich=64, powerLich=65, blackKnight=66, dreadKnight=67,
--             boneDragon=68, ghostDragon=69
-- Dungeon:    blackDragon=83
-- Stronghold: orc=88, orcChieftain=89
-- Fortress:   gorgon=102, mightyGorgon=103
-- Conflux:    airElemental=112, fireElemental=114, pixie=118, sprite=119
-- Neutral:    rustDragon=135

local BattleStarted     = require("events.BattleStarted")
local BattleEnded       = require("events.BattleEnded")
local PlayerGotTurn     = require("events.PlayerGotTurn")
local SetHeroExperience = require("netpacks.SetHeroExperience")
local SetStackEffect    = require("netpacks.SetStackEffect")
local ChangeStackCount  = require("netpacks.ChangeStackCount")
local SetStackType      = require("netpacks.SetStackType")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.creatureRelationsEnabled = C.creatureRelationsEnabled ~= false

-- Post-battle synergy XP bonus: configurable % extra per active relationship
local SYNERGY_BONUS_PCT = C.synergyBonusPct or 5

-- ═══════════════════════════════════════════════════════════════════════════════
-- HATE PAIRS — from ERM script47 FU13521 calls to FU13522
-- Each entry: {sideA = {creatureIds...}, sideB = {creatureIds...}, desc}
-- Conflict fires when any creature from sideA AND any creature from sideB
-- are in the same hero's army.
-- ═══════════════════════════════════════════════════════════════════════════════
local HATE_PAIRS = {
	-- Angel/Archangel vs Devil/ArchDevil
	{
		sideA = {12, 13},    -- angel, archangel
		sideB = {54, 55},    -- devil, archDevil
		desc  = "Angels vs Devils",
	},
	-- Titan vs Black Dragon
	{
		sideA = {41},        -- titan
		sideB = {83},        -- blackDragon
		desc  = "Titan vs Black Dragon",
	},
	-- Genie/Master Genie vs Efreet/Efreet Sultan
	{
		sideA = {36, 37},    -- genie, masterGenie
		sideB = {52, 53},    -- efreet, efreetSultan
		desc  = "Genies vs Efreets",
	},
	-- Orc/Orc Chieftain vs Wood Elf/Grand Elf
	-- (ERM also includes boar riders =140 and pegasi =20,21, but those are less central)
	{
		sideA = {88, 89},    -- orc, orcChieftain
		sideB = {18, 19},    -- woodElf, grandElf
		desc  = "Orcs vs Wood Elves",
	},
	-- Pixie/Sprite vs Imp/Familiar
	{
		sideA = {118, 119},  -- pixie, sprite
		sideB = {42, 43},    -- imp, familiar
		desc  = "Pixies vs Imps",
	},
	-- Life dragons (Rampart: greenDragon, goldDragon) vs Death dragons (Necropolis: boneDragon, ghostDragon)
	{
		sideA = {26, 27},    -- greenDragon, goldDragon
		sideB = {68, 69},    -- boneDragon, ghostDragon
		desc  = "Life Dragons vs Death Dragons",
	},
	-- Rust Dragon (Conflux) vs Gorgon/Mighty Gorgon (Fortress)
	{
		sideA = {135},       -- rustDragon
		sideB = {102, 103},  -- gorgon, mightyGorgon
		desc  = "Rust Dragon vs Gorgons",
	},
	-- Cavalier/Champion vs Black Knight/Dread Knight
	{
		sideA = {10, 11},    -- cavalier, champion
		sideB = {66, 67},    -- blackKnight, dreadKnight
		desc  = "Cavaliers vs Black Knights",
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- ALLIED PAIRS — from ERM script47 FU13521 calls to FU13526
-- Each entry: {upgradeA = {from, to}, upgradeB = {from, to}, supporters = {ids...}}
-- ═══════════════════════════════════════════════════════════════════════════════
-- UPGRADE GROUPS: ERM FU13526/FU13527 — daily % chance to upgrade one creature
-- to next tier when both sides of an allied pair are in the same hero's army.
-- Chance = min(25, floor(5 * supporter_totalHP / upgradable_totalHP))
-- Each group has upgradeA (one side) and upgradeB (other side), plus supporter IDs.
local ALLIED_UPGRADE_GROUPS = {
	-- Mage/Monk: enchanter(136) supports mage→archmage; warZealot(169) supports monk→zealot
	{
		upgradeA = {from = 34, to = 35},  -- mage→archMage
		upgradeB = {from = 8,  to = 9},   -- monk→zealot
		supportersA = {136},              -- enchanter supports mage side
		supportersB = {169},              -- warZealot supports monk side (WOG creature)
		desc = "Mage/Monk alliance",
	},
	-- Archer/Elf: sharpshooter(137) supports both
	{
		upgradeA = {from = 2,  to = 3},   -- archer→marksman
		upgradeB = {from = 18, to = 19},  -- woodElf→grandElf
		supportersA = {137},              -- sharpshooter
		supportersB = {137},              -- sharpshooter
		desc = "Archer/Elf alliance",
	},
	-- Griffin/Roc: firebird(130)/phoenix(131) support both
	{
		upgradeA = {from = 4,  to = 5},   -- griffin→royalGriffin
		upgradeB = {from = 92, to = 93},  -- roc→thunderbird
		supportersA = {130, 131},         -- firebird, phoenix
		supportersB = {130, 131},         -- firebird, phoenix
		desc = "Griffin/Roc alliance",
	},
	-- Efreet/Fire Elemental: fireMessenger(164) supports both
	{
		upgradeA = {from = 52,  to = 53},  -- efreet→efreetSultan
		upgradeB = {from = 114, to = 129}, -- fireElemental→energyElemental
		supportersA = {164},              -- fireMessenger (WOG creature)
		supportersB = {164},              -- fireMessenger (WOG creature)
		desc = "Efreet/Fire Elemental alliance",
	},
}

-- For morale and XP purposes, allied pairs are expressed as flat {creatureIdA, creatureIdB}
-- This includes all pairs from upgrade groups plus cross-type pairs.
local ALLIED_PAIRS = {
	-- Mage/Monk synergy (all creature types that are allies)
	{34, 8,  "Mage/Monk synergy"},         -- mage and monk together
	{34, 35, "Mage/ArchMage pair"},         -- both mage types
	{8,  9,  "Monk/Zealot pair"},           -- both monk types
	-- Archers/Elves
	{2,  18, "Archer/Elf alliance"},        -- archer and woodElf together
	{2,  3,  "Archer/Marksman pair"},       -- both archer types
	{18, 19, "Elf/Grand Elf pair"},         -- both elf types
	-- Griffins/Rocs
	{4,  92, "Griffin/Roc alliance"},       -- griffin and roc together
	{4,  5,  "Griffin/Royal Griffin pair"}, -- both griffin types
	{92, 93, "Roc/Thunderbird pair"},       -- both roc types
	-- Efreets/Fire Elementals
	{52, 114, "Efreet/Fire Elemental alliance"},
	{52, 53,  "Efreet/Sultan pair"},        -- both efreet types
	{114, 112, "Fire/Air Elemental pair"},  -- elemental synergy
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- Build fast lookup sets for hate detection
-- hateSideA[creatureId] = list of pair indices where creature is on sideA
-- hateSideB[creatureId] = list of pair indices where creature is on sideB
-- ═══════════════════════════════════════════════════════════════════════════════
local hateSideA = {}
local hateSideB = {}
for pairIdx, pair in ipairs(HATE_PAIRS) do
	for _, id in ipairs(pair.sideA) do
		hateSideA[id] = hateSideA[id] or {}
		table.insert(hateSideA[id], pairIdx)
	end
	for _, id in ipairs(pair.sideB) do
		hateSideB[id] = hateSideB[id] or {}
		table.insert(hateSideB[id], pairIdx)
	end
end

-- Per-battle tracking: hero -> set of creature IDs in their army
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

-- BonusType constants (from VCMI BonusEnum.h ordinal positions)
local BONUS_MORALE = 4  -- BonusType::MORALE

-- Deterministic daily hash for hate conflict roll (avoids global RNG mutation)
-- Returns a value 1..100
local function dailyHash(heroId, day)
	local h = heroId * 1000003 + day * 48271 + 12345
	h = h % 2147483647
	return (h % 100) + 1
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- HATE DAILY CONFLICT — fires each day for human-owned heroes (PlayerGotTurn)
-- ERM: !?TM13 → DO13520 → FU13521 → FU13522 → FU13525 → FU13524
-- ═══════════════════════════════════════════════════════════════════════════════
local HATE_CONFLICT_BASE   = C.hateConflictBase    or 14
local HATE_DIPLOMACY_FACTOR = C.hateDiplomacyFactor or 2
local HATE_LOSS_PCT        = C.hateLossPct          or 10

local SKILL_DIPLOMACY = (C.SKILL and C.SKILL.DIPLOMACY) or 4
local SKILL_LUCK      = (C.SKILL and C.SKILL.LUCK)      or 9

wogCreatureRelationsHateSub = PlayerGotTurn.subscribeAfter(EVENT_BUS, function(event)
	if not C.creatureRelationsEnabled then return end

	-- ERM only applies hatred for human-owned heroes
	local playerIdx = event:getPlayer()
	if not GAME:isPlayerHuman(playerIdx) then return end

	local heroIds = GAME:getPlayerHeroes(playerIdx)
	if not heroIds then return end

	local totalDay = GAME:getDate(0)

	for _, heroId in ipairs(heroIds) do
		local hero = GAME:getHero(heroId)
		if hero then
			-- Get hero army creature set
			local armyCreatures = {}
			local slotData = {}  -- slot -> {creatureId, count, hp}
			for slot = 0, 6 do
				local stack = hero:getStack(slot)
				if stack then
					local creatureType = stack:getType()
					local count = stack:getCount()
					if creatureType and count and count > 0 then
						local idx = creatureType:getIndex()
						if idx ~= nil then
							armyCreatures[idx] = true
							local hp = 1
							local okHp
							okHp, hp = pcall(function() return creatureType:getBaseHitPoints() end)
							if not okHp then hp = 1 end
							hp = (hp and hp > 0) and hp or 1
							slotData[slot] = {id = idx, count = count, hp = hp}
						end
					end
				end
			end

			-- Check each hate pair
			for pairIdx, pair in ipairs(HATE_PAIRS) do
				-- Determine if sideA and sideB both present in army
				local hasSideA = false
				local hasSideB = false
				for _, id in ipairs(pair.sideA) do
					if armyCreatures[id] then hasSideA = true; break end
				end
				for _, id in ipairs(pair.sideB) do
					if armyCreatures[id] then hasSideB = true; break end
				end

				if hasSideA and hasSideB then
					-- ERM FU13525: Calculate conflict chance
					local diplomacy = hero:getSecSkillLevel(SKILL_DIPLOMACY) or 0
					local morale    = 0
					local okMorale
					okMorale, morale = pcall(function()
						-- getMorale() returns current morale modifier
						return hero:getMorale()
					end)
					if not okMorale then morale = 0 end

					-- If morale > 0, multiplier = 1 (no amplification from good morale)
					-- If morale <= 0, multiplier = |morale| + 1
					local moraleMultiplier
					if morale > 0 then
						moraleMultiplier = 1
					else
						moraleMultiplier = math.abs(morale) + 1
					end

					local chanceBase = HATE_CONFLICT_BASE - HATE_DIPLOMACY_FACTOR * diplomacy
					if chanceBase < 1 then chanceBase = 1 end
					local chance = chanceBase * moraleMultiplier
					if chance > 80 then chance = 80 end  -- cap at 80%

					-- Deterministic roll using heroId + day + pairIdx
					local roll = dailyHash(heroId * 100 + pairIdx, totalDay)
					if roll <= chance then
						-- Conflict! Calculate losses.
						-- luck level reduces loss percentage (ERM: 10-luck %)
						local luck = hero:getSecSkillLevel(SKILL_LUCK) or 0
						local lossPct = HATE_LOSS_PCT - luck
						if lossPct < 1 then lossPct = 1 end

						-- Collect sideA stacks and sideB stacks in this army
						local sideASlots = {}
						local sideBSlots = {}
						local sideAHP = 0
						local sideBHP = 0

						for slot, data in pairs(slotData) do
							local onA = false
							local onB = false
							for _, id in ipairs(pair.sideA) do
								if data.id == id then onA = true; break end
							end
							for _, id in ipairs(pair.sideB) do
								if data.id == id then onB = true; break end
							end
							if onA then
								table.insert(sideASlots, slot)
								sideAHP = sideAHP + data.count * data.hp
							end
							if onB then
								table.insert(sideBSlots, slot)
								sideBHP = sideBHP + data.count * data.hp
							end
						end

						-- SideA loses based on sideB's total HP
						-- SideB loses based on sideA's total HP
						local sideALoss = math.floor(sideBHP * lossPct / 100)
						local sideBLoss = math.floor(sideAHP * lossPct / 100)

						-- Distribute losses across stacks (take from first matching slot)
						-- ChangeStackCount uses setArmyId(heroId), setSlot, setCount(newAbsCount), setMode(true)
						local function applyLossToSlots(slots, totalLoss)
							local remaining = totalLoss
							for _, slot in ipairs(slots) do
								local data = slotData[slot]
								if data and remaining > 0 then
									local killHp = data.hp
									if killHp < 1 then killHp = 1 end
									local kills = math.floor(remaining / killHp)
									if kills < 1 then kills = 1 end
									if kills > data.count then kills = data.count end
									-- Only kill if stack has more than ERM's threshold (14 total HP)
									if data.count * data.hp > 14 then
										local newCount = data.count - kills
										if newCount < 0 then newCount = 0 end
										local pack = ChangeStackCount.new()
										pack:setArmyId(heroId)
										pack:setSlot(slot)
										pack:setCount(newCount)
										pack:setMode(true)  -- absolute mode
										SERVER:commitPackage(pack)
										-- Update local tracking
										local actualKills = data.count - newCount
										data.count = newCount
										remaining = remaining - actualKills * killHp
									end
								end
							end
						end

						applyLossToSlots(sideASlots, sideALoss)
						applyLossToSlots(sideBSlots, sideBLoss)
					end
				end
			end
		end
	end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- ALLIED DAILY UPGRADE — ERM FU13526/FU13527: daily % chance to upgrade creature
-- Fires each day for human-owned heroes via PlayerGotTurn.
-- Uses SetStackType netpack (equivalent to ERM HE:C).
-- ═══════════════════════════════════════════════════════════════════════════════
wogCreatureRelationsUpgradeSub = PlayerGotTurn.subscribeAfter(EVENT_BUS, function(event)
	if not C.creatureRelationsEnabled then return end

	local playerIdx = event:getPlayer()
	if not GAME:isPlayerHuman(playerIdx) then return end

	local heroIds = GAME:getPlayerHeroes(playerIdx)
	if not heroIds then return end

	local totalDay = GAME:getDate(0)

	for _, heroId in ipairs(heroIds) do
		local hero = GAME:getHero(heroId)
		if hero then
			-- Collect army data: slot -> {id, count, hp}
			local armyCreatures = {}
			local slotData = {}
			for slot = 0, 6 do
				local stack = hero:getStack(slot)
				if stack then
					local creatureType = stack:getType()
					local count = stack:getCount()
					if creatureType and count and count > 0 then
						local idx = creatureType:getIndex()
						if idx ~= nil then
							armyCreatures[idx] = true
							local hp = 1
							local okHp
							okHp, hp = pcall(function() return creatureType:getBaseHitPoints() end)
							if not okHp then hp = 1 end
							hp = (hp and hp > 0) and hp or 1
							slotData[slot] = {id = idx, count = count, hp = hp}
						end
					end
				end
			end

			-- Check each upgrade group
			for groupIdx, group in ipairs(ALLIED_UPGRADE_GROUPS) do
				-- Check if both sides have creatures present
				local hasUpgradeA = armyCreatures[group.upgradeA.from] or false
				local hasUpgradeB = armyCreatures[group.upgradeB.from] or false
				local hasSupportA = false
				local hasSupportB = false
				for _, sid in ipairs(group.supportersA) do
					if armyCreatures[sid] then hasSupportA = true; break end
				end
				for _, sid in ipairs(group.supportersB) do
					if armyCreatures[sid] then hasSupportB = true; break end
				end

				-- Upgrade sideA (e.g. mage→archMage) if sideB supporters are present
				if hasUpgradeA and (hasSupportB or armyCreatures[group.upgradeB.from] or armyCreatures[group.upgradeB.to]) then
					-- Calculate supporter HP total (sideB creatures + supporters)
					local supportHP = 0
					local upgradableHP = 0
					for slot, data in pairs(slotData) do
						if data.id == group.upgradeA.from then
							upgradableHP = upgradableHP + data.count * data.hp
						end
						-- Supporters for sideA upgrade: sideB creatures and their supporters
						if data.id == group.upgradeB.from or data.id == group.upgradeB.to then
							supportHP = supportHP + data.count * data.hp
						end
						for _, sid in ipairs(group.supportersA) do
							if data.id == sid then
								supportHP = supportHP + data.count * data.hp
								break
							end
						end
					end

					if upgradableHP > 0 then
						local chance = math.min(25, math.floor(5 * supportHP / upgradableHP))
						local roll = dailyHash(heroId * 1000 + groupIdx * 10, totalDay)
						if roll <= chance then
							-- Upgrade one creature from upgradeA.from to upgradeA.to
							-- Find the first slot with upgradeA.from
							for slot, data in pairs(slotData) do
								if data.id == group.upgradeA.from then
									local pack = SetStackType.new()
									pack:setArmyId(heroId)
									pack:setSlot(slot)
									pack:setCreatureId(group.upgradeA.to)
									SERVER:commitPackage(pack)
									-- Update local tracking
									data.id = group.upgradeA.to
									armyCreatures[group.upgradeA.to] = true
									break
								end
							end
						end
					end
				end

				-- Upgrade sideB (e.g. monk→zealot) if sideA supporters are present
				if hasUpgradeB and (hasSupportA or armyCreatures[group.upgradeA.from] or armyCreatures[group.upgradeA.to]) then
					local supportHP = 0
					local upgradableHP = 0
					for slot, data in pairs(slotData) do
						if data.id == group.upgradeB.from then
							upgradableHP = upgradableHP + data.count * data.hp
						end
						if data.id == group.upgradeA.from or data.id == group.upgradeA.to then
							supportHP = supportHP + data.count * data.hp
						end
						for _, sid in ipairs(group.supportersB) do
							if data.id == sid then
								supportHP = supportHP + data.count * data.hp
								break
							end
						end
					end

					if upgradableHP > 0 then
						local chance = math.min(25, math.floor(5 * supportHP / upgradableHP))
						local roll = dailyHash(heroId * 1000 + groupIdx * 10 + 1, totalDay)
						if roll <= chance then
							for slot, data in pairs(slotData) do
								if data.id == group.upgradeB.from then
									local pack = SetStackType.new()
									pack:setArmyId(heroId)
									pack:setSlot(slot)
									pack:setCreatureId(group.upgradeB.to)
									SERVER:commitPackage(pack)
									data.id = group.upgradeB.to
									armyCreatures[group.upgradeB.to] = true
									break
								end
							end
						end
					end
				end
			end
		end
	end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- BATTLE START — capture army composition, apply +1 morale to allied stacks
-- ═══════════════════════════════════════════════════════════════════════════════
wogCreatureRelationsBattleStartSub = BattleStarted.subscribeAfter(EVENT_BUS, function(event)
	if not C.creatureRelationsEnabled then return end

	local attackerHeroId = event:getAttackerHeroId()
	local defenderHeroId = event:getDefenderHeroId()
	local battleId = event:getBattleId()

	local key = battleKey(attackerHeroId, defenderHeroId)

	local attackerCreatures = getHeroCreatureSet(attackerHeroId)
	local defenderCreatures = getHeroCreatureSet(defenderHeroId)

	C.battleArmyCreatures[key] = {
		attacker = attackerCreatures,
		defender = defenderCreatures,
	}

	-- Apply +1 morale to battle stacks that have allied pairs in their army
	if battleId < 0 then return end

	local stacks = GAME:getBattleStacks(battleId)
	if not stacks then return end

	local sse = SetStackEffect.new()
	sse:setBattleId(battleId)
	local anyBonus = false

	for _, stack in ipairs(stacks) do
		local side = stack.side       -- 0=attacker, 1=defender
		local armySet = (side == 0) and attackerCreatures or defenderCreatures

		-- Check if this stack's creature type has an allied pair in the same army
		local creatureId = stack.creatureId
		for _, pair in ipairs(ALLIED_PAIRS) do
			if (pair[1] == creatureId or pair[2] == creatureId) then
				local partnerId = (pair[1] == creatureId) and pair[2] or pair[1]
				if armySet[partnerId] then
					sse:addBonusToStack(stack.unitId, BONUS_MORALE, 1)
					anyBonus = true
					break
				end
			end
		end
	end

	if anyBonus then
		SERVER:commitPackage(sse)
	end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- BATTLE END — award synergy XP based on army composition
-- The daily upgrade mechanic (ERM FU13527) is now implemented above via
-- SetStackType netpack in the wogCreatureRelationsUpgradeSub handler.
-- This handler continues to award bonus synergy XP after won battles.
-- ═══════════════════════════════════════════════════════════════════════════════
wogCreatureRelationsSub = BattleEnded.subscribeAfter(EVENT_BUS, function(event)
	if not C.creatureRelationsEnabled then return end

	-- Synergy XP only for real concluded battles (NORMAL=0)
	if event:getBattleResult() ~= 0 then return end

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
