-- wog_karmic_battles.lua
-- WOG New Age — Karmic Battles (option 38)
--
-- Classic WOG: "Close battles award 5% extra XP" (to winner).
-- Also: losing hero gets consolation XP in close battles (karma).
--
-- VCMI implementation:
-- At BattleStarted: compute both sides' total AI value to judge army strength ratio.
-- At BattleEnded: if armies were within CLOSE_RATIO of each other, apply karma:
--   1. Winner gets +5% of XP awarded as a karmic bonus
--   2. Loser (if hero exists) gets 10% of winner's XP as consolation
--
-- Close battle: weaker army had >= CLOSE_RATIO (default 50%) of stronger army's AI value.
-- Falls back to XP threshold (2000) if army data unavailable.

local BattleStarted     = require("events.BattleStarted")
local BattleEnded       = require("events.BattleEnded")
local SetHeroExperience = require("netpacks.SetHeroExperience")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

-- Ratio below which battle is NOT close (0.5 = attacker must be ≥50% of defender's value)
local CLOSE_RATIO   = C.karmicCloseRatio or 0.5  -- armies within 50% strength ratio
-- Fallback XP threshold for "close" battle (used if army data unavailable)
local CLOSE_XP      = C.karmicCloseXP or 2000
local WINNER_PCT    = C.karmicWinnerPct or 5
local LOSER_PCT     = C.karmicLoserPct  or 10

-- Per-battle tracking: {attackerStrength, defenderStrength}
-- Key: "attackerHeroId_defenderHeroId"
C.battleStrengthData = C.battleStrengthData or {}

local function calcArmyStrength(heroId)
	if heroId < 0 then return 0 end
	local hero = GAME:getHero(heroId)
	if not hero then return 0 end
	local total = 0
	for slot = 0, 6 do
		local stack = hero:getStack(slot)
		if stack then
			local creature = stack:getType()
			local count    = stack:getCount()
			if creature and count then
				local aiVal = creature:getAIValue() or 0
				total = total + aiVal * count
			end
		end
	end
	return total
end

local function battleKey(a, b)
	return tostring(a) .. "_" .. tostring(b)
end

wogKarmicBattleStartSub = BattleStarted.subscribeAfter(EVENT_BUS, function(event)
	if not (C.karmicEnabled ~= false) then return end

	local attackerHeroId = event:getAttackerHeroId()
	local defenderHeroId = event:getDefenderHeroId()
	local key = battleKey(attackerHeroId, defenderHeroId)

	C.battleStrengthData[key] = {
		attacker = calcArmyStrength(attackerHeroId),
		defender = calcArmyStrength(defenderHeroId),
	}
end)

wogKarmicSub = BattleEnded.subscribeAfter(EVENT_BUS, function(event)
	if not (C.karmicEnabled ~= false) then return end

	local exp = event:getExpAwarded()
	if exp <= 0 then return end

	local winnerHeroId = event:getWinnerHeroId()
	local loserHeroId  = event:getLoserHeroId()

	-- Determine if the battle was "close" using army strength data
	local isClose = false
	local keyWinFirst  = battleKey(winnerHeroId, loserHeroId)
	local keyLoseFirst = battleKey(loserHeroId,  winnerHeroId)
	local data = C.battleStrengthData[keyWinFirst]
	if not data then
		data = C.battleStrengthData[keyLoseFirst]
	end
	C.battleStrengthData[keyWinFirst]  = nil
	C.battleStrengthData[keyLoseFirst] = nil

	if data then
		local stronger = math.max(data.attacker, data.defender)
		local weaker   = math.min(data.attacker, data.defender)
		if stronger > 0 and (weaker / stronger) >= CLOSE_RATIO then
			isClose = true
		end
	else
		-- Fallback: use XP threshold
		isClose = (exp < CLOSE_XP)
	end

	if not isClose then return end

	local function giveXP(heroId, amount)
		if heroId < 0 or amount < 1 then return end
		local pack = SetHeroExperience.new()
		pack:setHeroId(heroId)
		pack:setValue(amount)
		pack:setMode(false)
		SERVER:commitPackage(pack)
	end

	-- Winner gets karmic bonus (+5% of awarded XP)
	if winnerHeroId >= 0 then
		giveXP(winnerHeroId, math.floor(exp * WINNER_PCT / 100))
	end

	-- Loser gets consolation XP (10% of awarded XP, rewarding bravery)
	if loserHeroId >= 0 then
		giveXP(loserHeroId, math.floor(exp * LOSER_PCT / 100))
	end
end)
