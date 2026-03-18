-- wog_spellbook.lua
-- WOG New Age — Enhanced Spellbook (option 27 / ERM script27)
--
-- ERM script27 v1.4 by Anders Jonsson.
-- Classic WOG: when a hero picks up a Spellbook from the adventure map,
-- the book comes pre-loaded with spells. Count and level depend on the
-- hero's Luck and Wisdom secondary skills.
--
-- ERM formula (v1 = spell tier roll):
--   v1 = random(0..9) + luckSkillLevel + 2×wisdomSkillLevel − 6
--   v1 clamped to [0, 9]
--
-- Spells given by roll tier:
--   0-3 (low):    3×lvl1 + 3×lvl2
--   4-6 (medium): + 2×lvl3
--   7-8 (high):   + 2×lvl4
--   9 (top):      + 1×lvl5
--
-- Adventure-map movement spells are not explicitly excluded here
-- (VCMI gives access to all available spells at each level).
-- ERM: triggers on OB5/0 (Artifact object, subtype 0 = Spellbook).

local ObjectVisitStarted = require("events.ObjectVisitStarted")
local ChangeSpells       = require("netpacks.ChangeSpells")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.spellbookEnabled = C.spellbookEnabled ~= false

-- Object group constants (from VCMI lib/constants/EntityIdentifiers.h Obj::Type)
local OBJ_GROUP_ARTIFACT = 5   -- Obj::ARTIFACT = 5

-- Spellbook = artifact index 0 (returned by obj:getObjTypeIndex() for Artifact objects)
local ART_SPELLBOOK = 0

-- Secondary skill indices (from SecondarySkillBase::Type enum)
local SKILL_LUCK   = 9   -- LUCK = 9
local SKILL_WISDOM = 7   -- WISDOM = 7

-- Per-hero queue: set to true when a hero (by heroId) is about to pick up their first Spellbook.
-- Cleared after spells are given in subscribeAfter.
local spellbookQueue = {}

-- ---------------------------------------------------------------------------
-- HELPER: pick up to `count` random spells of `level` that the hero doesn't know.
-- Returns a list of spellIds.
-- ---------------------------------------------------------------------------
local function pickSpells(hero, level, count)
	local available = GAME:getSpellsByLevel(level)
	if not available or #available == 0 then return {} end

	-- Build pool of unknown spells
	local pool = {}
	for _, spellId in ipairs(available) do
		if not hero:hasSpell(spellId) then
			pool[#pool + 1] = spellId
		end
	end

	-- Partial Fisher-Yates to select `count` unique spells from pool
	local result = {}
	local n = #pool
	for i = 1, math.min(count, n) do
		local j = math.random(i, n)
		pool[i], pool[j] = pool[j], pool[i]
		result[#result + 1] = pool[i]
	end
	return result
end

-- ---------------------------------------------------------------------------
-- HELPER: commit a ChangeSpells pack to teach multiple spells at once.
-- ---------------------------------------------------------------------------
local function giveSpells(heroId, spells)
	if #spells == 0 then return end
	local pack = ChangeSpells.new()
	pack:setHeroId(heroId)
	pack:setLearn(true)
	for _, spellId in ipairs(spells) do
		pack:addSpell(spellId)
	end
	SERVER:commitPackage(pack)
end

-- ---------------------------------------------------------------------------
-- BEFORE VISIT: detect when a hero who has no Spellbook is about to pick one up.
-- Tags the heroId in spellbookQueue so subscribeAfter can deliver spells.
-- ---------------------------------------------------------------------------
wogSpellbookPreSub = ObjectVisitStarted.subscribeBefore(EVENT_BUS, function(event)
	if not C.spellbookEnabled then return end

	local obj = event:getObject()
	if not obj then return end
	if obj:getObjGroupIndex() ~= OBJ_GROUP_ARTIFACT then return end
	if obj:getObjTypeIndex()  ~= ART_SPELLBOOK       then return end

	local heroId = event:getHero()
	if not heroId then return end

	local hero = GAME:getHero(heroId)
	-- Only tag if the hero does not already own a spellbook
	if hero and not hero:hasSpellbook() then
		spellbookQueue[heroId] = true
	end
end)

-- ---------------------------------------------------------------------------
-- AFTER VISIT: if hero was tagged as picking up their first Spellbook,
-- compute the spell roll and deliver spells.
-- ---------------------------------------------------------------------------
wogSpellbookSub = ObjectVisitStarted.subscribeAfter(EVENT_BUS, function(event)
	if not C.spellbookEnabled then return end

	local heroId = event:getHero()
	if not heroId then return end
	if not spellbookQueue[heroId] then return end
	spellbookQueue[heroId] = nil  -- consume the tag

	local hero = GAME:getHero(heroId)
	-- Confirm hero now has a spellbook (pickup succeeded)
	if not hero or not hero:hasSpellbook() then return end

	-- ERM formula: roll = random(0..9) + luckLevel + 2×wisdomLevel − 6, clamped 0-9
	local luckLevel   = hero:getSecSkillLevel(SKILL_LUCK)   or 0
	local wisdomLevel = hero:getSecSkillLevel(SKILL_WISDOM) or 0
	local roll = math.random(0, 9) + luckLevel + (2 * wisdomLevel) - 6
	if roll < 0 then roll = 0 end
	if roll > 9 then roll = 9 end

	-- Always give 3×level-1 + 3×level-2 spells
	giveSpells(heroId, pickSpells(hero, 1, 3))
	giveSpells(heroId, pickSpells(hero, 2, 3))

	-- Medium roll (4-9): also give 2×level-3 spells
	if roll >= 4 then
		giveSpells(heroId, pickSpells(hero, 3, 2))
	end

	-- High roll (7-9): also give 2×level-4 spells
	if roll >= 7 then
		giveSpells(heroId, pickSpells(hero, 4, 2))
	end

	-- Top roll (9): also give 1×level-5 spell
	if roll == 9 then
		giveSpells(heroId, pickSpells(hero, 5, 1))
	end
end)
