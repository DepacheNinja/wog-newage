-- wog_neutral_stack_exp.lua
-- WOG New Age — Neutral Stack Experience (option 231)
--
-- When wandering monsters (neutral stacks) WIN a battle against a hero,
-- their stack grows as a "reward" for the victory — simulating the XP
-- that WOG granted to victorious neutral stacks.
--
-- Classic WOG: neutrals that defeat a hero gained experience to improve stats.
-- VCMI approximation: winning neutrals grow their stack count by +victoryGrowthPct.
-- (True stat-boost XP is not possible without a bonus-granting netpack for map objects.)
--
-- Implementation:
--   BattleStarted: if one side has no hero (heroId == -1), record the neutral's
--     army object ID (from getAttackerArmyId/getDefenderArmyId) paired with
--     the battle's hero side. Store as pendingNeutralBattle[battleKey].
--   BattleEnded: if winner has no hero, look up the neutral, get current count,
--     apply the growth bonus via ChangeStackCount.

local BattleStarted = require("events.BattleStarted")
local BattleEnded   = require("events.BattleEnded")
local ChangeStackCount = require("netpacks.ChangeStackCount")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.neutralStackExpEnabled  = C.neutralStackExpEnabled ~= false
C.neutralVictoryGrowthPct = C.neutralVictoryGrowthPct or 20   -- % stack growth when neutral wins

-- Track pending neutral battles by hero ID pair (same key used in creature_relations)
local pendingNeutralBattles = {}

local function battleKey(a, b)
	return tostring(a) .. "_" .. tostring(b)
end

wogNeutralStackExpStartSub = BattleStarted.subscribeAfter(EVENT_BUS, function(event)
	if not C.neutralStackExpEnabled then return end

	local attackerHeroId = event:getAttackerHeroId()
	local defenderHeroId = event:getDefenderHeroId()

	-- Only interested in hero vs neutral (one side has no hero, heroId == -1)
	local NONE = -1
	if attackerHeroId == NONE and defenderHeroId == NONE then return end
	if attackerHeroId ~= NONE and defenderHeroId ~= NONE then return end

	local attackerArmyId = event:getAttackerArmyId()
	local defenderArmyId = event:getDefenderArmyId()

	-- Determine which side is the neutral (army ID will differ from heroId == NONE)
	local neutralArmyId, heroId
	if attackerHeroId == NONE then
		-- Attacker is neutral, defender is hero
		neutralArmyId = attackerArmyId
		heroId = defenderHeroId
	else
		-- Defender is neutral, attacker is hero
		neutralArmyId = defenderArmyId
		heroId = attackerHeroId
	end

	if neutralArmyId == nil or neutralArmyId < 0 then return end

	-- Store pending battle: both key orderings so BattleEnded can find it
	local key = battleKey(heroId, NONE)
	pendingNeutralBattles[key] = {neutralArmyId = neutralArmyId, heroId = heroId}
end)

wogNeutralStackExpEndSub = BattleEnded.subscribeAfter(EVENT_BUS, function(event)
	if not C.neutralStackExpEnabled then return end

	local winnerHeroId = event:getWinnerHeroId()
	local loserHeroId  = event:getLoserHeroId()

	-- We're interested in cases where the hero LOST (winnerHeroId == -1 means hero lost)
	if winnerHeroId ~= -1 then return end
	if loserHeroId < 0 then return end

	-- Look up the pending neutral battle where this hero was involved
	local key = battleKey(loserHeroId, -1)
	local battleData = pendingNeutralBattles[key]
	pendingNeutralBattles[key] = nil

	if not battleData then return end

	local neutralArmyId = battleData.neutralArmyId
	if not neutralArmyId or neutralArmyId < 0 then return end

	-- Get current count of the victorious neutral stack
	local currentCount = GAME:getMonsterCount(neutralArmyId)
	if not currentCount or currentCount <= 0 then return end

	-- Apply victory growth bonus
	local growthPct = C.neutralVictoryGrowthPct or 20
	local newCount = math.floor(currentCount * (100 + growthPct) / 100)
	if newCount <= currentCount then return end

	local pack = ChangeStackCount.new()
	pack:setArmyId(neutralArmyId)
	pack:setSlot(0)
	pack:setCount(newCount)
	pack:setMode(true)  -- absolute
	SERVER:commitPackage(pack)
end)
