-- wog_combined_warfare_skills.lua
-- WOG New Age — Combined Warfare Skills (WOG script #193)
--
-- Ballistics, Artillery, and First Aid are linked as one combined skill.
-- When any one of the three is learned or leveled up, the other two
-- are automatically set to the same level. One skill pick effectively
-- levels all three simultaneously.
--
-- Secondary skill IDs (SecondarySkill enum):
--   0  = Pathfinding
--   1  = Archery
--   2  = Logistics
--   3  = Scouting
--   4  = Diplomacy
--   5  = Navigation
--   6  = Leadership
--   7  = Wisdom
--   8  = Mysticism
--   9  = Luck
--  10  = Ballistics
--  11  = Eagle Eye
--  12  = Necromancy
--  13  = Estates
--  14  = Fire Magic
--  15  = Air Magic
--  16  = Water Magic
--  17  = Earth Magic
--  18  = Scholar
--  19  = Tactics
--  20  = Artillery
--  21  = Learning
--  22  = Offence
--  23  = Armorer
--  24  = Intelligence
--  25  = Sorcery
--  26  = Resistance
--  27  = First Aid
--
-- The three warfare skills:
local BALLISTICS  = 10
local ARTILLERY   = 20
local FIRST_AID   = 27

local WARFARE_SKILLS = {BALLISTICS, ARTILLERY, FIRST_AID}

local HeroLevelUp  = require("events.HeroLevelUp")
local SetSecSkill  = require("netpacks.SetSecSkill")

local function syncWarfareSkills(heroId, triggeredSkill, newLevel)
	for _, skill in ipairs(WARFARE_SKILLS) do
		if skill ~= triggeredSkill then
			-- Only sync upward — never reduce a skill already higher
			local hero = GAME:getHero(heroId)
			if hero then
				local current = hero:getSecSkillLevel(skill)
				if current < newLevel then
					local pack = SetSecSkill.new()
					pack:setHeroId(heroId)
					pack:setSkill(skill)
					pack:setValue(newLevel)
					pack:setMode(true)  -- true = absolute (set to exact level)
					SERVER:commitPackage(pack)
				end
			end
		end
	end
end

wogCWSub = HeroLevelUp.subscribeAfter(EVENT_BUS, function(event)
	local heroId = event:getHero()
	local hero   = GAME:getHero(heroId)
	if not hero then return end

	-- Check each warfare skill — if any changed this level-up, sync the others
	for _, skill in ipairs(WARFARE_SKILLS) do
		local level = hero:getSecSkillLevel(skill)
		if level > 0 then
			syncWarfareSkills(heroId, skill, level)
			-- Only need to sync once based on the highest warfare skill held
			break
		end
	end
end)
