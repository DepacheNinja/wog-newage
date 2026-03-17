-- wog_hero_spec_boost.lua
-- WOG New Age — Hero Specialization Boost (option 39)
--
-- Classic WOG: Hero specialties (creature specialists, spell specialists,
-- skill specialists) scale better with hero level instead of plateauing.
--
-- Approximation: At milestone levels (5/10/15/20/25/30), heroes receive
-- an extra +1 to a "characteristic" primary skill based on their stat profile.
-- Heroes with higher ATK/DEF (warriors) get a combat stat;
-- heroes with higher SP/KNO (mages) get a magic stat.
-- Within each archetype, the boost favors the hero's actual strongest stat,
-- giving each hero type a consistent specialty-aligned bonus.
--
-- getHeroTypeId() provides the hero type for deterministic per-type behavior.

local HeroLevelUp    = require("events.HeroLevelUp")
local SetPrimarySkill = require("netpacks.SetPrimarySkill")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.heroSpecBoostEnabled = C.heroSpecBoostEnabled ~= false

-- Primary skill IDs: 0=Attack, 1=Defense, 2=SpellPower, 3=Knowledge
local ATTACK    = 0
local DEFENSE   = 1
local SPELLPOWER = 2
local KNOWLEDGE  = 3

-- Determine which primary skill to boost at a milestone level.
-- Uses hero's stat profile to pick the "characteristic" stat.
-- heroTypeId: used as tiebreaker to be deterministic per hero type.
local function chooseBoostStat(hero, heroTypeId)
	local atk  = hero:getAttack()
	local def  = hero:getDefense()
	local sp   = hero:getSpellPower()
	local kno  = hero:getKnowledge()

	local combatScore = atk + def
	local magicScore  = sp + kno

	if combatScore >= magicScore then
		-- Warrior archetype: boost the higher of ATK/DEF
		-- Use heroTypeId parity as tiebreaker for consistency
		if atk > def then
			return ATTACK
		elseif def > atk then
			return DEFENSE
		else
			return (heroTypeId % 2 == 0) and ATTACK or DEFENSE
		end
	else
		-- Mage archetype: boost the higher of SP/KNO
		if sp > kno then
			return SPELLPOWER
		elseif kno > sp then
			return KNOWLEDGE
		else
			return (heroTypeId % 2 == 0) and SPELLPOWER or KNOWLEDGE
		end
	end
end

wogHeroSpecBoostSub = HeroLevelUp.subscribeAfter(EVENT_BUS, function(event)
	if not C.heroSpecBoostEnabled then return end

	local heroId = event:getHero()
	local hero   = GAME:getHero(heroId)
	if not hero then return end

	local level = hero:getLevel()
	-- Boost only at milestone levels (5, 10, 15, 20, 25, 30)
	if level % 5 ~= 0 then return end

	-- Use hero type ID for deterministic stat selection
	local heroTypeId = GAME:getHeroTypeId(heroId) or 0

	local stat = chooseBoostStat(hero, heroTypeId)

	local pack = SetPrimarySkill.new()
	pack:setHeroId(heroId)
	pack:setSkill(stat)
	pack:setValue(1)
	pack:setMode(false)  -- relative (add 1 more)
	SERVER:commitPackage(pack)
end)
