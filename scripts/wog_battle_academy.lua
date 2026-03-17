-- wog_battle_academy.lua
-- WOG New Age — Combat Hardening (custom feature)
--
-- After each battle, the winning hero receives bonus experience
-- equal to a percentage of the normal battle XP awarded.
-- Represents heroes learning from every fight they survive.
-- Default: 20% bonus XP on top of normal battle rewards.
-- Configurable via DATA.WOG.battleAcademyBonusPct in wog_config.lua.

local BattleEnded       = require("events.BattleEnded")
local SetHeroExperience = require("netpacks.SetHeroExperience")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

wogBattleAcademySub = BattleEnded.subscribeAfter(EVENT_BUS, function(event)
	if not (C.battleAcademyEnabled ~= false) then return end

	-- Combat Hardening bonus only applies to real battles (NORMAL=0)
	if event:getBattleResult() ~= 0 then return end

	local expAwarded = event:getExpAwarded()
	if expAwarded <= 0 then return end

	local winnerHeroId = event:getWinnerHeroId()
	if winnerHeroId < 0 then return end

	local bonusPct = C.battleAcademyBonusPct or 20
	if bonusPct <= 0 then return end

	local bonusExp = math.floor(expAwarded * bonusPct / 100)
	if bonusExp <= 0 then return end

	local pack = SetHeroExperience.new()
	pack:setHeroId(winnerHeroId)
	pack:setValue(bonusExp)
	pack:setMode(false)  -- relative (add to existing)
	SERVER:commitPackage(pack)
end)
