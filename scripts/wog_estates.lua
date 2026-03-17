-- wog_estates.lua
-- WOG New Age — Enhanced Estates (option 203 / 191)
--
-- Base VCMI Estates: Basic=125, Advanced=250, Expert=500 gold/day per hero.
-- WOG Enhancement: Adds heroLevel × multiplier gold/day per hero with Estates.
--   Basic:   heroLevel × 5  gold/day extra
--   Advanced: heroLevel × 8  gold/day extra
--   Expert:  heroLevel × 12 gold/day extra
--
-- Fires on PlayerGotTurn (subscribeAfter).

local PlayerGotTurn = require("events.PlayerGotTurn")
local SetResources  = require("netpacks.SetResources")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

-- Gold multiplier per hero level per skill level
local LEVEL_MULT = C.estatesLevelMultiplier or {5, 8, 12}
local ESTATES_SKILL = C.SKILL and C.SKILL.ESTATES or 13
local GOLD_RESOURCE = 6  -- GameResID: 0=wood 1=mercury 2=ore 3=sulfur 4=crystal 5=gems 6=gold

wogEstatesSub = PlayerGotTurn.subscribeAfter(EVENT_BUS, function(event)
	if not (C.estatesEnabled ~= false) then return end

	local playerIdx = event:getPlayer()
	local heroIds   = GAME:getPlayerHeroes(playerIdx)
	if not heroIds then return end

	local totalBonus = 0
	for _, heroId in ipairs(heroIds) do
		local hero = GAME:getHero(heroId)
		if hero then
			local skillLevel = hero:getSecSkillLevel(ESTATES_SKILL)
			if skillLevel > 0 then
				local mult    = LEVEL_MULT[skillLevel] or 0
				local hLevel  = hero:getLevel() or 1
				totalBonus    = totalBonus + (mult * hLevel)
			end
		end
	end

	if totalBonus > 0 then
		local pack = SetResources.new()
		pack:setPlayer(playerIdx)
		pack:setAbs(false)  -- relative (add to existing)
		pack:setAmount(GOLD_RESOURCE, totalBonus)
		SERVER:commitPackage(pack)
	end
end)
