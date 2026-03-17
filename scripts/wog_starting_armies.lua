-- wog_starting_armies.lua
-- WOG New Age — Rebalanced Starting Armies (option 199)
--
-- Classic WOG: Starting hero armies are equalized so no player begins
-- with a huge advantage over others. Heroes with small starting armies
-- get bonus units of their faction's tier-1 creature.
--
-- VCMI Approximation:
--   On day 1, each human player's starting heroes receive a bonus of
--   wogStartingBonusCount tier-1 creatures of their faction in slot 6
--   (if that slot is empty). This ensures every hero has at least some
--   troops to work with, reducing early-game RNG luck.
--
-- Faction → Tier-1 creature ID mapping (vanilla H3 indices):
--   0=Castle(Pikeman=0), 1=Rampart(Centaur=21), 2=Tower(Gremlin=42),
--   3=Inferno(Imp=56), 4=Necropolis(Skeleton=70), 5=Dungeon(Troglodyte=84),
--   6=Stronghold(Goblin=98), 7=Fortress(Gnoll=112), 8=Conflux(Pixie=126)

local PlayerGotTurn  = require("events.PlayerGotTurn")
local InsertNewStack = require("netpacks.InsertNewStack")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.startingArmiesEnabled  = C.startingArmiesEnabled  ~= false
C.startingBonusCount     = C.startingBonusCount     or 8   -- creatures to add
C.startingBonusSlot      = C.startingBonusSlot      or 6   -- army slot to fill (0-6)

-- Tier-1 creature ID per faction index (0-based)
local FACTION_TIER1 = {
	[0] = 0,    -- Castle → Pikeman
	[1] = 21,   -- Rampart → Centaur
	[2] = 42,   -- Tower → Gremlin
	[3] = 56,   -- Inferno → Imp
	[4] = 70,   -- Necropolis → Skeleton
	[5] = 84,   -- Dungeon → Troglodyte
	[6] = 98,   -- Stronghold → Goblin
	[7] = 112,  -- Fortress → Gnoll
	[8] = 126,  -- Conflux → Pixie (Sprite)
}

-- Track which players have already received their starting bonus
local givenToPlayer = {}

wogStartingArmiesSub = PlayerGotTurn.subscribeAfter(EVENT_BUS, function(event)
	if not C.startingArmiesEnabled then return end

	-- Only on day 1 of the game
	local totalDay = GAME:getDate(0)
	if totalDay ~= 1 then return end

	local playerIdx = event:getPlayer()
	if not GAME:isPlayerHuman(playerIdx) then return end
	if givenToPlayer[playerIdx] then return end
	givenToPlayer[playerIdx] = true

	local heroIds = GAME:getPlayerHeroes(playerIdx)
	if not heroIds then return end

	for _, heroId in ipairs(heroIds) do
		local hero = GAME:getHero(heroId)
		if hero then
			-- Only give bonus if slot 6 is empty (stack returns nil for empty slots)
			local existingStack = hero:getStack(C.startingBonusSlot)
			if not existingStack then
				local factionId = hero:getFactionId()
				local creatureId = FACTION_TIER1[factionId]
				if creatureId then
					local pack = InsertNewStack.new()
					pack:setArmyId(heroId)
					pack:setSlot(C.startingBonusSlot)
					pack:setCreatureId(creatureId)
					pack:setCount(C.startingBonusCount)
					SERVER:commitPackage(pack)
				end
			end
		end
	end
end)
