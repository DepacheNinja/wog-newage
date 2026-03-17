-- wog_karmic_battles.lua
-- WOG New Age — Karmic Battles (option 38)
--
-- Classic WOG: "Close battles award 5% extra XP" (to winner).
-- Also: losing hero gets consolation XP in close battles (karma).
--
-- VCMI implementation:
-- After any battle where XP awarded < CLOSE_BATTLE_XP:
--   1. Winner gets +5% of XP awarded as a karmic bonus
--   2. Loser (if human, if hero exists) gets 10% of winner's XP as consolation
--
-- The XP threshold (CLOSE_BATTLE_XP) approximates "equal-strength" battles.
-- True closeness would need army strength comparison from BattleStart (unavailable).

local BattleEnded       = require("events.BattleEnded")
local SetHeroExperience = require("netpacks.SetHeroExperience")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

-- XP threshold below which a battle is "close"
local CLOSE_BATTLE_XP = C.karmicCloseXP or 2000
-- Bonus percent for winner in close battle
local WINNER_BONUS_PCT = C.karmicWinnerPct or 5
-- Consolation percent for loser (based on winner's XP)
local LOSER_CONSOL_PCT = C.karmicLoserPct or 10

local function giveXP(heroId, amount)
	if heroId < 0 or amount < 1 then return end
	local pack = SetHeroExperience.new()
	pack:setHeroId(heroId)
	pack:setValue(amount)
	pack:setMode(false)
	SERVER:commitPackage(pack)
end

wogKarmicSub = BattleEnded.subscribeAfter(EVENT_BUS, function(event)
	if not (C.karmicEnabled ~= false) then return end

	local exp = event:getExpAwarded()
	if exp <= 0 then return end
	if exp >= CLOSE_BATTLE_XP then return end  -- not a close battle

	local winnerHeroId = event:getWinnerHeroId()
	local loserHeroId  = event:getLoserHeroId()

	-- Winner gets karmic bonus (+5% of awarded XP)
	if winnerHeroId >= 0 then
		local winBonus = math.floor(exp * WINNER_BONUS_PCT / 100)
		giveXP(winnerHeroId, winBonus)
	end

	-- Loser gets consolation XP (10% of what winner got, rewarding bravery)
	if loserHeroId >= 0 then
		local loseConsol = math.floor(exp * LOSER_CONSOL_PCT / 100)
		giveXP(loserHeroId, loseConsol)
	end
end)
