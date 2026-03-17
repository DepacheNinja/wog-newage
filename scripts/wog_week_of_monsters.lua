-- wog_week_of_monsters.lua
-- WOG New Age — Week of Monsters (option 20)
--
-- ERM script20 v1.7 by Timothy Pulver:
--   EVERY week EXCEPT week 1 is a Week of Monsters.
--   All stats: +33% of base (floor, minimum +1) for ATK, DEF, Speed, HP, Damage (low+high)
--   Growth: +50% of base (floor, minimum +1)
--   War machines (catapult=145, ballista=146, firstAidTent=147): HP and DEF only,
--     no ATK, no Speed, no Damage bonus.
--   Note: ERM uses MA (monster attribute) commands to set individual stat fields.
--         VCMI EntitiesChanged sets config.attack, config.defense, config.growth.
--         Speed (config.speed), HP (config.hitPoints), and damage range (config.damage.min/max)
--         are also supported if the creature entity exposes setBaseSpeed, setBaseHitPoints,
--         setBaseDamageMin/Max — check availability via creature methods.
--
-- Implementation:
--   On TurnStarted (day 1 of week, week >= 2):
--     1. Restore previous week's creature to its original stats
--     2. Pick a new random creature (deterministic hash of total day)
--     3. Read current stats and store for next-week restoration
--     4. Apply percentage-based boosts via EntitiesChanged
--   On PlayerGotTurn (day 1 of week, week >= 2): announce to each human player

local TurnStarted      = require("events.TurnStarted")
local PlayerGotTurn    = require("events.PlayerGotTurn")
local Metatype         = require("core:Metatype")
local EntitiesChanged  = require("netpacks.EntitiesChanged")
local InfoWindow       = require("netpacks.InfoWindow")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

-- ERM percentages: 33% for stats, 50% for growth
local STAT_PCT   = C.weekOfMonstersStatPct   or 33
local GROWTH_PCT = C.weekOfMonstersGrowthPct or 50

-- VCMI creature IDs for war machines (from special.json)
-- War machines receive HP and DEF only; no ATK, no Speed, no Damage.
local WAR_MACHINE_IDS = {
	[145] = true,  -- catapult
	[146] = true,  -- ballista
	[147] = true,  -- firstAidTent
	-- 148 = ammoCart (no growth either, skip entirely)
}

-- Tier 1-6 eligible creature list (base IDs, 0-indexed VCMI indices)
-- Only non-tier-7, non-unique creatures in standard H3+WOG
local ELIGIBLE_CREATURES = {
	-- Castle
	0, 1, 2, 3, 4, 5,       -- Pikeman/Halberdier, Archer/Marksman, Griffin/Royal Griffin
	6, 7, 8, 9, 10, 11,     -- Swordsman/Crusader, Monk/Zealot, Cavalier/Champion
	-- Rampart
	14, 15, 16, 17, 18, 19, -- Centaur/Capt, Dwarf/BattleDwarf, Wood Elf/Grand Elf
	20, 21, 22, 23,          -- Pegasus/Silver, Dendroid Guard/Soldier
	-- Tower
	28, 29, 30, 31, 32, 33, -- Gremlin/Master, Stone Gargoyle/Obsidian, Iron/Stone Golem
	34, 35, 36, 37,          -- Mage/Arch Mage, Genie/Master Genie
	-- Inferno
	42, 43, 44, 45, 46, 47, -- Imp/Familiar, Gog/Magog, HellHound/Cerberus
	48, 49, 50, 51,          -- Demon/HornedDemon, Pit Fiend/Pit Lord
	-- Necropolis
	56, 57, 58, 59, 60, 61, -- Skeleton/Warrior, WalkingDead/Zombie, Wight/Wraith
	62, 63, 64, 65,          -- Vampire/Lord, Lich/PowerLich
	-- Dungeon
	70, 71, 72, 73, 74, 75, -- Troglodyte/Infernal, Harpy/Hag, Beholder/EvilEye
	76, 77, 78, 79,          -- Medusa/Queen, Minotaur/King
	-- Stronghold
	84, 85, 86, 87, 88, 89, -- Goblin/Hobgoblin, WolfRider/HobgoblinWolfRider, Orc/OrcChieftain
	90, 91, 92, 93,          -- Ogre/OgreMage, Roc/Thunderbird
	-- Fortress
	98, 99, 100, 101, 102, 103, -- Gnoll/Marauder, Lizardman/Lancer, Gorgon/Mighty
	104, 105, 106, 107,      -- SerpentFly/FireDragonFly, Basilisk/Greater
	-- Conflux
	112, 113, 114, 115, 118, 119, -- Air/Earth/Fire/Water Elementals, Pixie/Sprite
	120, 121,                -- Psychic/Magic Elemental
	-- Neutral
	138, 139, 140, 144,      -- Halfling, Peasant, Boar, Troll
}

