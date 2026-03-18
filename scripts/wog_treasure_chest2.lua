-- wog_treasure_chest2.lua
-- WOG New Age — Special Treasure Chest (option 31 / ERM script31)
--
-- ERM script31 v1.3 by Timothy E. Pulver.
-- Classic WOG: a 5th chest type placed by map makers. When a hero picks
-- it up, one of three outcomes is chosen at random:
--
--   Roll 1   → Mine deed: a randomly chosen unowned mine is flagged for the player
--   Roll 2-3 → Tome of Knowledge: one non-Expert secondary skill raised to Expert
--   Roll 4-5 → Gold (300-900) + a random spell taught (simplified from scroll dialog)
--
-- ERM fallback chain:
--   Mine deed → no unowned mines?    → fall through to Tome
--   Tome      → <2 non-Expert skills? → fall through to Gold+Spell
--
-- VCMI simplifications vs ERM:
--   - Tome is applied immediately (ERM delays 1 week via Timer 28)
--   - One skill raised (ERM offers choice between two)
--   - Spell taught directly via ChangeSpells (ERM gives physical scroll +
--     dialog: keep scroll or convert to spell points)
--   - No map-view pan to mine location (requires client-side API)
--   - Gold amount: 300-900 (300 + rand(0-6)*100), matching ERM "S3 R6 *100"
--
-- Object removed automatically via JSON reward's "removeObject": true.
-- ERM trigger: OB101/5 (Obj::TREASURE_CHEST = 101, subtype 5).

local ObjectVisitStarted = require("events.ObjectVisitStarted")
local SetObjectProperty  = require("netpacks.SetObjectProperty")
local SetSecSkill        = require("netpacks.SetSecSkill")
local ChangeSpells       = require("netpacks.ChangeSpells")
local SetResources       = require("netpacks.SetResources")
local InfoWindow         = require("netpacks.InfoWindow")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.treasureChest2Enabled = C.treasureChest2Enabled ~= false

-- ---------------------------------------------------------------------------
-- CONSTANTS
-- ---------------------------------------------------------------------------

-- Obj::MINE type group integer (from EntityIdentifiers.h)
local OBJ_MINE = 53

-- Gold resource index
local RES_GOLD = 6

-- Number of standard H3 secondary skills (indices 0-27)
local MAX_SKILL = 27

-- ---------------------------------------------------------------------------
-- HELPER: show an InfoWindow message to a player.
-- ---------------------------------------------------------------------------
local function showMessage(playerIdx, msg)
	local w = InfoWindow.new()
	w:setMessage(msg)
	w:setPlayer(playerIdx)
	SERVER:commitPackage(w)
end

