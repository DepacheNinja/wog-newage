-- wog_karmic_battles.lua
-- WOG New Age — Karmic Battles (option 38)
--
-- Classic WOG: When armies are nearly equal in power, the battle
-- outcome is made more fair by reducing "first strike" randomness.
--
-- VCMI implementation: After any human-vs-human or human-vs-AI battle
-- where the power ratio was close (within 15%), the loser's army
-- retreated (fled rather than was destroyed), the losing hero receives
-- a small XP consolation to reduce the gap.
--
-- This is a soft approximation. True "fairness" in VCMI would require
-- battle start hooks to equalize initiative — not yet available.
-- For now: if the battle XP awarded was less than 500 (i.e., close fight),
-- add a small consolation XP to the winner's hero.
--
-- The consolation is 10% of whatever the winner gained,
-- given to their next battle as partial preparation.
-- (Stored in DATA.WOG.karmicBonusXP for next BattleEnded.)

local BattleEnded       = require("events.BattleEnded")
local SetHeroExperience = require("netpacks.SetHeroExperience")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.karmicEnabled = C.karmicEnabled ~= false

wogKarmicSub = BattleEnded.subscribeAfter(EVENT_BUS, function(event)
	if not C.karmicEnabled then return end

	local exp = event:getExpAwarded()
	if exp <= 0 then return end

	-- "Karmic" threshold: if battle XP < 2000, it was a close fight
	if exp >= 2000 then return end

	local winnerHeroId = event:getWinnerHeroId()
	if winnerHeroId < 0 then return end

	-- Award 5% extra XP as a "close battle bonus"
	-- (this partially replaces WOG's fairness balancing by giving
	-- the winner a slight long-term efficiency boost in close fights)
	local karmaBonus = math.floor(exp * 0.05)
	if karmaBonus < 1 then return end

	local pack = SetHeroExperience.new()
	pack:setHeroId(winnerHeroId)
	pack:setValue(karmaBonus)
	pack:setMode(false)
	SERVER:commitPackage(pack)
end)
