-- wog_treasure_chests.lua
-- WOG New Age — Upgrading Treasure Chests (option 132)
--
-- Classic WOG: Treasure chests give enhanced rewards.
-- The standard H3 chest gives 1000/1500/2000 gold or 1000/1500/2000 XP.
-- WOG Enhancement: After visiting a chest, hero gets an additional bonus.
--   500 gold OR 500 XP (randomly chosen) as extra reward.
--
-- This fires AFTER the engine gives the normal chest reward,
-- adding a supplemental bonus on top.
-- Fires on ObjectVisitStarted (subscribeAfter).

local ObjectVisitStarted = require("events.ObjectVisitStarted")
local SetResources       = require("netpacks.SetResources")
local SetHeroExperience  = require("netpacks.SetHeroExperience")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

-- MapObjectID::TREASURE_CHEST = 101
local TREASURE_CHEST_ID = 101
local GOLD_RESOURCE     = 6   -- EGameResID::GOLD
local BONUS_AMOUNT      = C.chestBonusAmount or 500  -- gold or XP

wogTreasureChestSub = ObjectVisitStarted.subscribeAfter(EVENT_BUS, function(event)
	if not (C.treasureChestsEnabled ~= false) then return end

	local objId = event:getObject()
	local obj   = GAME:getObj(objId)
	if not obj then return end

	-- Check if visited object is a Treasure Chest (MapObjectID 101)
	if obj:getObjGroupIndex() ~= TREASURE_CHEST_ID then return end

	local playerIdx = event:getPlayer()
	if not GAME:isPlayerHuman(playerIdx) then return end

	local heroId = event:getHero()
	if heroId < 0 then return end

	-- Randomly give gold or XP bonus
	local bonus = C.chestBonusAmount or BONUS_AMOUNT
	if math.random(2) == 1 then
		-- Extra gold
		local pack = SetResources.new()
		pack:setPlayer(playerIdx)
		pack:setAbs(false)
		pack:setAmount(GOLD_RESOURCE, bonus)
		SERVER:commitPackage(pack)
	else
		-- Extra XP
		local pack = SetHeroExperience.new()
		pack:setHeroId(heroId)
		pack:setValue(bonus)
		pack:setMode(false)
		SERVER:commitPackage(pack)
	end
end)
