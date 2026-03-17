-- wog_luck.lua
-- WOG New Age — Luck I Enhancement (option 206)
--
-- Classic WOG: Lucky strikes deal MORE than double damage.
-- Vanilla H3: Lucky strike = 2× base damage.
-- WOG Enhancement: Lucky strike = 2× damage + 50% bonus (so 3× effective).
--   i.e. the extra multiplier adds another 50% of initial damage on top.
--
-- Implementation: subscribeBefore on ApplyDamage so we see the base damage
-- BEFORE the lucky multiplier is applied... wait, in VCMI the lucky multiplier
-- is already baked into damageAmount by the time the event fires.
-- So getDamage() includes the 2× lucky. We add an extra 50% of getInitialDamage().
--   Extra = floor(initialDamage × 0.5)
--   New damage = getDamage() + extra
--
-- Fires on ApplyDamage subscribeAfter (damage already calculated).
-- Uses event:isLucky() to detect lucky hits.

local ApplyDamage = require("events.ApplyDamage")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

-- WOG Luck I: lucky hits get +50% of base damage extra (on top of 2× lucky)
local LUCK_EXTRA_PCT = C.luckExtraPct or 50

wogLuckSub = ApplyDamage.subscribeAfter(EVENT_BUS, function(event)
	if not (C.luckEnabled ~= false) then return end

	if not event:isLucky() then return end

	local initial  = event:getInitialDamage()
	local current  = event:getDamage()
	if initial <= 0 then return end

	-- Add LUCK_EXTRA_PCT% of initial damage on top of the 2× lucky damage
	local extra = math.floor(initial * LUCK_EXTRA_PCT / 100)
	if extra <= 0 then return end

	event:setDamage(current + extra)
end)