-- ---------------------------------------------------------------------------
-- HELPER: collect all unowned mine ObjectInstanceIDs from the map.
-- Uses GAME:getMapObjectIds(OBJ_MINE) + GAME:getObjectOwner(id).
-- Returns a table (possibly empty) of integer mine IDs.
-- ---------------------------------------------------------------------------
local function findUnownedMines()
	local allMines = GAME:getMapObjectIds(OBJ_MINE)
	if not allMines then return {} end
	local unowned = {}
	for _, mineId in ipairs(allMines) do
		if GAME:getObjectOwner(mineId) == -1 then
			unowned[#unowned + 1] = mineId
		end
	end
	return unowned
end

-- ---------------------------------------------------------------------------
-- HELPER: collect skill indices (0-27) where the hero has Basic (1) or
-- Advanced (2) level — i.e., skills that can still be raised to Expert.
-- ---------------------------------------------------------------------------
local function findRaisableSkills(hero)
	local skills = {}
	for i = 0, MAX_SKILL do
		local level = hero:getSecSkillLevel(i) or 0
		if level == 1 or level == 2 then
			skills[#skills + 1] = i
		end
	end
	return skills
end

-- ---------------------------------------------------------------------------
-- OUTCOME 1: Mine deed.
-- Randomly selects one unowned Obj::MINE and transfers it to the player.
-- Returns true if a mine was given, false if no unowned mines exist.
-- ---------------------------------------------------------------------------
local function giveMine(heroId, playerIdx)
	local unowned = findUnownedMines()
	if #unowned == 0 then return false end

	local mineId = unowned[math.random(1, #unowned)]
	local pack = SetObjectProperty.new()
	pack:setId(mineId)
	pack:setOwner(playerIdx)
	SERVER:commitPackage(pack)

	showMessage(playerIdx,
		"{Special Treasure Chest}\n\n"
		.. "Inside you find a deed to an unowned mine! The mine has been flagged "
		.. "with your colors. A new source of income awaits.")
	return true
end

-- ---------------------------------------------------------------------------
-- OUTCOME 2: Tome of Knowledge.
-- Raises one randomly chosen non-Expert secondary skill to Expert (level 3).
-- ERM requires ≥2 raisable skills to offer Tomes; returns false if <2.
-- ---------------------------------------------------------------------------
local function giveTome(heroId, hero, playerIdx)
	local skills = findRaisableSkills(hero)
	if #skills < 2 then return false end  -- ERM: need 2 to qualify

	-- Pick one randomly and raise it to Expert
	local skillIdx = skills[math.random(1, #skills)]
	local pack = SetSecSkill.new()
	pack:setHeroId(heroId)
	pack:setSkill(skillIdx)
	pack:setValue(3)      -- Expert = 3
	pack:setMode(true)    -- true = ABSOLUTE (set to exact level)
	SERVER:commitPackage(pack)

	showMessage(playerIdx,
		"{Special Treasure Chest}\n\n"
		.. "You find a Tome of Knowledge! After careful study, one of your "
		.. "secondary skills has been raised to Expert level.")
	return true
end

-- ---------------------------------------------------------------------------
-- OUTCOME 3: Gold and spell.
-- Gold: 300-900 (random in 100-unit steps matching ERM "S3 R6 *100").
-- Spell: random unknown spell at a level based on hero level (ERM formula:
--   level = heroLevel ÷ 5 + 1, clamped 1-5).
-- ---------------------------------------------------------------------------
local function giveGoldAndSpell(heroId, hero, playerIdx)
	-- Spell level: floor(heroLevel / 5) + 1, clamped 1-5
	local heroLevel  = hero:getLevel() or 1
	local spellLevel = math.floor(heroLevel / 5) + 1
	if spellLevel > 5 then spellLevel = 5 end

	-- Gold: 300-900 in 100-unit steps (ERM: S3 R6 → 3-9, then *100)
	local gold = (math.random(3, 9)) * 100

	-- Give gold
	local res = SetResources.new()
	res:setPlayer(playerIdx)
	res:setAbs(false)
	res:setAmount(RES_GOLD, gold)
	SERVER:commitPackage(res)

	-- Teach one random unknown spell at the appropriate level
	local available = GAME:getSpellsByLevel(spellLevel)
	local unknown   = {}
	if available then
		for _, spellId in ipairs(available) do
			if not hero:hasSpell(spellId) then
				unknown[#unknown + 1] = spellId
			end
		end
	end

	local spellMsg = ""
	if #unknown > 0 then
		local spellId = unknown[math.random(1, #unknown)]
		local pack = ChangeSpells.new()
		pack:setHeroId(heroId)
		pack:setLearn(true)
		pack:addSpell(spellId)
		SERVER:commitPackage(pack)
		spellMsg = " A magical scroll inside also taught you a new spell."
	end

	showMessage(playerIdx,
		"{Special Treasure Chest}\n\n"
		.. "You find a chest containing " .. gold .. " gold!" .. spellMsg)
end

-- ---------------------------------------------------------------------------
-- AFTER VISIT: deliver rewards when a hero visits a wogTreasureChest2 object.
-- The JSON reward's "removeObject": true has already removed the chest before
-- this handler fires. We detect the visit by subtype name.
-- ---------------------------------------------------------------------------
wogTreasureChest2Sub = ObjectVisitStarted.subscribeAfter(EVENT_BUS, function(event)
	if not C.treasureChest2Enabled then return end

	local obj = event:getObject()
	if not obj then return end
	if obj:getSubtypeName() ~= "wogTreasureChest2" then return end

	local heroId    = event:getHero()
	local playerIdx = event:getPlayer()
	if not heroId or playerIdx == nil then return end

	local hero = GAME:getHero(heroId)
	if not hero then return end

	-- Roll 1-5 to determine outcome (ERM: VRv3 S1 R4 → 1-5)
	local roll = math.random(1, 5)

	if roll == 1 then
		-- Mine deed; fall through to Tome if no unowned mines
		if not giveMine(heroId, playerIdx) then
			if not giveTome(heroId, hero, playerIdx) then
				giveGoldAndSpell(heroId, hero, playerIdx)
			end
		end
	elseif roll <= 3 then
		-- Tome of Knowledge; fall through to Gold+Spell if <2 raisable skills
		if not giveTome(heroId, hero, playerIdx) then
			giveGoldAndSpell(heroId, hero, playerIdx)
		end
	else
		-- Gold and spell (rolls 4-5)
		giveGoldAndSpell(heroId, hero, playerIdx)
	end
end)
