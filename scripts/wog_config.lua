-- wog_config.lua
-- WOG New Age — Central configuration table
--
-- All WOG feature flags and tunable values are here.
-- Set any value to false to disable that feature.

DATA.WOG = DATA.WOG or {}

local C = DATA.WOG

-- =====================================================================
-- ECONOMY & RESOURCES
-- =====================================================================

-- Castle Upgrading / Town Income (option 45)
-- Bonus gold per day per town, scaling with hall tier:
--   City Hall: +250g/day, Capitol: +500g/day
C.castleIncomeEnabled    = true   -- enable town income scaling bonus
C.castleIncomeCityHall   = 250    -- gold/day per town with City Hall
C.castleIncomeCapitol    = 500    -- gold/day per town with Capitol

C.firstMoneyEnabled       = true   -- option 40: Starting gold bonus
C.firstMoneyAmount        = 5000   -- gold given to each player on day 1 (WoG default: 12000)
C.firstMoneyResources     = false  -- set true to also give classic WoG starting resources
C.firstMoneyWood          = 20     -- wood bonus if firstMoneyResources=true
C.firstMoneyOre           = 20     -- ore bonus if firstMoneyResources=true
C.firstMoneyMercury       = 10     -- mercury bonus if firstMoneyResources=true
C.firstMoneySulfur        = 10     -- sulfur bonus if firstMoneyResources=true
C.firstMoneyCrystal       = 10     -- crystal bonus if firstMoneyResources=true
C.firstMoneyGems          = 10     -- gems bonus if firstMoneyResources=true

C.weeklyIncomeEnabled     = true   -- custom: daily 100g for human players
C.weeklyIncomeAmount      = 100    -- gold per day per human player

-- =====================================================================
-- COMBAT
-- =====================================================================
C.battleAcademyEnabled    = true   -- custom: Combat Hardening (post-battle XP)
C.battleAcademyBonusPct   = 20     -- percent bonus XP after each won battle

-- Karmic Battles (option 38)
-- Close battle threshold (XP below this = close fight)
-- Winner gets +5%, loser gets consolation 10% of winner XP
C.karmicEnabled           = true
C.karmicCloseXP           = 2000   -- fallback XP threshold (when army data unavailable)
C.karmicCloseRatio        = 0.5    -- armies within 50% strength ratio = close battle
C.karmicWinnerPct         = 5      -- bonus % for winner in close battle
C.karmicLoserPct          = 10     -- consolation % for loser in close battle

-- =====================================================================
-- HERO SKILLS — ENHANCED SECONDARY SKILLS
-- =====================================================================

-- Mysticism enhancement (options 35 / 207)
-- WOG Classic: 10%/20%/30% of max SP regenerated per day (Knowledge × 10 = max SP).
-- VCMI base gives 1/2/3 SP/day flat; WOG formula subtracts that to avoid double-count.
-- Example: Knowledge=20 (200 max SP) → Expert gives 60 SP/day total.
C.mysticismEnabled        = true
C.mysticismBonusPct       = {10, 20, 30}  -- [basic, advanced, expert] % of max SP/day

-- Estates enhancement (option 203)
-- Extra gold per day per hero with Estates, scaling with hero level.
-- Formula: heroLevel × multiplier per skill level
C.estatesEnabled          = true
C.estatesLevelMultiplier  = {5, 8, 12}  -- gold × heroLevel per [basic, adv, expert]

-- Learning enhancement (options 205 / 217)
-- Extra XP gained passively per day.
-- Learning I (217):  50/100/150 XP/day
-- Learning II (205): 100/200/300 XP/day (stacks — both can be active? No, take max)
C.learningEnabled         = true
C.learningBonusXP         = {100, 200, 300}  -- XP/day per [basic, advanced, expert]

