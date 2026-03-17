-- wog_weekly_income.lua
-- WOG New Age — Daily Gold Bonus (custom feature)
--
-- Each day, every active human player receives a small bonus gold income.
-- Default: 100 gold/day per player (configurable via wog_config.lua).
-- Inspired by classic WOG Town Income Development scripts.

local PlayerGotTurn = require("events.PlayerGotTurn")
local SetResources  = require("netpacks.SetResources")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

local RES_GOLD = 6  -- EGameResID::GOLD

wogIncomeSub = PlayerGotTurn.subscribeAfter(EVENT_BUS, function(event)
	if not (C.weeklyIncomeEnabled ~= false) then return end

	local playerIdx = event:getPlayer()
	if not GAME:isPlayerHuman(playerIdx) then return end

	local bonus = C.weeklyIncomeAmount or 100
	if bonus <= 0 then return end

	local pack = SetResources.new()
	pack:setPlayer(playerIdx)
	pack:setAbs(false)
	pack:setAmount(RES_GOLD, bonus)
	SERVER:commitPackage(pack)
end)
