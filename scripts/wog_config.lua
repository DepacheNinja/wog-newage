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
C.karmicCloseXP           = 2000   -- XP threshold for "close" battle
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

-- Luck I enhancement (option 206)
-- Lucky strikes deal extra damage on top of the 2× base lucky multiplier.
-- WOG: +50% of initial damage extra (making lucky hits ~3× normal).
C.luckEnabled             = true
C.luckExtraPct            = 50   -- extra % of initial damage added to lucky hits

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
-- COMBINED WARFARE SKILLS (option 193)
-- =====================================================================
C.combinedWarfareEnabled  = true  -- Ballistics/Artillery/FirstAid sync as one

-- Stack Experience: handled by wake-of-gods.stackExperience engine module
-- (added as dependency in mod.json). The wog_stack_experience.lua approximation
-- is disabled because the real engine module provides proper per-stack XP.
C.stackExpEnabled         = false  -- disabled: real engine module active

-- =====================================================================
-- WEEK OF MONSTERS (option 20)
-- Each week a random creature type gets a stat bonus
-- =====================================================================
C.weekOfMonstersEnabled   = false  -- disabled until EntitiesChanged API is confirmed

-- =====================================================================
-- HERO SPECIALIZATION BOOST (option 39)
-- Specialty bonuses scale better with hero level
-- =====================================================================
C.heroSpecBoostEnabled    = false  -- planned, needs specialty API

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
