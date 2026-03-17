-- wog_display_features.lua
-- WOG New Age — Display WoGification Messages (option 248)
--
-- Shows human players a summary of which WOG features are active
-- on the very first day of a new game (day 1, week 1, month 1).
-- Mimics the classic WOG intro message listing enabled options.

local PlayerGotTurn = require("events.PlayerGotTurn")
local InfoWindow    = require("netpacks.InfoWindow")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.displayFeaturesEnabled = C.displayFeaturesEnabled ~= false

-- Only show once per player per session (game day 1)
local shownToPlayers = {}

wogDisplayFeaturesSub = PlayerGotTurn.subscribeAfter(EVENT_BUS, function(event)
	if not C.displayFeaturesEnabled then return end

	-- Only on the very first turn of the game
	local totalDay = GAME:getDate(0)
	if totalDay ~= 1 then return end

	local playerIdx = event:getPlayer()
	if not GAME:isPlayerHuman(playerIdx) then return end
	if shownToPlayers[playerIdx] then return end
	shownToPlayers[playerIdx] = true

	-- Build active feature list
	local lines = {"WOG New Age — Active Features:", ""}

	local function add(enabled, name)
		if enabled ~= false then
			lines[#lines + 1] = "  + " .. name
		end
	end

	-- Economy
	add(C.firstMoneyEnabled,        "First Money (+" .. (C.firstMoneyAmount or 12000) .. " gold + resources on day 1)")
	add(C.weeklyIncomeEnabled,       "Daily Gold Bonus (+" .. (C.weeklyIncomeAmount or 100) .. "g/day)")
	add(C.castleIncomeEnabled,       "Castle Town Income (City Hall +250g, Capitol +500g/day)")

	-- Combat
	add(C.battleAcademyEnabled,      "Combat Hardening (+" .. (C.battleAcademyBonusPct or 20) .. "% XP per won battle)")
	add(C.karmicEnabled,             "Combat Veteran Bonus (custom: close fights: +5% winner, +10% loser XP)")
	add(C.level7XPEnabled,           "Level 7+ Creatures XP Reduction (-" .. (C.level7XPReductionPct or 50) .. "% XP vs tier-7 armies)")
	add(C.luckEnabled,               "Luck Enhancement (lucky hits deal +" .. (C.luckExtraPct or 50) .. "% extra damage)")
	add(C.artilleryEnabled,          "Artillery Enhancement (Ballista double-hits +25/50/75% extra)")
	add(C.battleExtenderEnabled,     "Battle Extender (escape/surrender: " .. (C.battleExtenderRefundGold or 1000) .. " gold refund)")
	add(C.combinedWarfareEnabled,    "Combined Warfare Skills (Ballistics+Artillery+FirstAid synced)")

	-- Hero Skills
	add(C.mysticismEnabled,          "Mysticism Enhancement (10/20/30% max SP/day)")
	add(C.estatesEnabled,            "Estates Enhancement (gold × hero level × multiplier/day)")
	add(C.learningEnabled,           "Learning Enhancement (100/200/300 XP/day)")
	add(C.scholarEnabled,            "Scholar Enhancement (weekly spell research 40/50/60%)")
	add(C.witchHutsEnabled,          "Advanced Witch Huts (teaches at Advanced level for 1000g)")
	add(C.espionageEnabled,          "Espionage (Adv. Scouting: enemy hero count/week; Expert: positions)")
	add(C.heroSpecBoostEnabled,      "Hero Specialization Boost (+1 primary skill at milestone levels)")
	add(C.heroHiredEnabled,          "Hero Hiring Enhancement (newly hired heroes gain a fitting secondary skill)")
	add(C.creatureRelationsEnabled,  "Creature Relationships (hate pairs: daily intra-army conflict; allied pairs: +1 morale + synergy XP)")
	add(C.protectionElementsEnabled, "Enhanced Protection from Elements (protection spells reduce elemental physical attacks by " .. (C.protectionReductionPct or 35) .. "%)")

	-- Starting conditions & map rules
	add(C.upgradedDwellingsEnabled,  "Upgraded Dwellings (starting towns receive upgraded creature dwellings on day 1)")
	add(C.startingArmiesEnabled,     "Rebalanced Starting Armies (+" .. (C.startingBonusCount or 8) .. " tier-1 troops per hero on day 1)")
	add(C.specialTerrainEnabled,     "Special Terrain Effects (Magic Plains/Lucid Pools: +" .. (C.magicPlainsManaRegen or 10) .. "% mana/day; Evil Fog: -10% mana/day)")
	add(C.displayMapRulesEnabled,    "Display Map Rules (shows active map-level rules on day 1)")
	add(C.replaceDragonFlyEnabled,   "Replace Dragon Fly (dragon fly dwellings → wyvern on day 1)")
	add(C.ghostSpawnsEnabled,        "Ghost Spawns (1 in " .. (C.ghostSpawnFraction or 3) .. " tier-3 neutral dwellings → Ghost on day 1)")
	add(C.refugeeCampSyncEnabled,    "Refugee Camp Sync (all refugee camps offer same creature each week)")

	-- Creatures
	add(C.enhancedMonstersEnabled,   "Enhanced Monsters (neutral stacks grow +" .. (C.monsterWeeklyGrowthPct or 10) .. "%/week, cap " .. (C.monsterMaxMultiplier or 3) .. "×)")
	add(C.neutralStackExpEnabled,    "Neutral Stack Experience (neutral stacks grow +" .. (C.neutralVictoryGrowthPct or 20) .. "% when they defeat a hero)")
	add(C.neutralUnitsEnabled,       "Neutral Units (wandering monster stacks scaled to " .. (C.neutralSizeMultPct or 150) .. "% on day 1)")
	add(C.weekOfMonstersEnabled,     "Week of Monsters (+33% ATK/DEF/Speed/HP/Dmg, +50% growth; week 1 skipped)")
	add(C.wanderingMonstersEnabled,  "Wandering Monsters (surviving stacks move " .. (C.wanderingMonstersMaxRange or 2) .. " tiles/week, " .. (C.wanderingMonstersChancePct or 33) .. "% chance)")
	add(C.buildingBonusesEnabled,    "Building Bonuses (rewards for Mage Guild 5, Castle, Capitol)")

	-- Treasure
	add(C.treasureChestsEnabled,     "Upgrading Treasure Chests (extra 500 gold or XP per chest)")

	-- War Machines & Map Objects
	add(C.warMachinesEnabled,        "Enhanced War Machines I (Ballista attacks twice at Basic, 3× at Expert; First Aid heals double)")
	add(C.deathChamberEnabled,       "Death Chamber (map object — hero visits to gain 1 level; must be placed by mapmaker)")

	local msg = table.concat(lines, "\n")

	local pack = InfoWindow.new()
	pack:setPlayer(playerIdx)
	pack:addText(msg)
	SERVER:commitPackage(pack)
end)
