-- wog_mysticism.lua
-- WOG New Age — Enhanced Mysticism (options 35 / 207)
--
-- Classic WOG Script 35: Mysticism regenerates 10%/20%/30% of max SP per day.
-- (Hero's max mana = Knowledge × 10)
--
-- ERM script35 addition: Intelligence secondary skill multiplies max mana
-- for the Mysticism regen calculation:
--   Expert Intelligence (level 3): max mana × 2.0
--   Advanced Intelligence (level 2): max mana × 1.5
--   Basic Intelligence (level 1): max mana × 1.25
--   No Intelligence: max mana × 1.0
--
-- VCMI base Mysticism gives: 1/2/3 SP/day flat (from config/skills.json)
-- Engine natural regen: 3 SP/day base
-- WOG Enhanced: 10%/20%/30% of (maxMana × intelligenceMultiplier) per day TOTAL
--
-- This script adds the PERCENTAGE-based bonus on top of VCMI's flat regen.
-- We calculate bonus = floor(effectiveMana * pct / 100) then subtract the flat
-- VCMI native amount to avoid double-counting.
--
-- Note: In ERM, AI heroes receive double the Mysticism regen. This script only
-- runs on PlayerGotTurn (human turns only in practice), so AI double-regen is
-- not implemented here.
--
-- Fires on PlayerGotTurn (subscribeAfter so engine regen has already run).

local PlayerGotTurn = require("events.PlayerGotTurn")
local SetMana       = require("netpacks.SetMana")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

-- WOG: % of max SP regenerated per day per skill level [basic, advanced, expert]
local BONUS_PCT = C.mysticismBonusPct or {10, 20, 30}

-- Intelligence multiplier per level [basic, advanced, expert]
-- Applied to maxMana before computing regen (ERM script35 lines 59-64)
local INTEL_MULT = C.intelligenceMultiplier or {1.25, 1.5, 2.0}

-- VCMI native flat Mysticism amounts (from config/skills.json values: 1/2/3)
-- Subtract these so we don't double-count what the engine already gives.
local VCMI_NATIVE = {1, 2, 3}

-- Skill IDs
local MYSTICISM_SKILL    = C.SKILL and C.SKILL.MYSTICISM    or 8
local INTELLIGENCE_SKILL = C.SKILL and C.SKILL.INTELLIGENCE or 24

wogMysticismSub = PlayerGotTurn.subscribeAfter(EVENT_BUS, function(event)
	if not (C.mysticismEnabled ~= false) then return end

	local playerIdx = event:getPlayer()
	local heroIds   = GAME:getPlayerHeroes(playerIdx)
	if not heroIds then return end

	for _, heroId in ipairs(heroIds) do
		local hero = GAME:getHero(heroId)
		if hero then
			local level = hero:getSecSkillLevel(MYSTICISM_SKILL)
			if level > 0 then
				local maxMana = hero:getManaMax()

				-- Apply Intelligence multiplier to effective mana for regen calc
				local intelLevel = hero:getSecSkillLevel(INTELLIGENCE_SKILL)
				local mult = 1.0
				if intelLevel > 0 then
					mult = INTEL_MULT[intelLevel] or 1.0
				end
				local effectiveMana = maxMana * mult

				local pct      = BONUS_PCT[level] or 0
				local native   = VCMI_NATIVE[level] or 0
				local wogRegen = math.floor(effectiveMana * pct / 100)
				local bonus    = wogRegen - native  -- net addition beyond VCMI native

				if bonus > 0 then
					local pack = SetMana.new()
					pack:setHeroId(heroId)
					pack:setValue(bonus)
					pack:setMode(false)  -- relative (add to existing)
					SERVER:commitPackage(pack)
				end
			end
		end
	end
end)
