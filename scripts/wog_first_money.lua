-- wog_first_money.lua
-- WOG New Age — First Money (option 40)
--
-- On the very first day of the game, each human player receives a bonus
-- gold sum. In classic WOG this was configurable per map but defaulted
-- to 5000 gold. Helps heroes afford early armies and buildings.
--
-- Only fires once: day 1, month 1, week 1 (GAME:getDate(3) == 1).
-- getDate modes: 0=total days, 1=day of week (1-7), 2=current week, 3=current month.
-- We use mode 0 (total days) and check for day == 1.

local PlayerGotTurn = require("events.PlayerGotTurn")
local SetResources  = require("netpacks.SetResources")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

local GOLD = 6  -- EGameResID::GOLD

wogFirstMoneySub = PlayerGotTurn.subscribeAfter(EVENT_BUS, function(event)
	if not (C.firstMoneyEnabled ~= false) then return end

	-- Only fire on absolute day 1 (total game day counter = 0=DAY enum)
	local day = GAME:getDate(0)
	if day ~= 1 then return end

	local playerIdx = event:getPlayer()
	if not GAME:isPlayerHuman(playerIdx) then return end

	local bonus = C.firstMoneyAmount or 5000
	if bonus <= 0 then return end

	local pack = SetResources.new()
	pack:setPlayer(playerIdx)
	pack:setAbs(false)
	pack:setAmount(GOLD, bonus)
	SERVER:commitPackage(pack)
end)