-- Scholar enhancement (option 211)
-- Weekly chance to research and learn a new spell.
-- Basic: 40% chance for level 1-2 spell
-- Advanced: 50% chance for level 1-3 spell
-- Expert: 60% chance for level 1-4 spell
C.scholarEnabled          = true
C.scholarLearnChance      = {40, 50, 60}  -- % chance to learn per [basic, advanced, expert]
C.scholarMaxSpellLevel    = {2, 3, 4}     -- max spell level to learn per [basic, advanced, expert]

-- Luck I enhancement (option 206)
-- Lucky strikes deal extra damage on top of the 2× base lucky multiplier.
-- WOG: +50% of initial damage extra (making lucky hits ~3× normal).
C.luckEnabled             = true
C.luckExtraPct            = 50   -- extra % of initial damage added to lucky hits

-- Artillery I Enhanced (option 201)
-- Ballista double-damage hits get extra bonus scaling with Artillery skill.
-- Basic: +25%, Advanced: +50%, Expert: +75% of initial damage.
C.artilleryEnabled        = true
C.artilleryExtraPct       = {25, 50, 75}  -- [basic, advanced, expert]

-- Advanced Witch Huts (option 194)
-- Witch Huts teach skills at Advanced level automatically (costs gold).
-- witchHutAutoLevel: 1=Basic (vanilla), 2=Advanced (WOG default), 3=Expert
-- witchHutUpgradeCost: {cost_for_adv, cost_for_exp} in gold
C.witchHutsEnabled        = true
C.witchHutAutoLevel       = 2      -- teach at Advanced (level 2) instead of Basic
C.witchHutUpgradeCost     = {1000, 2000}  -- [to_advanced, to_expert]

-- Treasure Chest Enhancement (option 132)
-- After visiting a chest, hero gets extra 500 gold or XP.
C.treasureChestsEnabled   = true
C.chestBonusAmount        = 500   -- gold or XP bonus per chest visit

-- =====================================================================
-- CREATURE RELATIONSHIPS (option 47)
-- =====================================================================
C.creatureRelationsEnabled = true  -- allied pair morale/XP bonuses; hate pair damage bonus
C.synergyBonusPct         = 5     -- % extra XP per active allied pair in winner's army
C.hateDamagePct           = 15    -- % extra damage when attacker hits its hated creature type

-- =====================================================================
-- COMBINED WARFARE SKILLS (option 193)
-- =====================================================================
C.combinedWarfareEnabled  = true  -- Ballistics/Artillery/FirstAid sync as one

-- Stack Experience: handled by wake-of-gods.stackExperience engine module
-- (added as dependency in mod.json). The wog_stack_experience.lua approximation
-- is disabled because the real engine module provides proper per-stack XP.
C.stackExpEnabled         = false  -- disabled: real engine module active

-- Level 7+ Creatures XP Reduction (option 245)
-- Defeating armies with tier 7 creatures gives 50% less XP to balance late-game.
C.level7XPEnabled         = true
C.level7XPReductionPct    = 50     -- percent XP reduction when fighting tier-7 army

-- =====================================================================
-- WEEK OF MONSTERS (option 20)
-- Each week a random creature type gets a stat bonus
-- =====================================================================
C.weekOfMonstersEnabled      = true   -- uses EntitiesChanged to boost creature stats each week
C.weekOfMonstersAtkBonus     = 2      -- attack bonus for week's creature (+2 = WOG classic)
C.weekOfMonstersDefBonus     = 2      -- defense bonus for week's creature (+2 = WOG classic)
C.weekOfMonstersGrowthBonus  = 1      -- extra weekly dwelling growth for the chosen creature

-- =====================================================================
-- HERO SPECIALIZATION BOOST (option 39)
-- Specialty bonuses scale better with hero level
-- =====================================================================
C.heroSpecBoostEnabled    = true   -- milestone primary skill boost at levels 5/10/15/20/25/30

-- =====================================================================
-- HERO HIRED ENHANCEMENTS (option 198 approximation)
-- =====================================================================
C.heroHiredEnabled        = true   -- give newly hired heroes a fitting secondary skill if missing

