-- wog_daily_income.lua
-- WOG New Age — Daily Income Bonus
-- Inspired by classic WOG Town Income Development scripts.
--
-- Each day, every active human player receives a small bonus gold income.
-- Default: 100 gold/day per player.
-- Configurable via DATA.WOG.dailyGoldBonus.

local PlayerGotTurn = require("events.PlayerGotTurn")
local SetResources  = require("netpacks.SetResources")

DATA.WOG = DATA.WOG or {}
DATA.WOG.dailyGoldBonus = DATA.WOG.dailyGoldBonus or 100

local RES_GOLD = 6  -- EGameResID::GOLD

wogIncomeSub = PlayerGotTurn.subscribeAfter(EVENT_BUS, function(event)
	local playerIdx = event:getPlayer()

	if not GAME:isPlayerHuman(playerIdx) then
		return
	end

	local bonus = DATA.WOG.dailyGoldBonus
	if bonus <= 0 then return end

	local pack = SetResources.new()
	pack:setPlayer(playerIdx)
	pack:setAbs(false)       -- relative: adds to current gold
	pack:setAmount(RES_GOLD, bonus)
	SERVER:commitPackage(pack)
end)
