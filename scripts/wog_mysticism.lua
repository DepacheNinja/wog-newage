-- wog_mysticism.lua
-- WOG New Age — Enhanced Mysticism (options 35 / 207)
--
-- VCMI base Mysticism:    Basic=2, Advanced=3, Expert=4 SP/day
-- WOG Enhanced Mysticism: Basic=3, Advanced=5, Expert=8 SP/day
-- This script adds the DIFFERENCE each day via SetMana netpack.
--
-- Fires on PlayerGotTurn (subscribeAfter so engine regen has already run).

local PlayerGotTurn = require("events.PlayerGotTurn")
local SetMana       = require("netpacks.SetMana")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

-- Bonus SP per skill level on top of VCMI's native Mysticism regen.
-- Index: 1=basic, 2=advanced, 3=expert
local BONUS_SP = C.mysticismBonusSP or {1, 2, 4}

wogMysticismSub = PlayerGotTurn.subscribeAfter(EVENT_BUS, function(event)
	if not (C.mysticismEnabled ~= false) then return end

	local playerIdx = event:getPlayer()
	local heroIds   = GAME:getPlayerHeroes(playerIdx)
	if not heroIds then return end

	for _, heroId in ipairs(heroIds) do
		local hero = GAME:getHero(heroId)
		if hero then
			local level = hero:getSecSkillLevel(C.SKILL and C.SKILL.MYSTICISM or 8)
			if level > 0 then
				local bonus = BONUS_SP[level] or 0
				if bonus > 0 then
					local pack = SetMana.new()
					pack:setHeroId(heroId)
					pack:setValue(bonus)
					pack:setMode(false)  -- relative (add to existing)
					SERVER:commitPackage(pack)
				end
			end
		end
	end
end)
