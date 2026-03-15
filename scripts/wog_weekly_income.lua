-- wog_weekly_income.lua
-- WOG New Age — Weekly Income Bonus
-- Inspired by classic WOG script45 (Town Income Development)
--
-- Each Monday (day 1 of week), every active human player receives a bonus
-- gold income. Amount is configurable via DATA.WOG.weeklyGoldBonus.
-- Default: 500 gold/week per player.
--
-- In classic WOG, this bonus required upgrading town buildings via a dialog.
-- Custom dialogs are not yet available in FCMI Lua. This script provides
-- the weekly effect as a foundation. When FCMI adds dialog support, this
-- will be extended to require resource investment to unlock/increase the bonus.

local PlayerGotTurn = require("events.PlayerGotTurn")
local SetResources = require("netpacks.SetResources")

-- Persistent config — survives save/load in DATA table
DATA.WOG = DATA.WOG or {}
DATA.WOG.weeklyGoldBonus = DATA.WOG.weeklyGoldBonus or 500

-- Resource type constants (EGameResID)
local RES_GOLD = 6

-- Date mode constants (Date enum)
local DATE_DAY_OF_WEEK = 1  -- returns 1-7, 1 = Monday

-- Subscribe: fires when any player starts their turn
wogIncomeSub = PlayerGotTurn.subscribeAfter(EVENT_BUS, function(event)
	-- Only fire on day 1 of each week (Monday = income day, matches vanilla H3)
	local dayOfWeek = GAME:getDate(DATE_DAY_OF_WEEK)
	if dayOfWeek ~= 1 then
		return
	end

	-- event:getPlayer() returns player index as integer (0-7)
	local playerIdx = event:getPlayer()

	-- Skip AI players — WOG weekly income is for human players only
	if not GAME:isPlayerHuman(playerIdx) then
		return
	end

	local bonus = DATA.WOG.weeklyGoldBonus
	if bonus <= 0 then
		return
	end

	-- Give the weekly gold bonus (setAbs=false means relative delta — adds to existing gold)
	local pack = SetResources.new()
	pack:setPlayer(playerIdx)
	pack:setAbs(false)
	pack:setAmount(RES_GOLD, bonus)
	SERVER:commitPackage(pack)
end)
