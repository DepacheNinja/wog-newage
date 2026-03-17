-- wog_battle_academy.lua
-- WOG New Age — Combat Hardening (custom feature)
--
-- After each battle, the winning hero receives bonus experience
-- equal to a percentage of the normal battle XP awarded.
-- Represents heroes learning from every fight they survive.
-- Default: 20% bonus XP on top of normal battle rewards.
-- Configurable via DATA.WOG.battleAcademyBonusPct.

local BattleEnded = require("events.BattleEnded")
local SetHeroExperience = require("netpacks.SetHeroExperience")

-- Config
DATA.WOG = DATA.WOG or {}
DATA.WOG.battleAcademyBonusPct = DATA.WOG.battleAcademyBonusPct or 20  -- 20% bonus XP

wogBattleAcademySub = BattleEnded.subscribeAfter(EVENT_BUS, function(event)
	local expAwarded = event:getExpAwarded()
	if expAwarded <= 0 then
		return  -- draw or no exp (wiped out attacker)
	end

	local winnerHeroId = event:getWinnerHeroId()
	if winnerHeroId < 0 then
		return  -- no hero on winning side
	end

	local bonusPct = DATA.WOG.battleAcademyBonusPct
	if bonusPct <= 0 then
		return
	end

	local bonusExp = math.floor(expAwarded * bonusPct / 100)
	if bonusExp <= 0 then
		return
	end

	local pack = SetHeroExperience.new()
	pack:setHeroId(winnerHeroId)
	pack:setValue(bonusExp)
	pack:setMode(false)  -- relative (add to existing)
	SERVER:commitPackage(pack)
end)