-- =====================================================================
-- BUILDING CONSTRUCTION BONUSES
-- =====================================================================
C.buildingBonusesEnabled  = true   -- reward players for constructing key buildings (Mage Guild 5, Castle, Capitol)
C.buildingBonusGuildGold    = 500   -- gold for Mage Guild 5
C.buildingBonusGuildCrystal = 3     -- crystals for Mage Guild 5
C.buildingBonusCastleGold   = 1000  -- gold for Castle
C.buildingBonusCapitolGold  = 2000  -- gold for Capitol
C.buildingBonusCapitolRare  = 5     -- quantity of each rare resource (mercury/sulfur/crystal/gems) for Capitol

-- =====================================================================
-- SPECIAL TERRAIN EFFECTS (option 142)
-- =====================================================================
C.specialTerrainEnabled  = true   -- enable WOG special terrain daily effects
C.magicPlainsManaRegen   = 10     -- % of max mana regenerated/day on Magic Plains
C.lucidPoolsManaRegen    = 10     -- % of max mana regenerated/day on Lucid Pools
C.evilFogManaDrain       = 10     -- % of current mana drained/day in Evil Fog
C.rockLandXPBonus        = 50     -- flat XP bonus/day on Rock Land terrain
C.holyGroundManaPct      = 5      -- % mana regen for non-Necro heroes / drain for Necro heroes on Holy Ground

-- =====================================================================
-- DISPLAY MAP RULES (option 230)
-- =====================================================================
C.displayMapRulesEnabled  = true   -- show active map rules to human players on day 1

-- =====================================================================
-- REBALANCED STARTING ARMIES (option 199)
-- =====================================================================
C.startingArmiesEnabled  = true   -- give starting heroes a small troop bonus on day 1
C.startingBonusCount     = 8      -- tier-1 creatures to add per hero
C.startingBonusSlot      = 6      -- army slot to fill (0-6; slot 6 = last slot)

-- =====================================================================
-- NEUTRAL STACK EXPERIENCE (option 231)
-- =====================================================================
-- Wandering neutral stacks gain "experience" when they defeat a hero.
-- Approximated as a stack count growth bonus (true stat boost not possible without
-- engine-level bonus support for map creature objects).
C.neutralStackExpEnabled   = true   -- enable neutral victory growth
C.neutralVictoryGrowthPct  = 20     -- % stack size bonus when neutral defeats a hero

-- =====================================================================
-- ENHANCED MONSTERS (option 50)
-- =====================================================================
-- Wandering monster stacks grow over time if not defeated.
-- monsterWeeklyGrowthPct: percent growth per week (WOG default: +10%/week)
-- monsterMaxMultiplier: hard cap as multiple of day-1 stack count (default: 3×)
C.enhancedMonstersEnabled  = true   -- enable weekly neutral stack growth
C.monsterWeeklyGrowthPct   = 10     -- % growth per week for surviving stacks
C.monsterMaxMultiplier     = 3      -- cap: never exceed this multiple of day-1 count

-- =====================================================================
-- NEUTRAL UNITS (option 57)
-- =====================================================================
-- Controls wandering monster stack sizes at game start.
-- neutralSizeMultPct: percent multiplier applied to all Obj::MONSTER stack counts.
--   100 = unchanged (vanilla), 150 = +50% more monsters (WOG default).
C.neutralUnitsEnabled  = true   -- scale neutral wandering monster stacks on day 1
C.neutralSizeMultPct   = 150    -- % of base count (150 = 1.5x stack size; WOG classic: +50%)

-- =====================================================================
-- ENHANCED PROTECTION FROM ELEMENTS (option 61)
-- =====================================================================
-- Extends Protection spells to reduce physical damage from opposing elementals.
-- Fire Elementals vs protectFire, Air Elementals vs protectAir, etc.
C.protectionElementsEnabled   = true  -- enable elemental protection damage reduction
C.protectionReductionPct      = 35    -- % physical damage reduced when protected (35% = midpoint of basic 30% / adv 50%)

