-- wog_estates.lua
-- WOG New Age — Enhanced Estates (options 203 / 191)
--
-- Base VCMI Estates: Basic=125, Advanced=250, Expert=500 gold/day per hero.
--
-- WOG Enhancement I — Gold (fires daily):
--   Extra gold = heroLevel × multiplier per skill level
--   Basic: heroLevel × 5 gold/day
--   Advanced: heroLevel × 8 gold/day
--   Expert:   heroLevel × 12 gold/day
--
-- WOG Enhancement II — Weekly Resource (fires on day 1 of each week):
--   Each hero with Estates randomly generates 1-3 units of a rare resource.
--   Wood and ore quantities are doubled.
--   Resource type is assigned once per hero and persists for the session.
--   (Classic WOG: "1-3 units of a resource every week, doubled for wood or ore")
--
-- Fires on PlayerGotTurn (subscribeAfter).

local PlayerGotTurn = require("events.PlayerGotTurn")
local SetResources  = require("netpacks.SetResources")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

-- Gold multiplier per hero level per skill level [basic, advanced, expert]
local LEVEL_MULT    = C.estatesLevelMultiplier or {5, 8, 12}
local ESTATES_SKILL = C.SKILL and C.SKILL.ESTATES or 13
local GOLD_RESOURCE = 6  -- EGameResID: 0=wood 1=mercury 2=ore 3=sulfur 4=crystal 5=gems 6=gold

-- Resource IDs for the weekly bonus (non-gold resources)
-- Wood=0 and Ore=2 are common, so doubled; rare resources are normal amount
local RESOURCE_IDS  = {0, 1, 2, 3, 4, 5}
local DOUBLED_TYPES = {[0]=true, [2]=true}

-- Per-hero resource type: heroId (string) -> resource index
C.estatesHeroResource = C.estatesHeroResource or {}

local function pickResourceForHero(heroId)
	local key = tostring(heroId)
	if not C.estatesHeroResource[key] then
		local idx = math.random(1, #RESOURCE_IDS)
		C.estatesHeroResource[key] = RESOURCE_IDS[idx]
	end
	return C.estatesHeroResource[key]
end

wogEstatesSub = PlayerGotTurn.subscribeAfter(EVENT_BUS, function(event)
	if not (C.estatesEnabled ~= false) then return end

	local playerIdx = event:getPlayer()
	local heroIds   = GAME:getPlayerHeroes(playerIdx)
	if not heroIds then return end

	local dayOfWeek  = GAME:getDate(1)
	local isWeekStart = (dayOfWeek == 1)

	local resourceAmounts = {}
	local totalGoldBonus  = 0

	for _, heroId in ipairs(heroIds) do
		local hero = GAME:getHero(heroId)
		if hero then
			local skillLevel = hero:getSecSkillLevel(ESTATES_SKILL)
			if skillLevel > 0 then
				-- Daily gold scaling bonus
				local mult   = LEVEL_MULT[skillLevel] or 0
				local hLevel = hero:getLevel() or 1
				totalGoldBonus = totalGoldBonus + (mult * hLevel)

				-- Weekly resource bonus
				if isWeekStart then
					local resType = pickResourceForHero(heroId)
					local baseAmt = math.random(1, 3)
					local amount  = DOUBLED_TYPES[resType] and (baseAmt * 2) or baseAmt
					resourceAmounts[resType] = (resourceAmounts[resType] or 0) + amount
				end
			end
		end
	end

	if totalGoldBonus > 0 then
		local pack = SetResources.new()
		pack:setPlayer(playerIdx)
		pack:setAbs(false)
		pack:setAmount(GOLD_RESOURCE, totalGoldBonus)
		SERVER:commitPackage(pack)
	end

	if isWeekStart then
		for resType, amount in pairs(resourceAmounts) do
			if amount > 0 then
				local pack = SetResources.new()
				pack:setPlayer(playerIdx)
				pack:setAbs(false)
				pack:setAmount(resType, amount)
				SERVER:commitPackage(pack)
			end
		end
	end
end)
