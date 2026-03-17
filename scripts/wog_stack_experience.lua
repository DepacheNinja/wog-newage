-- wog_stack_experience.lua
-- WOG New Age — Stack Experience (option 900)
--
-- Classic WOG: Every creature stack in a hero's army accumulates
-- experience from battles. With enough XP, stacks advance through
-- 10 ranks, gaining stat bonuses at each rank.
--
-- VCMI LIMITATIONS:
-- 1. Cannot modify individual stack stats mid-game without engine support.
-- 2. Stack XP data does not persist across save/load via Lua tables alone.
-- 3. No API to iterate a hero's army stack composition.
--
-- WHAT THIS SCRIPT DOES:
-- Tracks approximate "army experience" per hero using battle XP as a proxy.
-- Awards bonus primary skill points to heroes whose armies would have ranked up.
-- This simulates the "your army gets stronger" feel of Stack Experience.
--
-- XP THRESHOLDS (from WOG classic data, classic Crexpbon.txt):
-- Rank 1: 1000 × creature_level XP needed
-- Rank 2: 2000 × creature_level XP needed
-- Each rank: 1000 × creature_level × rank_number
-- Max rank: 10
--
-- APPROXIMATION: Track total battle XP per hero. Every 5000 total battle XP,
-- award +1 to a random primary skill. This simulates army growth without
-- per-stack tracking.

local BattleEnded    = require("events.BattleEnded")
local SetPrimarySkill = require("netpacks.SetPrimarySkill")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.stackExpEnabled = C.stackExpEnabled ~= false
C.stackExpPerHero = C.stackExpPerHero or {}  -- {heroId = totalBattleXP}

-- XP threshold per bonus (approximates multiple rank-ups)
local XP_PER_BONUS = 5000

-- Primary skills to cycle through: Attack, Defense, SpellPower, Knowledge
local SKILLS = {0, 1, 2, 3}

wogStackExpSub = BattleEnded.subscribeAfter(EVENT_BUS, function(event)
	if not C.stackExpEnabled then return end

	local exp = event:getExpAwarded()
	if exp <= 0 then return end

	local heroId = event:getWinnerHeroId()
	if heroId < 0 then return end

	local key = tostring(heroId)
	C.stackExpPerHero[key] = (C.stackExpPerHero[key] or 0) + exp

	local total = C.stackExpPerHero[key]
	local bonusCount = math.floor(total / XP_PER_BONUS)
	local prevBonusCount = math.floor((total - exp) / XP_PER_BONUS)

	local newBonuses = bonusCount - prevBonusCount
	if newBonuses <= 0 then return end

	-- Award skill bonuses based on hero's XP milestone
	-- Cycle through primary skills based on milestone number
	for i = 1, newBonuses do
		local skillIdx = (bonusCount + i - 1) % 4
		local skill = SKILLS[skillIdx + 1]

		local pack = SetPrimarySkill.new()
		pack:setHeroId(heroId)
		pack:setSkill(skill)
		pack:setValue(1)
		pack:setMode(false)  -- relative
		SERVER:commitPackage(pack)
	end
end)
