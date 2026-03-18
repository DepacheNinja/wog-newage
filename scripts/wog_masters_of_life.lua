-- wog_masters_of_life.lua
-- WOG New Age — Masters of Life (option 19)
--
-- ERM script19 v1.8 by Sir Four, modified by Thomas Franz (samot).
-- Classic WOG: At the beginning of each player's turn, ALL peasants
-- and tier-1 base creatures in every hero army (of the same faction)
-- are automatically upgraded to the tier-1 upgraded form.
-- Necromancers (faction 4) are skipped.
--
-- ERM logic:
--   !!HEx16:C1/y-3/y-4/d/d/0/5  — change tier-1 base → tier-1 upgraded (keep count/XP)
--   !!HEx16:C1/139/y-4/d/d/0/5  — change Peasant (139) → tier-1 upgraded of hero's faction
--
-- VCMI port:
--   PlayerGotTurn fires for each player each day.
--   For each of that player's heroes, scan all 7 army slots.
--   If the slot contains the faction's base tier-1 creature OR a Peasant,
--   replace it with the faction's upgraded tier-1 via SetStackType netpack.
--   SetStackType preserves stack count and experience.
--
-- Faction → tier-1 pair mapping (VCMI 0-based creature indices,
-- verified from fcmi/config/creatures/*.json and wog_creature_relations.lua):
--   0 Castle:     Pikeman(0)      → Halberdier(1)
--   1 Rampart:    Centaur(14)     → CentaurCaptain(15)
--   2 Tower:      Gremlin(28)     → MasterGremlin(29)
--   3 Inferno:    Imp(42)         → Familiar(43)
--   4 Necropolis: SKIP (Necromancers are excluded per ERM)
--   5 Dungeon:    Troglodyte(70)  → InfernalTroglodyte(71)
--   6 Stronghold: Goblin(84)      → Hobgoblin(85)
--   7 Fortress:   Gnoll(98)       → GnollMarauder(99)
--   8 Conflux:    Pixie(118)      → Sprite(119)
--
-- Peasant VCMI ID = 139 (confirmed from wog_week_of_monsters.lua neutral list).

local PlayerGotTurn = require("events.PlayerGotTurn")
local SetStackType  = require("netpacks.SetStackType")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.mastersOfLifeEnabled = C.mastersOfLifeEnabled == true

-- Necropolis faction ID (skipped per ERM script19)
local NECROPOLIS = 4

-- Peasant creature ID in VCMI (neutral creature, upgrades to hero's faction tier-1 upg)
local PEASANT_ID = 139

-- Faction → {baseTier1, upgradedTier1}
-- Only factions where tier-1 upgrades make sense (not Necropolis)
local FACTION_TIER1 = {
	[0] = {0,   1},    -- Castle:     Pikeman      → Halberdier
	[1] = {14,  15},   -- Rampart:    Centaur      → Centaur Captain
	[2] = {28,  29},   -- Tower:      Gremlin      → Master Gremlin
	[3] = {42,  43},   -- Inferno:    Imp          → Familiar
	-- [4] Necropolis: SKIP
	[5] = {70,  71},   -- Dungeon:    Troglodyte   → Infernal Troglodyte
	[6] = {84,  85},   -- Stronghold: Goblin       → Hobgoblin
	[7] = {98,  99},   -- Fortress:   Gnoll        → Gnoll Marauder
	[8] = {118, 119},  -- Conflux:    Pixie        → Sprite
}

-- ---------------------------------------------------------------------------
-- PLAYER GOT TURN: upgrade tier-1 base + peasants in all heroes' armies
-- Runs for every player (human and AI) each day, matching ERM behaviour.
-- ---------------------------------------------------------------------------

wogMastersOfLifeSub = PlayerGotTurn.subscribeAfter(EVENT_BUS, function(event)
	if not C.mastersOfLifeEnabled then return end

	local playerIdx = event:getPlayer()
	local heroIds   = GAME:getPlayerHeroes(playerIdx)
	if not heroIds then return end

	for _, heroId in ipairs(heroIds) do
		local hero = GAME:getHero(heroId)
		if hero then
			local factionId = hero:getFactionId()

			-- ERM: skip Necromancers entirely
			if factionId ~= NECROPOLIS then
				local pair = FACTION_TIER1[factionId]
				if pair then
					local baseTier1 = pair[1]
					local upgTier1  = pair[2]

					for slot = 0, 6 do
						local stack = hero:getStack(slot)
						if stack then
							local ct  = stack:getType()
							local cnt = stack:getCount()
							if ct and cnt and cnt > 0 then
								local idx = ct:getIndex()
								-- Upgrade base tier-1 or Peasant → upgraded tier-1
								if idx == baseTier1 or idx == PEASANT_ID then
									local pack = SetStackType.new()
									pack:setArmyId(heroId)
									pack:setSlot(slot)
									pack:setCreatureId(upgTier1)
									SERVER:commitPackage(pack)
								end
							end
						end
					end
				end
			end
		end
	end
end)
