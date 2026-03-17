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
C.firstMoneyAmount        = 5000   -- gold given to each hero on day 1

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
-- Extra spell points regenerated per day, ON TOP of base VCMI Mysticism.
-- Base VCMI:    Basic=2, Adv=3, Expert=4 SP/day
-- WOG Enhanced: Basic=3, Adv=5, Expert=8 SP/day
-- So this adds:     +1,    +2,      +4 SP/day
C.mysticismEnabled        = true
C.mysticismBonusSP        = {1, 2, 4}  -- [basic, advanced, expert] extra SP/day

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
