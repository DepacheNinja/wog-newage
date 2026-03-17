-- wog_week_of_monsters.lua
-- WOG New Age — Week of Monsters (option 20)
--
-- Each week, one random creature type is the "Monster of the Week":
--   - Gets +WOM_ATK_BONUS attack and +WOM_DEF_BONUS defense for that week
--   - Gets +WOM_GROWTH_BONUS extra weekly growth in their dwelling
--   - Classic WOG: +2 ATK / +2 DEF, +1 growth
--   - Players are notified at start of each week which creature is boosted
--
-- Implementation:
--   On TurnStarted (day 1 of week):
--     1. Restore previous week's creature to its original stats/growth
--     2. Pick a new random creature from the eligible list
--     3. Read current stats and store them for restoration next week
--     4. Apply the boost via EntitiesChanged
--   On PlayerGotTurn (day 1 of week): announce WOM creature to each human player

local TurnStarted      = require("events.TurnStarted")
local PlayerGotTurn    = require("events.PlayerGotTurn")
local Metatype         = require("core:Metatype")
local EntitiesChanged  = require("netpacks.EntitiesChanged")
local InfoWindow       = require("netpacks.InfoWindow")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

-- Stat bonus given to the week's creature
local WOM_ATK_BONUS    = C.weekOfMonstersAtkBonus    or 2
local WOM_DEF_BONUS    = C.weekOfMonstersDefBonus    or 2
local WOM_GROWTH_BONUS = C.weekOfMonstersGrowthBonus or 1

-- Tier 1-6 eligible creature list (base IDs, 0-indexed)
-- Only non-tier-7, non-unique creatures in standard H3+WOG
local ELIGIBLE_CREATURES = {
	-- Castle
	0, 1, 2, 3, 4, 5,       -- Pikeman/Halberdier, Archer/Marksman, Griffin/Royal Griffin
	6, 7, 8, 9, 10, 11,     -- Swordsman/Crusader, Monk/Zealot, Cavalier/Champion
	-- Rampart
	21, 22, 23, 24, 25, 26, -- Centaur/Capt, Dwarf/BattleDwarf, Wood Elf/Grand Elf
	27, 28, 29, 30,          -- Pegasus/Silver, Dendroid Guard/Soldier
	-- Tower
	42, 43, 44, 45, 46, 47, -- Gremlin/Master, Stone Gargoyle/Obsidian, Stone/Iron Golem
	48, 49, 50, 51,          -- Mage/Arch Mage, Genie/Master Genie
	-- Inferno
	56, 57, 58, 59, 60, 61, -- Imp/Familiar, Gog/Magog, HellHound/Cerberus
	62, 63, 64, 65,          -- Demon/HornedDemon, Pit Fiend/Pit Lord
	-- Necropolis
	70, 71, 72, 73, 74, 75, -- Skeleton/Warrior, WalkingDead/Zombie, Wight/Wraith
	76, 77, 78, 79,          -- Vampire/Lord, Lich/PowerLich
	-- Dungeon
	84, 85, 86, 87, 88, 89, -- Troglodyte/Infernal, Harpy/Hag, Beholder/EvilEye
	90, 91, 92, 93,          -- Medusa/Queen, Minotaur/King
	-- Fortress
	98, 99, 100, 101, 102, 103, -- Gnoll/Marauder, Lizardman/Lancer, Serpentfly/Dragonfly
	104, 105, 106, 107,      -- Basilisk/Greater, Gorgon/Mighty
	-- Conflux
	112, 113, 114, 115, 116, 117, -- Pixie/Sprite, Air/StormElemental, Water/IceElemental
	118, 119, 120, 121,      -- Fire/EnergyElemental, Earth/MagmaElemental
	-- Neutral
	133, 134, 135, 136,      -- Halfling, Halfling Grenadier, Peasant, Boar
}

-- Internal state: previous week's creature and its original stats
C.weekMonster             = nil
C.weekMonsterOrigAtk      = nil
C.weekMonsterOrigDef      = nil
C.weekMonsterOrigGrowth   = nil
C.weekMonsterName         = nil  -- cached creature name for announcements

local function applyCreatureBoost(creatureId, atk, def, growth)
	local pack = EntitiesChanged.new()
	pack:update(Metatype.CREATURE, creatureId, {config = {attack = atk, defense = def, growth = growth}})
	SERVER:commitPackage(pack)
end

local function weekRandom(seed)
	-- Simple deterministic hash from seed to pick creature index
	local h = seed * 1103515245 + 12345
	h = h % 2147483648
	return (h % #ELIGIBLE_CREATURES) + 1
end

wogWeekOfMonstersSub = TurnStarted.subscribeAfter(EVENT_BUS, function(event)
	if not (C.weekOfMonstersEnabled ~= false) then return end

	local dayOfWeek = GAME:getDate(1)
	if dayOfWeek ~= 1 then return end

	-- Step 1: Restore previous creature to original stats
	if C.weekMonster ~= nil and C.weekMonsterOrigAtk ~= nil then
		applyCreatureBoost(C.weekMonster, C.weekMonsterOrigAtk, C.weekMonsterOrigDef, C.weekMonsterOrigGrowth or 0)
	end

	-- Step 2: Pick this week's creature
	local totalDay   = GAME:getDate(0)
	local idx        = weekRandom(totalDay)
	local creatureId = ELIGIBLE_CREATURES[idx]

	-- Step 3: Read current stats via creature service
	local creatures  = SERVICES:creatures()
	local creature   = creatures:getByIndex(creatureId)
	if not creature then
		C.weekMonster     = nil
		C.weekMonsterName = nil
		return
	end

	local origAtk    = creature:getBaseAttack()
	local origDef    = creature:getBaseDefense()
	local origGrowth = creature:getGrowth()

	-- Step 4: Apply stat + growth boost
	applyCreatureBoost(creatureId,
		origAtk + WOM_ATK_BONUS,
		origDef + WOM_DEF_BONUS,
		origGrowth + WOM_GROWTH_BONUS)

	-- Store for next week's restoration and announcement
	C.weekMonster           = creatureId
	C.weekMonsterOrigAtk    = origAtk
	C.weekMonsterOrigDef    = origDef
	C.weekMonsterOrigGrowth = origGrowth
	C.weekMonsterName       = creature:getPluralName()
end)

-- Announce the Week of Monsters creature to each human player
wogWeekOfMonstersAnnounceSub = PlayerGotTurn.subscribeAfter(EVENT_BUS, function(event)
	if not (C.weekOfMonstersEnabled ~= false) then return end
	if not C.weekMonsterName then return end

	local dayOfWeek = GAME:getDate(1)
	if dayOfWeek ~= 1 then return end

	local playerIdx = event:getPlayer()
	if not GAME:isPlayerHuman(playerIdx) then return end

	local atk    = C.weekOfMonstersAtkBonus    or 2
	local def    = C.weekOfMonstersDefBonus    or 2
	local growth = C.weekOfMonstersGrowthBonus or 1
	local msg = "Week of Monsters: " .. C.weekMonsterName
		.. string.format(" are stronger (+%d ATK/+%d DEF) and more numerous (+%d growth) this week!", atk, def, growth)

	local pack = InfoWindow.new()
	pack:setPlayer(playerIdx)
	pack:addText(msg)
	SERVER:commitPackage(pack)
end)
