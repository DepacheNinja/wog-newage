-- wog_learning.lua
-- WOG New Age — Enhanced Learning (options 205 / 217)
--
-- Heroes with Learning skill gain passive experience each day.
-- Classic WOG: Learning II = 100/200/300 XP per day (basic/advanced/expert).
--
-- Also: on BattleEnded, if winner has Learning, multiply the XP gain.
-- Learning I (217):  +10% battle XP
-- Learning II (205): +25% battle XP (stacks with Combat Hardening)
--
-- Daily XP fires on PlayerGotTurn (subscribeAfter).

local PlayerGotTurn    = require("events.PlayerGotTurn")
local SetHeroExperience = require("netpacks.SetHeroExperience")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

local BONUS_XP   = C.learningBonusXP or {100, 200, 300}  -- XP/day per [basic, adv, expert]
local LEARN_SKILL = C.SKILL and C.SKILL.LEARNING or 21

wogLearningDailySub = PlayerGotTurn.subscribeAfter(EVENT_BUS, function(event)
	if not (C.learningEnabled ~= false) then return end

	local playerIdx = event:getPlayer()
	local heroIds   = GAME:getPlayerHeroes(playerIdx)
	if not heroIds then return end

	for _, heroId in ipairs(heroIds) do
		local hero = GAME:getHero(heroId)
		if hero then
			local level = hero:getSecSkillLevel(LEARN_SKILL)
			if level > 0 then
				local bonus = BONUS_XP[level] or 0
				if bonus > 0 then
					local pack = SetHeroExperience.new()
					pack:setHeroId(heroId)
					pack:setValue(bonus)
					pack:setMode(false)  -- relative (add)
					SERVER:commitPackage(pack)
				end
			end
		end
	end
end)
