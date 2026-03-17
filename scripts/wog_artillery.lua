-- wog_artillery.lua
-- WOG New Age — Artillery I Enhanced (option 201)
--
-- Classic WOG: With Artillery skill, the Ballista deals enhanced damage.
-- WOG Enhancement: When the Ballista rolls its double-damage hit, add an
-- extra bonus on top, scaling with Artillery skill level.
--   Basic:    +25% of initial damage
--   Advanced: +50% of initial damage
--   Expert:   +75% of initial damage
--
-- Implementation: subscribeAfter on ApplyDamage.
-- Uses event:isBallistaDmg() to detect ballista double-damage hits.
-- Uses event:getAttackerOwner() to find the attacking player,
-- then scans their heroes for the highest Artillery skill level.
-- Falls back gracefully if no Artillery found.
--
-- Note: getDamage() at subscribeAfter already includes the ballista 2× roll.
-- We add an extra % of getInitialDamage() on top.

local ApplyDamage = require("events.ApplyDamage")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

-- Extra bonus percentage per Artillery skill level [basic, advanced, expert]
local ARTILLERY_EXTRA_PCT = C.artilleryExtraPct or {25, 50, 75}

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

	-- Find the highest Artillery skill level among this player's heroes
	local artLevel = 0
	local heroes = GAME:getPlayerHeroes(attackerPlayer)
	if heroes then
		for _, heroId in ipairs(heroes) do
			local hero = GAME:getHero(heroId)
			if hero then
				local lvl = hero:getSecSkillLevel(SKILL_ARTILLERY)
				if lvl > artLevel then artLevel = lvl end
			end
		end
	end

	if artLevel <= 0 then return end

	-- artLevel: 1=Basic, 2=Advanced, 3=Expert
	local pct = ARTILLERY_EXTRA_PCT[artLevel] or 0
	if pct <= 0 then return end

	local extra = math.floor(initial * pct / 100)
	if extra <= 0 then return end

	event:setDamage(event:getDamage() + extra)
end)
