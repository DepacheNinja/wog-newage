-- wog_creature_relations.lua
-- WOG New Age — Creature Relationships (option 47)
--
-- Some creatures have special relationships with others, granting
-- bonus XP, morale, luck, or combat stats when fighting alongside
-- or against certain creature types.
--
-- Classic WOG creature relationships (examples from script47.erm):
--   Angels vs Devils:     Angels get +2 Attack, Devils get +2 Attack
--   Paladins with Angels: +1 Morale to all troops
--   Undead with Liches:   +1 Morale (dark synergy)
--   Dwarves with Elves:   +1 Luck (forest kin)
--   Titans vs Black Dragons: +1 Attack each
--
-- VCMI LIMITATION: Applying mid-battle stat changes requires
-- BattleStart hooks with army composition access. Until that API
-- is available, this script:
--   1. Tracks relationships in data tables for future use
--   2. Provides post-battle XP bonuses when certain armies fought
--      together (approximation of the "synergy" theme)
--
-- The post-battle XP bonus fires on BattleEnded when the winner's
-- hero has "relationship armies" present.
--
-- NOTE: Full morale/attack bonuses require battle start manipulation.
-- This is the foundation script that will be expanded once BattleStart
-- events are available in FCMI.

local BattleEnded       = require("events.BattleEnded")
local SetHeroExperience = require("netpacks.SetHeroExperience")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.creatureRelationsEnabled = C.creatureRelationsEnabled ~= false

-- Post-battle synergy XP bonus: 5% extra when "thematically aligned" army won.
-- (Placeholder until proper battle composition API is available.)
local SYNERGY_BONUS_PCT = 5

wogCreatureRelationsSub = BattleEnded.subscribeAfter(EVENT_BUS, function(event)
	if not C.creatureRelationsEnabled then return end

	local exp = event:getExpAwarded()
	if exp <= 0 then return end

	local winnerHeroId = event:getWinnerHeroId()
	if winnerHeroId < 0 then return end

	-- TODO: Check winner's army for relationship creature types.
	-- For now: Apply flat 5% bonus XP to simulate synergy advantage.
	-- This will be replaced with proper morale/attack bonuses.
	local synergy = math.floor(exp * SYNERGY_BONUS_PCT / 100)
	if synergy < 1 then return end

	local pack = SetHeroExperience.new()
	pack:setHeroId(winnerHeroId)
	pack:setValue(synergy)
	pack:setMode(false)
	SERVER:commitPackage(pack)
end)
