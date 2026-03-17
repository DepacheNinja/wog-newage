-- wog_display_map_rules.lua
-- WOG New Age — Display Map Rules (option 230)
--
-- Shows human players a summary of which WOG map-level rules are
-- active on the very first day. Separate from option 248 (which shows
-- hero/battle/skill WOG features); this message focuses on map-setup
-- rules that affect starting conditions, resource distribution, and
-- map object behaviour.

local PlayerGotTurn = require("events.PlayerGotTurn")
local InfoWindow    = require("netpacks.InfoWindow")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.displayMapRulesEnabled = C.displayMapRulesEnabled ~= false

local shownToPlayers = {}

wogDisplayMapRulesSub = PlayerGotTurn.subscribeAfter(EVENT_BUS, function(event)
	if not C.displayMapRulesEnabled then return end

	local totalDay = GAME:getDate(0)
	if totalDay ~= 1 then return end

	local playerIdx = event:getPlayer()
	if not GAME:isPlayerHuman(playerIdx) then return end
	if shownToPlayers[playerIdx] then return end
	shownToPlayers[playerIdx] = true

	local lines = {"WOG New Age — Active Map Rules:", ""}

	local function add(enabled, name)
		if enabled ~= false then
			lines[#lines + 1] = "  + " .. name
		end
	end

	-- Starting conditions
	add(C.startingArmiesEnabled,
		"Rebalanced Starting Armies: each hero receives +"
		.. (C.startingBonusCount or 8) .. " tier-1 creatures on day 1")
	add(C.firstMoneyEnabled,
		"First Money: each player receives "
		.. (C.firstMoneyAmount or 5000) .. " gold on day 1")

	-- Economy / income rules
	add(C.castleIncomeEnabled,
		"Castle Town Income: City Hall +250g/day, Capitol +500g/day")
	add(C.weeklyIncomeEnabled,
		"Daily Gold Bonus: +" .. (C.weeklyIncomeAmount or 100) .. "g/day per player")

	-- Building rules
	add(C.buildingBonusesEnabled,
		"Building Rewards: bonus resources for constructing Mage Guild 5 / Castle / Capitol")

	-- Treasure & object rules
	add(C.treasureChestsEnabled,
		"Upgraded Treasure Chests: extra +" .. (C.chestBonusAmount or 500) .. " gold or XP per chest")

	-- Witch Huts
	add(C.witchHutsEnabled,
		"Advanced Witch Huts: Witch Huts teach at Advanced level for 1000g")

	-- Special terrain
	add(C.specialTerrainEnabled,
		"Special Terrain: Magic Plains/Lucid Pools +" .. (C.magicPlainsManaRegen or 10) .. "% mana/day; Evil Fog -" .. (C.evilFogManaDrain or 10) .. "% mana/day")

	if #lines == 2 then
		lines[3] = "  (none — all map rules disabled)"
	end

	local msg = table.concat(lines, "\n")

	local pack = InfoWindow.new()
	pack:setPlayer(playerIdx)
	pack:addText(msg)
	SERVER:commitPackage(pack)
end)
