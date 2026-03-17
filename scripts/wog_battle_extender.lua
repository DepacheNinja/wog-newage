-- wog_battle_extender.lua
-- WOG New Age — Battle Extender (option 220)
--
-- Classic WOG: When a hero retreats or surrenders from battle, they receive
-- a gold refund representing the cost to reconvene forces. In classic WOG,
-- the hero could also choose to immediately rejoin the battle, but that
-- requires engine-level retreat interception not yet available.
--
-- Implementation:
--   On BattleEnded: if battle result is ESCAPE (1) or SURRENDER (2),
--   the losing human player receives a gold refund. NORMAL defeat (0)
--   gives no refund — the hero lost the battle outright.
--
-- getBattleResult() values: 0=NORMAL, 1=ESCAPE, 2=SURRENDER

local BattleEnded  = require("events.BattleEnded")
local SetResources = require("netpacks.SetResources")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.battleExtenderEnabled = C.battleExtenderEnabled ~= false

local RESULT_NORMAL    = 0
local RESULT_ESCAPE    = 1
local RESULT_SURRENDER = 2
local GOLD = 6

local REFUND_GOLD = C.battleExtenderRefundGold or 1000

wogBattleExtenderSub = BattleEnded.subscribeAfter(EVENT_BUS, function(event)
	if not C.battleExtenderEnabled then return end

	local result = event:getBattleResult()
	-- Only refund when hero escaped or surrendered (not a normal battle defeat)
	if result ~= RESULT_ESCAPE and result ~= RESULT_SURRENDER then return end

	local loserIdx = event:getLoser()
	-- Only refund to human players
	if not GAME:isPlayerHuman(loserIdx) then return end

	local pack = SetResources.new()
	pack:setPlayer(loserIdx)
	pack:setAbs(false)
	pack:setAmount(GOLD, REFUND_GOLD)
	SERVER:commitPackage(pack)
end)