-- =====================================================================
-- REPLACE DRAGON FLY (option 165)
-- =====================================================================
-- On day 1, adventure-map dwellings that contain Dragon Fly or Fire Dragon Fly
-- are replaced with Wyvern dwellings.
C.replaceDragonFlyEnabled = true   -- replace dragon fly dwellings with wyvernId on day 1

-- =====================================================================
-- GHOST SPAWNS — SOME LEVEL 3S → GHOSTS (option 242)
-- =====================================================================
-- On day 1, approximately 1 in ghostSpawnFraction tier-3 creature dwellings
-- on the adventure map are replaced with WOG Ghost dwellings.
C.ghostSpawnsEnabled   = true   -- replace some tier-3 dwellings with ghosts on day 1
C.ghostSpawnFraction   = 3      -- replace 1 in N tier-3 neutral dwellings (3 = ~33%)

-- =====================================================================
-- REFUGEE CAMP SYNC (option 200)
-- =====================================================================
-- Synchronizes all Refugee Camps weekly to offer the same creature type.
-- Uses the first camp's creature as the reference for all others.
C.refugeeCampSyncEnabled = true   -- sync all refugee camps to same creature type each week

-- =====================================================================
-- UPGRADED DWELLINGS (option 133)
-- =====================================================================
-- On day 1, starting towns automatically receive the upgraded version of
-- any basic dwelling already built (e.g., Imp Crucible → Brimstone Stalls).
C.upgradedDwellingsEnabled = true   -- give starting towns upgraded dwellings on day 1

-- =====================================================================
-- ESPIONAGE (option 58)
-- =====================================================================
-- Heroes with Advanced/Expert Scouting generate weekly intelligence reports
-- about enemy hero locations. Advanced: count only; Expert: positions (x, y).
C.espionageEnabled = true   -- enable weekly scouting intelligence reports

-- =====================================================================
-- WANDERING MONSTERS (option 135)
-- =====================================================================
-- Surviving neutral monster stacks move 1-2 tiles each week, making the map
-- feel more alive. Movement is random with passability checks.
-- wanderingMonstersChancePct: % chance each stack moves per week
-- wanderingMonstersMaxRange: max tiles moved per step (1 or 2)
C.wanderingMonstersEnabled   = true  -- enable weekly monster wandering
C.wanderingMonstersChancePct = 33    -- % chance each surviving stack moves per week
C.wanderingMonstersMaxRange  = 2     -- max tiles of movement per step

-- =====================================================================
-- BATTLE EXTENDER (option 220)
-- =====================================================================
C.battleExtenderEnabled    = true   -- give gold refund to losers who escape/surrender
C.battleExtenderRefundGold = 1000   -- gold refunded when hero retreats or surrenders

-- =====================================================================
-- DISPLAY WOGIFICATION MESSAGES (option 248)
-- =====================================================================
C.displayFeaturesEnabled  = true   -- show active WOG features to human players on day 1

-- =====================================================================
-- SKILL IDs (SecondarySkill enum values from VCMI engine)
-- Used by skill enhancement scripts.
-- =====================================================================
C.SKILL = {
	PATHFINDING  = 0,
	ARCHERY      = 1,
	LOGISTICS    = 2,
	SCOUTING     = 3,
	DIPLOMACY    = 4,
	NAVIGATION   = 5,
	LEADERSHIP   = 6,
	WISDOM       = 7,
	MYSTICISM    = 8,
	LUCK         = 9,
	BALLISTICS   = 10,
	EAGLE_EYE    = 11,
	NECROMANCY   = 12,
	ESTATES      = 13,
	FIRE_MAGIC   = 14,
	AIR_MAGIC    = 15,
	WATER_MAGIC  = 16,
	EARTH_MAGIC  = 17,
	SCHOLAR      = 18,
	TACTICS      = 19,
	ARTILLERY    = 20,
	LEARNING     = 21,
	OFFENCE      = 22,
	ARMORER      = 23,
	INTELLIGENCE = 24,
	SORCERY      = 25,
	RESISTANCE   = 26,
	FIRST_AID    = 27,
}
