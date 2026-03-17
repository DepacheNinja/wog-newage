-- wog_first_money.lua
-- WOG New Age — First Money (option 40)
--
-- On the very first day of the game, ALL players (including AI) receive:
--   Gold: 12000 (ERM script40: +12000 gold — unconditional)
--   Resources: +20 wood, +20 ore, +10 mercury, +10 sulfur, +10 crystal, +10 gems
--              (ERM script40: all resources given unconditionally, same packet as gold)
--
-- ERM script40 by Alexis Koz: Uses OW:R (owner resources) to add to each resource type.
-- Resource type order in ERM: 6=gold, 0=wood, 1=mercury, 2=ore, 3=sulfur, 4=crystal, 5=gems
-- ERM: +12000 gold, +20 wood, +20 ore, +10 mercury, +10 sulfur, +10 crystal, +10 gems
--
-- Only fires once: when total game day == 1.

local PlayerGotTurn = require("events.PlayerGotTurn")
local SetResources  = require("netpacks.SetResources")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

-- Resource type IDs
local GOLD    = 6
local WOOD    = 0
local ORE     = 2
local MERCURY = 1
local SULFUR  = 3
local CRYSTAL = 4
local GEMS    = 5

wogFirstMoneySub = PlayerGotTurn.subscribeAfter(EVENT_BUS, function(event)
	if not (C.firstMoneyEnabled ~= false) then return end

	local day = GAME:getDate(0)
	if day ~= 1 then return end

	local playerIdx = event:getPlayer()
	-- Give to ALL players (including AI), matching classic WoG behavior

	-- Gold bonus
	local goldBonus = C.firstMoneyAmount or 5000
	if goldBonus > 0 then
		local pack = SetResources.new()
		pack:setPlayer(playerIdx)
		pack:setAbs(false)
		pack:setAmount(GOLD, goldBonus)
		SERVER:commitPackage(pack)
	end

	-- Resource bonus (disabled by default; set C.firstMoneyResources = true to enable)
	if C.firstMoneyResources then
		local rPack = SetResources.new()
		rPack:setPlayer(playerIdx)
		rPack:setAbs(false)
		rPack:setAmount(WOOD,    C.firstMoneyWood    or 20)
		rPack:setAmount(ORE,     C.firstMoneyOre     or 20)
		rPack:setAmount(MERCURY, C.firstMoneyMercury or 10)
		rPack:setAmount(SULFUR,  C.firstMoneySulfur  or 10)
		rPack:setAmount(CRYSTAL, C.firstMoneyCrystal or 10)
		rPack:setAmount(GEMS,    C.firstMoneyGems    or 10)
		SERVER:commitPackage(rPack)
	end
end)
