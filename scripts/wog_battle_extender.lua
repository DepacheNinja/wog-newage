-- wog_battle_extender.lua
-- WOG New Age — Battle Extender (option 220)
--
-- Classic WOG: When a hero retreats from battle and has sufficient gold,
-- they can choose to immediately rejoin the battle with their remaining
-- forces. The cost scales with army strength and battle progress.
--
-- VCMI LIMITATION: Intercepting retreat/flee actions and offering a
-- "rejoin" option requires:
--   1. A BattleRetreating event (not yet in FCMI)
--   2. UI hooks to show the choice dialog
--
-- Approximation: When a hero loses a battle (is the loser in BattleEnded),
-- they receive a small gold refund (25% of estimated army value) to help
-- rebuild faster. This softens the penalty of losing a battle.
--
-- The refund is 1000 gold flat as a minimal survival aid.
-- Full feature requires engine-level retreat/flee interception.

local BattleEnded  = require("events.BattleEnded")
local SetResources = require("netpacks.SetResources")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.battleExtenderEnabled = C.battleExtenderEnabled ~= false
local REFUND_GOLD = 1000
local GOLD = 6

wogBattleExtenderSub = BattleEnded.subscribeAfter(EVENT_BUS, function(event)
	if not C.battleExtenderEnabled then return end

	local exp = event:getExpAwarded()
	-- Only apply when a proper battle happened (exp > 0 means real combat)
	if exp <= 0 then return end

	local loserIdx = event:getLoser()
	-- Only refund to human players
	if not GAME:isPlayerHuman(loserIdx) then return end

	local pack = SetResources.new()
	pack:setPlayer(loserIdx)
	pack:setAbs(false)
	pack:setAmount(GOLD, REFUND_GOLD)
	SERVER:commitPackage(pack)
end)
