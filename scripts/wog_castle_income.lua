-- wog_castle_income.lua
-- WOG New Age — Castle Upgrading / Town Income (option 45)
--
-- Classic WOG: Towns can build a "Gold Reserve" for extra income (+1000g/day).
-- VCMI Approximation: Bonus income scales with existing town development:
--   - Town with City Hall built: +250 gold/day bonus
--   - Town with Capitol built:   +500 gold/day bonus (instead of City Hall bonus)
--
-- This simulates WOG's philosophy that developed towns generate more wealth.
-- The bonus stacks per town — a player with 3 Capitol towns earns +1500g/day.
-- Only applies to human players (AI uses default engine income).
--
-- Building IDs (BuildingID enum from VCMI engine):
--   CITY_HALL = 12   (generates 2000 gold/week in vanilla)
--   CAPITOL   = 13   (generates 4000 gold/week in vanilla)

local PlayerGotTurn = require("events.PlayerGotTurn")
local SetResources  = require("netpacks.SetResources")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

-- Enable/disable this feature
C.castleIncomeEnabled         = C.castleIncomeEnabled ~= false
-- Gold bonus per day per town, based on hall level
local CITY_HALL_BONUS = C.castleIncomeCityHall or 250   -- gold/day if town has City Hall
local CAPITOL_BONUS   = C.castleIncomeCapitol  or 500   -- gold/day if town has Capitol

local GOLD       = 6   -- EGameResID::GOLD
local CITY_HALL  = 12  -- BuildingID::CITY_HALL
local CAPITOL    = 13  -- BuildingID::CAPITOL

wogCastleIncomeSub = PlayerGotTurn.subscribeAfter(EVENT_BUS, function(event)
	if not C.castleIncomeEnabled then return end

	local playerIdx = event:getPlayer()
	if not GAME:isPlayerHuman(playerIdx) then return end

	local towns = GAME:getPlayerTowns(playerIdx)
	if not towns then return end

	local totalBonus = 0

	for _, townId in ipairs(towns) do
		if GAME:townHasBuilding(townId, CAPITOL) then
			totalBonus = totalBonus + CAPITOL_BONUS
		elseif GAME:townHasBuilding(townId, CITY_HALL) then
			totalBonus = totalBonus + CITY_HALL_BONUS
		end
	end

	if totalBonus <= 0 then return end

	local pack = SetResources.new()
	pack:setPlayer(playerIdx)
	pack:setAbs(false)
	pack:setAmount(GOLD, totalBonus)
	SERVER:commitPackage(pack)
end)
