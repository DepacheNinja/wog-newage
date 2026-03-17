-- wog_artillery.lua
-- WOG New Age — Artillery I Enhanced (option 54)
--
-- ERM script54 ballista formula (FU902, line: y7 = y11 + y6 * 20 - 20):
--   extraDamagePct = (artilleryLevel + heroLevel) * 20 - 20
-- Where artilleryLevel = 1/2/3 (Basic/Advanced/Expert) and heroLevel = hero's current level.
-- Example: Level 10 hero with Basic Artillery (lvl 1):
--   (1 + 10) * 20 - 20 = 200% extra → ballista deals 3× normal on double-hit.
--
-- Implementation: subscribeAfter on ApplyDamage.
-- Uses event:isBallistaDmg() to detect ballista double-damage hits.
-- Uses event:getAttackerOwner() to find the attacking player,
-- then scans their heroes for the highest Artillery skill level.
--
-- Hero level: obtained via hero:getLevel() (confirmed available in FCMI API).
-- Falls back to C.artilleryExtraPct flat values if hero:getLevel() returns nil/0.
--
-- Note: getDamage() at subscribeAfter already includes the ballista 2× roll.
-- We add an extra % of getInitialDamage() on top.

local ApplyDamage = require("events.ApplyDamage")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

-- Fallback flat bonus % per Artillery skill level [basic, advanced, expert]
-- Used only if hero:getLevel() is unavailable.
local ARTILLERY_EXTRA_PCT = C.artilleryExtraPct or {25, 50, 75}

-- Flag: use ERM (skillLevel + heroLevel) * 20 - 20 formula when true
local HERO_LEVEL_SCALING = C.artilleryHeroLevelScaling ~= false

-- SecondarySkill IDs from wog_config.lua (Artillery = 20)
local SKILL_ARTILLERY = (C.SKILL and C.SKILL.ARTILLERY) or 20

wogArtillerySub = ApplyDamage.subscribeAfter(EVENT_BUS, function(event)
	if not (C.artilleryEnabled ~= false) then return end

	-- Only fire on ballista double-damage hits
	if not event:isBallistaDmg() then return end

	local initial = event:getInitialDamage()
	if initial <= 0 then return end

	-- Get the attacking player's index
	local attackerPlayer = event:getAttackerOwner()
	if attackerPlayer == nil or attackerPlayer < 0 or attackerPlayer > 7 then return end

	-- Find the highest Artillery skill level and corresponding hero level
	local artLevel  = 0
	local heroLevel = 1  -- default if getLevel() unavailable
	local bestHero  = nil
	local heroes = GAME:getPlayerHeroes(attackerPlayer)
	if heroes then
		for _, heroId in ipairs(heroes) do
			local hero = GAME:getHero(heroId)
			if hero then
				local lvl = hero:getSecSkillLevel(SKILL_ARTILLERY)
				if lvl > artLevel then
					artLevel = lvl
					bestHero = hero
				end
			end
		end
	end

	if artLevel <= 0 then return end

	-- Get hero level for ERM formula (hero:getLevel() confirmed available in FCMI)
	local pct = 0
	if HERO_LEVEL_SCALING and bestHero then
		local level = bestHero:getLevel()
		if level and level > 0 then
			-- ERM formula: (artilleryLevel + heroLevel) * 20 - 20
			pct = (artLevel + level) * 20 - 20
		else
			-- Fallback: hero level unavailable or 0
			pct = ARTILLERY_EXTRA_PCT[artLevel] or 0
		end
	else
		pct = ARTILLERY_EXTRA_PCT[artLevel] or 0
	end

	if pct <= 0 then return end

	local extra = math.floor(initial * pct / 100)
	if extra <= 0 then return end

	event:setDamage(event:getDamage() + extra)
end)
