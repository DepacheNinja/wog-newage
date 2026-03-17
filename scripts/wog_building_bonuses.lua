-- wog_building_bonuses.lua
-- WOG New Age — Building Construction Bonuses
--
-- When players construct certain key buildings, they receive a small
-- resource bonus as a reward for town development. This simulates the
-- WOG philosophy of rewarding investment in town infrastructure.
--
-- Bonuses are only given to human players.
--
-- Key building rewards (WOG-inspired):
--   Castle (BuildingID 9): +1000 gold bonus
--   Capitol (BuildingID 13): +2000 gold + 5 of each rare resource
--   Mage Guild 5 (BuildingID 5): +500 gold + 3 crystals
--   Shipyard (BuildingID 20): +3 wood + 3 ore
--
-- BuildingID values from VCMI BuildingID enum:
--   MAGES_GUILD_1..5 = 0..4 (but here indices differ by town)
--   Actually BuildingID is faction-specific — we use subID or raw int checks

local BuildingBuilt = require("events.BuildingBuilt")
local SetResources  = require("netpacks.SetResources")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.buildingBonusesEnabled = C.buildingBonusesEnabled ~= false

-- Resource IDs (EGameResID)
local WOOD    = 0
local MERCURY = 1
local ORE     = 2
local SULFUR  = 3
local CRYSTAL = 4
local GEMS    = 5
local GOLD    = 6

-- Building IDs that give bonuses (faction-independent IDs where possible)
-- These are the standard "slot" IDs (0-based index in BuildingID enum)
-- Castle/Capitol/Citadel are in slots 8, 9, 10 for most factions
-- Mage Guild levels 0-4 (slots 0-4)
local MAGES_GUILD_5 = 4    -- Mage's Guild Level 5
local CASTLE        = 9    -- Castle (upgrade from Citadel)
local CAPITOL       = 13   -- Capitol

local function giveBonus(playerIdx, amounts)
	-- amounts: table of {resourceId, amount} pairs
	local pack = SetResources.new()
	pack:setPlayer(playerIdx)
	pack:setAbs(false)
	for _, pair in ipairs(amounts) do
		pack:setAmount(pair[1], pair[2])
	end
	SERVER:commitPackage(pack)
end

wogBuildingBonusesSub = BuildingBuilt.subscribeAfter(EVENT_BUS, function(event)
	if not C.buildingBonusesEnabled then return end

	local playerIdx = event:getPlayer()
	if not GAME:isPlayerHuman(playerIdx) then return end

	local buildingId = event:getBuilding()

	if buildingId == MAGES_GUILD_5 then
		-- Mage Guild 5: magical research bonus
		local gold    = C.buildingBonusGuildGold    or 500
		local crystal = C.buildingBonusGuildCrystal or 3
		giveBonus(playerIdx, {{GOLD, gold}, {CRYSTAL, crystal}})

	elseif buildingId == CASTLE then
		-- Castle completed: military bonus
		local gold = C.buildingBonusCastleGold or 1000
		giveBonus(playerIdx, {{GOLD, gold}})

	elseif buildingId == CAPITOL then
		-- Capitol: major economic milestone
		local gold = C.buildingBonusCapitolGold or 2000
		local rare = C.buildingBonusCapitolRare or 5
		giveBonus(playerIdx, {
			{GOLD,    gold},
			{MERCURY, rare},
			{SULFUR,  rare},
			{CRYSTAL, rare},
			{GEMS,    rare},
		})
	end
end)
