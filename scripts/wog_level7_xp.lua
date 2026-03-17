-- wog_level7_xp.lua
-- WOG New Age — Level 7+ Creatures Gain 50% XP (option 245)
--
-- Classic WOG: When you defeat an army containing tier 7 creatures,
-- the XP awarded is halved. This balances the power of high-tier armies
-- (Black Dragons, Angels, etc.) — they're still powerful, but XP-efficient.
--
-- Implementation:
--   BattleStarted: Record if each side has any tier 7 creatures
--   BattleEnded: If the LOSER had tier 7 creatures, reduce winner's XP by 50%
--   (Refund = award another chunk, but negative — SetHeroExperience with negative value)
--
-- Uses SetHeroExperience with mode=false (relative) and negative value to deduct.
-- Note: The XP is already awarded by the engine at BattleEnded. We add a negative
-- correction immediately after.

local BattleStarted     = require("events.BattleStarted")
local BattleEnded       = require("events.BattleEnded")
local SetHeroExperience = require("netpacks.SetHeroExperience")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.level7XPEnabled = C.level7XPEnabled ~= false  -- enabled by default

-- XP reduction when fighting tier 7 army: 50% deduction
local XP_REDUCTION_PCT = C.level7XPReductionPct or 50

-- Per-battle tracking: does each side have tier 7 creatures?
-- Key: "attackerHeroId_defenderHeroId", Value: {attackerHasTier7, defenderHasTier7}
C.battleTier7Data = C.battleTier7Data or {}

local function hasTier7InArmy(heroId)
	if heroId < 0 then return false end
	local hero = GAME:getHero(heroId)
	if not hero then return false end
	for slot = 0, 6 do
		local stack = hero:getStack(slot)
		if stack then
			local creatureType = stack:getType()
			if creatureType and creatureType:getLevel() >= 7 then
				return true
			end
		end
	end
	return false
end

local function battleKey(attackerHeroId, defenderHeroId)
	return tostring(attackerHeroId) .. "_" .. tostring(defenderHeroId)
end

wogLevel7XPBattleStartSub = BattleStarted.subscribeAfter(EVENT_BUS, function(event)
	if not C.level7XPEnabled then return end

	local attackerHeroId = event:getAttackerHeroId()
	local defenderHeroId = event:getDefenderHeroId()
	local key = battleKey(attackerHeroId, defenderHeroId)

	C.battleTier7Data[key] = {
		attackerHasTier7 = hasTier7InArmy(attackerHeroId),
		defenderHasTier7 = hasTier7InArmy(defenderHeroId),
	}
end)

wogLevel7XPBattleEndSub = BattleEnded.subscribeAfter(EVENT_BUS, function(event)
	if not C.level7XPEnabled then return end

	-- Only apply XP reduction on real combat (NORMAL=0), not retreats/surrenders
	if event:getBattleResult() ~= 0 then return end

	local exp = event:getExpAwarded()
	if exp <= 0 then return end

	local winnerHeroId = event:getWinnerHeroId()
	local loserHeroId  = event:getLoserHeroId()
	if winnerHeroId < 0 then return end

	-- Look up tier 7 data (try both orderings)
	local keyWinFirst  = battleKey(winnerHeroId, loserHeroId)
	local keyLoseFirst = battleKey(loserHeroId,  winnerHeroId)

	local data = C.battleTier7Data[keyWinFirst]
	local loserWasAttacker = false
	if not data then
		data = C.battleTier7Data[keyLoseFirst]
		loserWasAttacker = (data ~= nil)
	end

	-- Clean up
	C.battleTier7Data[keyWinFirst]  = nil
	C.battleTier7Data[keyLoseFirst] = nil

	if not data then return end

	-- Determine if the LOSER had tier 7 creatures
	local loserHasTier7 = loserWasAttacker and data.attackerHasTier7 or data.defenderHasTier7
	if not loserHasTier7 then return end

	-- Deduct XP_REDUCTION_PCT% of awarded XP
	local deduct = math.floor(exp * XP_REDUCTION_PCT / 100)
	if deduct < 1 then return end

	local pack = SetHeroExperience.new()
	pack:setHeroId(winnerHeroId)
	pack:setValue(-deduct)
	pack:setMode(false)  -- relative (add/subtract)
	SERVER:commitPackage(pack)
end)