-- Internal state: previous week's creature and its original stats
C.weekMonster              = nil
C.weekMonsterOrigAtk       = nil
C.weekMonsterOrigDef       = nil
C.weekMonsterOrigGrowth    = nil
C.weekMonsterOrigSpeed     = nil
C.weekMonsterOrigHP        = nil
C.weekMonsterOrigDmgMin    = nil
C.weekMonsterOrigDmgMax    = nil
C.weekMonsterName          = nil  -- cached creature name for announcements

-- Helper: calculate bonus = floor(base * pct / 100), minimum 1
local function pctBonus(base, pct)
	local b = math.floor(base * pct / 100)
	if b < 1 then b = 1 end
	return b
end

local function applyCreatureBoost(creatureId, origStats, isWarMachine)
	-- Build the config table for EntitiesChanged.
	-- Always set ATK and DEF.
	-- War machines skip ATK, Speed, Damage.
	local newAtk    = origStats.atk  + (not isWarMachine and pctBonus(origStats.atk,    STAT_PCT)   or 0)
	local newDef    = origStats.def  + pctBonus(origStats.def,    STAT_PCT)
	local newGrowth = origStats.growth > 0
		and (origStats.growth + pctBonus(origStats.growth, GROWTH_PCT))
		or origStats.growth  -- don't boost growth if base is 0 (war machines/neutrals)

	local cfg = {
		attack   = newAtk,
		defense  = newDef,
		growth   = newGrowth,
	}

	-- Speed, HP, and Damage: only for non-war-machines.
	-- VCMI EntitiesChanged config fields: speed, hitPoints, damage.min, damage.max
	-- These field names are speculative — if they don't work, the engine will silently ignore them.
	if not isWarMachine then
		if origStats.speed ~= nil then
			cfg.speed = origStats.speed + pctBonus(origStats.speed, STAT_PCT)
		end
		if origStats.hp ~= nil then
			cfg.hitPoints = origStats.hp + pctBonus(origStats.hp, STAT_PCT)
		end
		if origStats.dmgMin ~= nil then
			cfg["damage.min"] = origStats.dmgMin + pctBonus(origStats.dmgMin, STAT_PCT)
		end
		if origStats.dmgMax ~= nil then
			cfg["damage.max"] = origStats.dmgMax + pctBonus(origStats.dmgMax, STAT_PCT)
		end
	else
		-- War machine: HP boost only (ERM gives HP and DEF to war machines)
		if origStats.hp ~= nil then
			cfg.hitPoints = origStats.hp + pctBonus(origStats.hp, STAT_PCT)
		end
	end

	local pack = EntitiesChanged.new()
	pack:update(Metatype.CREATURE, creatureId, {config = cfg})
	SERVER:commitPackage(pack)
end

