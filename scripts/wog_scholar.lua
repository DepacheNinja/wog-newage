-- wog_scholar.lua
-- WOG New Age — Enhanced Scholar (option 211)
--
-- Classic WOG Script 48, Scholar sub-option:
-- "Each week a hero will attempt to research a new spell."
--   Basic:    40% chance to learn up to a 2nd level spell
--   Advanced: 50% chance to learn up to a 3rd level spell
--   Expert:   60% chance to learn up to a 4th level spell
--
-- Hero must have a spellbook. Won't duplicate known spells.
-- Fires on PlayerGotTurn on day 1 of each week (subscribeAfter).

local PlayerGotTurn  = require("events.PlayerGotTurn")
local ChangeSpells   = require("netpacks.ChangeSpells")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

-- Chance and max level per skill level [basic, advanced, expert]
-- Values come from config; these are the fallback defaults.
local LEARN_CHANCE  = C.scholarLearnChance   or {40, 50, 60}  -- percent
local MAX_SPELL_LVL = C.scholarMaxSpellLevel or {2, 3, 4}

local SCHOLAR_SKILL = C.SKILL and C.SKILL.SCHOLAR or 18

wogScholarSub = PlayerGotTurn.subscribeAfter(EVENT_BUS, function(event)
	if not (C.scholarEnabled ~= false) then return end

	local dayOfWeek = GAME:getDate(1)
	if dayOfWeek ~= 1 then return end  -- only on first day of each week

	local playerIdx = event:getPlayer()
	local heroIds   = GAME:getPlayerHeroes(playerIdx)
	if not heroIds then return end

	for _, heroId in ipairs(heroIds) do
		local hero = GAME:getHero(heroId)
		if hero then
			local skillLevel = hero:getSecSkillLevel(SCHOLAR_SKILL)
			if skillLevel > 0 and hero:hasSpellbook() then
				local chance   = LEARN_CHANCE[skillLevel] or 0
				local maxLevel = MAX_SPELL_LVL[skillLevel] or 1

				if math.random(100) <= chance then
					-- Pick a spell level from 1 to maxLevel, weighted toward higher levels
					local spellLevel = math.random(1, maxLevel)

					-- Get all spells at that level
					local available = GAME:getSpellsByLevel(spellLevel)
					if available and #available > 0 then
						-- Shuffle to find one the hero doesn't know
						local startIdx = math.random(1, #available)
						for i = 1, #available do
							local idx = ((startIdx + i - 2) % #available) + 1
							local spellId = available[idx]
							if spellId and not hero:hasSpell(spellId) then
								local pack = ChangeSpells.new()
								pack:setHeroId(heroId)
								pack:setLearn(true)
								pack:addSpell(spellId)
								SERVER:commitPackage(pack)
								break
							end
						end
					end
				end
			end
		end
	end
end)
