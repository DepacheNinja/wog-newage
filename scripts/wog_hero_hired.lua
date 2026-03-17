-- wog_hero_hired.lua
-- WOG New Age — Hero Hiring Enhancements (option 198 approximation)
--
-- Classic WOG: Certain heroes have their starting secondary skills
-- rebalanced to be more useful. Magic-class heroes always start with
-- Wisdom, combat heroes get more useful starting secondaries.
--
-- VCMI Approximation using HeroHired event:
--   - If hero has SpellPower > Attack and lacks Wisdom: grant Wisdom:Basic
--   - If hero has Attack >= Defense and SpellPower < 2 and lacks Offense: grant Offense:Basic
--
-- This fires after every tavern hero recruitment (not starting heroes).
-- Starting hero rebalancing is done via JSON hero type definitions.

local HeroHired  = require("events.HeroHired")
local SetSecSkill = require("netpacks.SetSecSkill")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.heroHiredEnabled = C.heroHiredEnabled ~= false

-- Secondary skill IDs
local WISDOM  = 7
local OFFENSE = 22
local ARMORER = 23

wogHeroHiredSub = HeroHired.subscribeAfter(EVENT_BUS, function(event)
	if not C.heroHiredEnabled then return end

	local heroId = event:getHero()
	local hero   = GAME:getHero(heroId)
	if not hero then return end

	local atk      = hero:getAttack()
	local def      = hero:getDefense()
	local sp       = hero:getSpellPower()
	local know     = hero:getKnowledge()

	local hasWisdom  = hero:getSecSkillLevel(WISDOM)  > 0
	local hasOffense = hero:getSecSkillLevel(OFFENSE) > 0
	local hasArmorer = hero:getSecSkillLevel(ARMORER) > 0

	-- Magic-class heuristic: spell power is their top stat
	local isMagicHero = (sp >= atk and sp >= def)

	if isMagicHero and not hasWisdom then
		-- Grant Wisdom:Basic so magic heroes can always cast spells
		local pack = SetSecSkill.new()
		pack:setHeroId(heroId)
		pack:setSkill(WISDOM)
		pack:setValue(1)   -- Basic
		pack:setMode(true) -- absolute set
		SERVER:commitPackage(pack)

	elseif not isMagicHero then
		-- Combat hero: grant Offense:Basic if attack-focused
		if atk >= def and atk >= sp and not hasOffense then
			local pack = SetSecSkill.new()
			pack:setHeroId(heroId)
			pack:setSkill(OFFENSE)
			pack:setLevel(1)
			pack:setMode(true)
			SERVER:commitPackage(pack)

		-- Defense-focused hero: grant Armorer:Basic
		elseif def > atk and not hasArmorer then
			local pack = SetSecSkill.new()
			pack:setHeroId(heroId)
			pack:setSkill(ARMORER)
			pack:setLevel(1)
			pack:setMode(true)
			SERVER:commitPackage(pack)
		end
	end
end)
