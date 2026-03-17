-- wog_mysticism.lua
-- WOG New Age — Enhanced Mysticism (options 35 / 207)
--
-- Classic WOG Script 35: Mysticism regenerates 10%/20%/30% of max SP per day.
-- (Hero's max mana = Knowledge × 10)
--
-- VCMI base Mysticism gives: 1/2/3 SP/day flat (from config/skills.json)
-- Engine natural regen: 3 SP/day base
-- WOG Enhanced: 10%/20%/30% of max SP/day TOTAL
--   For a hero with Knowledge=10 (100 max SP): 10/20/30 SP/day
--   For a hero with Knowledge=20 (200 max SP): 20/40/60 SP/day
--
-- This script adds the PERCENTAGE-based bonus on top of VCMI's flat regen.
-- We calculate bonus = floor(maxMana * pct / 100) then subtract the flat
-- VCMI native amount to avoid double-counting.
--
-- Fires on PlayerGotTurn (subscribeAfter so engine regen has already run).

local PlayerGotTurn = require("events.PlayerGotTurn")
local SetMana       = require("netpacks.SetMana")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

-- WOG: % of max SP regenerated per day per skill level [basic, advanced, expert]
local BONUS_PCT = {10, 20, 30}

-- VCMI native flat Mysticism amounts (from config/skills.json values: 1/2/3)
-- Subtract these so we don't double-count what the engine already gives.
local VCMI_NATIVE = {1, 2, 3}

-- MYSTICISM skill ID = 8
local MYSTICISM_SKILL = C.SKILL and C.SKILL.MYSTICISM or 8

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
				local maxMana  = hero:getManaMax()
				local pct      = BONUS_PCT[level] or 0
				local native   = VCMI_NATIVE[level] or 0
				local wogRegen = math.floor(maxMana * pct / 100)
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
