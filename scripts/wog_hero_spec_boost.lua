-- wog_hero_spec_boost.lua
-- WOG New Age — Hero Specialization Boost (option 39)
--
-- Classic WOG: Hero specialties (creature specialists, spell specialists,
-- skill specialists) scale better with hero level instead of plateauing.
--
-- Example: A Creature Specialist's bonus scales as:
--   WOG: 5% * hero_level instead of a fixed 5% + fractional growth
--
-- VCMI LIMITATION: Specialty bonuses are defined at hero creation time
-- in JSON config (heroTypes). Dynamic scaling based on hero level requires
-- either:
--   1. A recalculate-on-level mechanic (needs engine support)
--   2. Periodic primary skill boosts based on specialty type (approximation)
--
-- Approximation: On each hero level-up, if the hero has a creature specialty,
-- give them a small primary skill bonus to simulate improved specialization.
-- This is not the exact WOG formula but creates the scaling feel.

local HeroLevelUp    = require("events.HeroLevelUp")
local SetPrimarySkill = require("netpacks.SetPrimarySkill")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.heroSpecBoostEnabled = C.heroSpecBoostEnabled ~= false

-- Primary skill IDs: 0=Attack, 1=Defense, 2=SpellPower, 3=Knowledge
local ATTACK    = 0
local DEFENSE   = 1
local SPELLPOWER = 2

wogHeroSpecBoostSub = HeroLevelUp.subscribeAfter(EVENT_BUS, function(event)
	if not C.heroSpecBoostEnabled then return end

	local heroId = event:getHero()
	local hero   = GAME:getHero(heroId)
	if not hero then return end

	local level = hero:getLevel()
	-- Boost only at milestone levels (5, 10, 15, 20, 25, 30)
	if level % 5 ~= 0 then return end

	-- Give +1 to primary skill gained this level (simulate specialty scaling)
	local primGained = event:getPrimarySkillGained()
	-- primGained: 0=Attack, 1=Defense, 2=SpellPower, 3=Knowledge
	if primGained >= 0 and primGained <= 3 then
		local pack = SetPrimarySkill.new()
		pack:setHeroId(heroId)
		pack:setSkill(primGained)
		pack:setValue(1)
		pack:setMode(false)  -- relative (add 1 more)
		SERVER:commitPackage(pack)
	end
end)
