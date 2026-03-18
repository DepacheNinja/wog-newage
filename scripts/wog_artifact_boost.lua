-- wog_artifact_boost.lua
-- WOG New Age — Artifact Boost (option 2 / ERM script02)
--
-- ERM script02 v1.4 by Donald X. Vaccarino, updated by Hermann the Weird.
-- Classic WOG: once per week (day 1, week >= 2), heroes wearing certain weak
-- artifacts receive special benefits. Surcoat of Counterpoise doubles effects.
--
-- Implemented effects:
--   Art  63  Bird of Perception      → +6 Royal Griffins / week
--   Art 103  Pendant of Life         → +24 Sprites / week
--   Art 104  Pendant of Death        → +12 Zombies / week
--   Art  93  Orb of Vulnerability    → +(Wisdom+1) Archmages / week
--   Art  92  Sphere of Permanence    → +(Defense÷10+1) Mighty Gorgons / week
--   Art  56  Dead Man's Boots        → give another pair / week
--   Art 107  Pendant of Total Recall → +1000 XP / week
--   Art  65  Emblem of Cognizance    → +15 gold × total creature count / week
--   Art 101  Pendant of Second Sight → upgrade base shooters → upgraded form
--   Art 100  Pendant of Dispassion   → +1 Knowledge / week
--   Art 105  Pendant of Free Will    → Peasant→Rogue; Golem chain upgrades
--   Art  58  Surcoat of Counterpoise → doubles creature counts, XP, gold, Knowledge
--
-- Skipped (require dialog or unavailable APIs):
--   Art  16  Targ of Rampaging Ogre   (triggers combat)
--   Art  64  Stoic Watchman           (map reveal — no Lua API)
--   Art 102  Pendant of Holiness      (give random spell — no GiveHeroSpell API)
--   Art  59  Boots of Polarity        (trade boots for movement — needs dialog + movement API)
--   Art  57  Garniture of Interference (trade for magic skill — needs dialog + give-skill API)
--   Art  67  Diplomat's Ring          (double tier-1 + consume ring — needs player dialog)
--   Art 126  Orb of Inhibition        (modify creature flags — needs dialog + flag API)
--
-- VCMI creature IDs verified from fcmi/config/creatures/*.json:
--   Royal Griffin=5, Zombie=59, Archmage=35, Mighty Gorgon=103, Sprite=119
--   Shooter upgrade pairs: Archer(2)→Marksman(3), Wood Elf(18)→Grand Elf(19),
--     Gremlin(28)→Master Gremlin(29), Gog(44)→Magog(45),
--     Beholder(74)→Evil Eye(75), Orc(88)→Orc Chieftain(89),
--     Lizardman(100)→Lizard Warrior(101), Air Elemental(112)→Storm Elemental(127)
--   Golem chain: Stone Golem(32)→Iron Golem(33)→Gold Golem(116)→Diamond Golem(117)
--   Peasant(139)→Rogue(143)

local PlayerGotTurn     = require("events.PlayerGotTurn")
local SetPrimarySkill   = require("netpacks.SetPrimarySkill")
local SetHeroExperience = require("netpacks.SetHeroExperience")
local SetResources      = require("netpacks.SetResources")
local GiveHeroArtifact  = require("netpacks.GiveHeroArtifact")
local InsertNewStack    = require("netpacks.InsertNewStack")
local SetStackType      = require("netpacks.SetStackType")
local ChangeStackCount  = require("netpacks.ChangeStackCount")
local EraseHeroArtifact = require("netpacks.EraseHeroArtifact")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.artifactBoostEnabled = C.artifactBoostEnabled ~= false

-- ---------------------------------------------------------------------------
-- CONSTANTS
-- ---------------------------------------------------------------------------

local RES_GOLD = 6  -- EGameResID::GOLD

-- Artifact IDs — ERM IDs match VCMI numeric indices for H3+WOG artifacts
local ART_BIRD_OF_PERCEPTION   = 63
local ART_ORB_OF_VULNERABILITY = 93
local ART_SPHERE_OF_PERMANENCE = 92
local ART_PENDANT_OF_LIFE      = 103
local ART_PENDANT_OF_DEATH     = 104
local ART_DEAD_MANS_BOOTS      = 56
local ART_TOTAL_RECALL         = 107
local ART_EMBLEM_OF_COGNIZANCE = 65
local ART_SECOND_SIGHT         = 101
local ART_DISPASSION           = 100
local ART_FREE_WILL            = 105
local ART_SURCOAT              = 58

-- SecondarySkill: WISDOM = 7 (from lib/constants/EntityIdentifiers.h SecondarySkillBase::Type)
local SKILL_WISDOM = 7

-- Equipped artifact slots to scan (head=0..ring=12, misc5=18)
local EQUIPPED_SLOTS = {0,1,2,3,4,5,6,7,8,9,10,11,12,18}

-- Shooter upgrade pairs for Pendant of Second Sight (base → upgraded)
-- Source: ERM script02 HE:C1 calls; VCMI IDs verified from creature JSON files
local SHOOTER_UPGRADES = {
	{2,   3},    -- Archer       → Marksman
	{18,  19},   -- Wood Elf     → Grand Elf
	{28,  29},   -- Gremlin      → Master Gremlin
	{44,  45},   -- Gog          → Magog
	{74,  75},   -- Beholder     → Evil Eye
	{88,  89},   -- Orc          → Orc Chieftain
	{100, 101},  -- Lizardman    → Lizard Warrior
	{112, 127},  -- Air Elemental → Storm Elemental
}

-- Golem chain for Pendant of Free Will
-- Applied top-down to avoid re-upgrading the same stack twice in one pass.
-- ERM does C1 calls in this order: 116→117, 33→116, 32→33 (plus 116→117 again w/ Surcoat)
local GOLEM_CHAIN = {
	{116, 117},  -- Gold Golem   → Diamond Golem  (first, so Gold Golems from prev step aren't re-upgraded)
	{33,  116},  -- Iron Golem   → Gold Golem
	{32,  33},   -- Stone Golem  → Iron Golem
}

-- ---------------------------------------------------------------------------
-- HELPER: scan equipped slots and return the first matching slot index, or nil
-- ---------------------------------------------------------------------------
local function findArtifactSlot(hero, artId)
	for _, slot in ipairs(EQUIPPED_SLOTS) do
		local found = hero:getArtifactAtSlot(slot)
		if found == artId then
			return slot
		end
	end
	return nil
end

-- ---------------------------------------------------------------------------
-- HELPER: count how many copies of an artifact the hero wears
-- ---------------------------------------------------------------------------
local function countArtifact(hero, artId)
	local count = 0
	for _, slot in ipairs(EQUIPPED_SLOTS) do
		if hero:getArtifactAtSlot(slot) == artId then
			count = count + 1
		end
	end
	return count
end

-- ---------------------------------------------------------------------------
-- HELPER: give `count` creatures of type `creatureId` to the hero.
-- Adds to an existing stack of the same type, or uses an empty slot.
-- Returns true if placed, false if army is full.
-- ---------------------------------------------------------------------------
local function giveCreatures(heroId, hero, creatureId, count)
	-- Try to add to an existing stack of the same type first
	for slot = 0, 6 do
		local stack = hero:getStack(slot)
		if stack then
			local ct  = stack:getType()
			local cnt = stack:getCount()
			if ct and cnt and cnt > 0 and ct:getIndex() == creatureId then
				local pack = ChangeStackCount.new()
				pack:setArmyId(heroId)
				pack:setSlot(slot)
				pack:setCount(count)
				pack:setMode(false)  -- relative (add)
				SERVER:commitPackage(pack)
				return true
			end
		end
	end
	-- No existing stack — find an empty slot
	for slot = 0, 6 do
		local stack = hero:getStack(slot)
		local isEmpty = (not stack) or (not stack:getType()) or (stack:getCount() == 0)
		if isEmpty then
			local pack = InsertNewStack.new()
			pack:setArmyId(heroId)
			pack:setSlot(slot)
			pack:setCreatureId(creatureId)
			pack:setCount(count)
			SERVER:commitPackage(pack)
			return true
		end
	end
	return false  -- army is full
end

-- ---------------------------------------------------------------------------
-- HELPER: in each army slot, if creature type == fromId then upgrade to toId.
-- ---------------------------------------------------------------------------
local function upgradeAllStacks(heroId, hero, fromId, toId)
	for slot = 0, 6 do
		local stack = hero:getStack(slot)
		if stack then
			local ct  = stack:getType()
			local cnt = stack:getCount()
			if ct and cnt and cnt > 0 and ct:getIndex() == fromId then
				local pack = SetStackType.new()
				pack:setArmyId(heroId)
				pack:setSlot(slot)
				pack:setCreatureId(toId)
				SERVER:commitPackage(pack)
			end
		end
	end
end

-- ---------------------------------------------------------------------------
-- PLAYER GOT TURN: apply artifact boosts on day 1 of each week (week >= 2)
-- ---------------------------------------------------------------------------
wogArtifactBoostSub = PlayerGotTurn.subscribeAfter(EVENT_BUS, function(event)
	if not C.artifactBoostEnabled then return end

	-- Trigger only on day 1 of each week, skip week 1 (totalDay == 1)
	local dayOfWeek = GAME:getDate(1)
	if dayOfWeek ~= 1 then return end
	local totalDay = GAME:getDate(0)
	if totalDay == 1 then return end

	local playerIdx = event:getPlayer()
	local heroIds   = GAME:getPlayerHeroes(playerIdx)
	if not heroIds then return end

	for _, heroId in ipairs(heroIds) do
		local hero = GAME:getHero(heroId)
		if not hero then goto continue end

		-- Surcoat of Counterpoise: doubles creature counts, XP, gold, Knowledge
		local surcoatCount = countArtifact(hero, ART_SURCOAT)
		local mult = (surcoatCount > 0) and 2 or 1

		-- ------------------------------------------------------------------
		-- Bird of Perception (art 63): +6 Royal Griffins (×mult)
		-- ------------------------------------------------------------------
		if findArtifactSlot(hero, ART_BIRD_OF_PERCEPTION) then
			giveCreatures(heroId, hero, 5, 6 * mult)
		end

		-- ------------------------------------------------------------------
		-- Pendant of Life (art 103): +24 Sprites (×mult)
		-- ------------------------------------------------------------------
		if findArtifactSlot(hero, ART_PENDANT_OF_LIFE) then
			giveCreatures(heroId, hero, 119, 24 * mult)
		end

		-- ------------------------------------------------------------------
		-- Pendant of Death (art 104): +12 Zombies (×mult)
		-- ------------------------------------------------------------------
		if findArtifactSlot(hero, ART_PENDANT_OF_DEATH) then
			giveCreatures(heroId, hero, 59, 12 * mult)
		end

		-- ------------------------------------------------------------------
		-- Orb of Vulnerability (art 93): +(Wisdom+1) Archmages (×mult)
		-- ERM: wisdom level 0-3; ERM skill 7 = HE:S7 = Wisdom
		-- ------------------------------------------------------------------
		if findArtifactSlot(hero, ART_ORB_OF_VULNERABILITY) then
			local wisdom = hero:getSecSkillLevel(SKILL_WISDOM) or 0
			giveCreatures(heroId, hero, 35, (wisdom + 1) * mult)
		end

		-- ------------------------------------------------------------------
		-- Sphere of Permanence (art 92): +(Defense÷10+1) Mighty Gorgons (×mult)
		-- ------------------------------------------------------------------
		if findArtifactSlot(hero, ART_SPHERE_OF_PERMANENCE) then
			local def = hero:getDefense() or 0
			giveCreatures(heroId, hero, 103, (math.floor(def / 10) + 1) * mult)
		end

		-- ------------------------------------------------------------------
		-- Dead Man's Boots (art 56): give another pair (×mult: extra pair w/ Surcoat)
		-- ERM: always gives boots; with Surcoat gives 2 pairs total
		-- ------------------------------------------------------------------
		if findArtifactSlot(hero, ART_DEAD_MANS_BOOTS) then
			local pairsToGive = mult  -- 1 normally, 2 with Surcoat
			for _ = 1, pairsToGive do
				local pack = GiveHeroArtifact.new()
				pack:setHeroId(heroId)
				pack:setArtTypeId(ART_DEAD_MANS_BOOTS)
				pack:setSlot(-1)  -- FIRST_AVAILABLE
				SERVER:commitPackage(pack)
			end
		end

		-- ------------------------------------------------------------------
		-- Pendant of Total Recall (art 107): +1000 XP (×mult)
		-- ------------------------------------------------------------------
		if findArtifactSlot(hero, ART_TOTAL_RECALL) then
			local pack = SetHeroExperience.new()
			pack:setHeroId(heroId)
			pack:setValue(1000 * mult)
			pack:setMode(false)  -- relative (add)
			SERVER:commitPackage(pack)
		end

		-- ------------------------------------------------------------------
		-- Emblem of Cognizance (art 65): +15 gold × total creature count (×mult)
		-- ERM: 15 * mult gold per creature in all 7 slots combined
		-- ------------------------------------------------------------------
		if findArtifactSlot(hero, ART_EMBLEM_OF_COGNIZANCE) then
			local totalCreatures = 0
			for slot = 0, 6 do
				local stack = hero:getStack(slot)
				if stack then
					local cnt = stack:getCount()
					if cnt and cnt > 0 then
						totalCreatures = totalCreatures + cnt
					end
				end
			end
			local gold = 15 * mult * totalCreatures
			if gold > 0 then
				local pack = SetResources.new()
				pack:setPlayer(playerIdx)
				pack:setAbs(false)
				pack:setAmount(RES_GOLD, gold)
				SERVER:commitPackage(pack)
			end
		end

		-- ------------------------------------------------------------------
		-- Pendant of Second Sight (art 101): upgrade base shooters to upgraded form
		-- ERM: C1/from/to/d for each shooter pair — upgrades in hero's army slots
		-- ------------------------------------------------------------------
		if findArtifactSlot(hero, ART_SECOND_SIGHT) then
			for _, pair in ipairs(SHOOTER_UPGRADES) do
				upgradeAllStacks(heroId, hero, pair[1], pair[2])
			end
		end

		-- ------------------------------------------------------------------
		-- Pendant of Dispassion (art 100): +1 Knowledge (×mult → +2 w/ Surcoat)
		-- ERM: HE:Fd/d/d/dv631 where 4th param = knowledge delta = v631 (1 or 2)
		-- ------------------------------------------------------------------
		if findArtifactSlot(hero, ART_DISPASSION) then
			local pack = SetPrimarySkill.new()
			pack:setHeroId(heroId)
			pack:setSkill(3)          -- 3 = Knowledge
			pack:setValue(1 * mult)
			pack:setMode(false)       -- relative (add)
			SERVER:commitPackage(pack)
		end

		-- ------------------------------------------------------------------
		-- Pendant of Free Will (art 105): upgrade Peasants and Golem chain
		-- ERM order: 139→143 (Peasant→Rogue), then golem chain top-down
		-- With Surcoat: extra pass of 116→117 and 33→116 (newly created Gold Golems)
		-- ------------------------------------------------------------------
		if findArtifactSlot(hero, ART_FREE_WILL) then
			-- Peasant → Rogue
			upgradeAllStacks(heroId, hero, 139, 143)
			-- Golem chain: top-down to avoid double-upgrading in one pass
			for _, pair in ipairs(GOLEM_CHAIN) do
				upgradeAllStacks(heroId, hero, pair[1], pair[2])
			end
			-- Surcoat: ERM applies gold→diamond and iron→gold a second time
			if surcoatCount > 0 then
				upgradeAllStacks(heroId, hero, 116, 117)
				upgradeAllStacks(heroId, hero, 33,  116)
			end
		end

		::continue::
	end
end)