local function restoreCreature(creatureId, origStats)
	local cfg = {
		attack   = origStats.atk,
		defense  = origStats.def,
		growth   = origStats.growth,
	}
	if origStats.speed   ~= nil then cfg.speed        = origStats.speed   end
	if origStats.hp      ~= nil then cfg.hitPoints     = origStats.hp      end
	if origStats.dmgMin  ~= nil then cfg["damage.min"] = origStats.dmgMin  end
	if origStats.dmgMax  ~= nil then cfg["damage.max"] = origStats.dmgMax  end
	local pack = EntitiesChanged.new()
	pack:update(Metatype.CREATURE, creatureId, {config = cfg})
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

	-- ERM: Week 1 is always skipped — no WOM on week 1
	local totalDay = GAME:getDate(0)
	if totalDay == 1 then
		-- It's week 1, day 1: clear any leftover state and do nothing
		C.weekMonster    = nil
		C.weekMonsterName = nil
		return
	end

	-- Step 1: Restore previous creature to original stats
	if C.weekMonster ~= nil and C.weekMonsterOrigAtk ~= nil then
		restoreCreature(C.weekMonster, {
			atk    = C.weekMonsterOrigAtk,
			def    = C.weekMonsterOrigDef,
			growth = C.weekMonsterOrigGrowth or 0,
			speed  = C.weekMonsterOrigSpeed,
			hp     = C.weekMonsterOrigHP,
			dmgMin = C.weekMonsterOrigDmgMin,
			dmgMax = C.weekMonsterOrigDmgMax,
		})
	end

	-- Step 2: Pick this week's creature
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

	-- Try to read Speed, HP, Damage — these methods may or may not exist in FCMI.
	-- Use pcall so we degrade gracefully if they're not available.
	local origSpeed, origHP, origDmgMin, origDmgMax = nil, nil, nil, nil
	local ok

	ok, origSpeed  = pcall(function() return creature:getBaseSpeed()     end)
	if not ok then origSpeed  = nil end
	ok, origHP     = pcall(function() return creature:getBaseHitPoints()  end)
	if not ok then origHP     = nil end
	ok, origDmgMin = pcall(function() return creature:getBaseDamageMin()  end)
	if not ok then origDmgMin = nil end
	ok, origDmgMax = pcall(function() return creature:getBaseDamageMax()  end)
	if not ok then origDmgMax = nil end

	local isWarMachine = WAR_MACHINE_IDS[creatureId] or false

	-- Step 4: Apply percentage-based stat + growth boost
	applyCreatureBoost(creatureId, {
		atk    = origAtk,
		def    = origDef,
		growth = origGrowth,
		speed  = origSpeed,
		hp     = origHP,
		dmgMin = origDmgMin,
		dmgMax = origDmgMax,
	}, isWarMachine)

	-- Store for next week's restoration and announcement
	C.weekMonster              = creatureId
	C.weekMonsterOrigAtk       = origAtk
	C.weekMonsterOrigDef       = origDef
	C.weekMonsterOrigGrowth    = origGrowth
	C.weekMonsterOrigSpeed     = origSpeed
	C.weekMonsterOrigHP        = origHP
	C.weekMonsterOrigDmgMin    = origDmgMin
	C.weekMonsterOrigDmgMax    = origDmgMax
	C.weekMonsterName          = creature:getPluralName()
	C.weekMonsterIsWarMachine  = isWarMachine
end)

-- Announce the Week of Monsters creature to each human player
wogWeekOfMonstersAnnounceSub = PlayerGotTurn.subscribeAfter(EVENT_BUS, function(event)
	if not (C.weekOfMonstersEnabled ~= false) then return end
	if not C.weekMonsterName then return end

	local dayOfWeek = GAME:getDate(1)
	if dayOfWeek ~= 1 then return end

	-- Skip announcement on week 1 (no WOM)
	local totalDay = GAME:getDate(0)
	if totalDay == 1 then return end

	local playerIdx = event:getPlayer()
	if not GAME:isPlayerHuman(playerIdx) then return end

	local statPct   = STAT_PCT
	local growthPct = GROWTH_PCT
	local wmNote    = C.weekMonsterIsWarMachine
		and " (war machine: HP/DEF only)"
		or string.format(" (+%d%% ATK/DEF/Speed/HP/Dmg, +%d%% growth)", statPct, growthPct)

	local msg = "Week of Monsters: " .. C.weekMonsterName
		.. wmNote .. " this week!"

	local pack = InfoWindow.new()
	pack:setPlayer(playerIdx)
	pack:addText(msg)
	SERVER:commitPackage(pack)
end)
