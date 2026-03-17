-- wog_wandering_monsters.lua
-- WOG New Age — Wandering Monsters (option 135)
--
-- Classic WOG: Neutral monster stacks that survive on the adventure map
-- wander around, moving a few tiles each week. This makes the map feel
-- more alive and prevents players from easily camping near monster stacks.
--
-- Implementation:
--   On each new week (TurnStarted, day divisible by 7), for each surviving
--   wandering monster (Obj::MONSTER), roll to see if it moves this week.
--   If yes, pick a random direction and try to step 1-2 tiles that way.
--   Skip moves into water or rock terrain (impassable tiles).
--   Skip moves out of map bounds (getTerrainAt returns nil).
--
-- Config:
--   C.wanderingMonstersEnabled    = true
--   C.wanderingMonstersChancePct  = 33   -- % chance each stack moves per week
--   C.wanderingMonstersMaxRange   = 2    -- max tiles moved per step

local TurnStarted  = require("events.TurnStarted")
local ChangeObjPos = require("netpacks.ChangeObjPos")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.wanderingMonstersEnabled   = C.wanderingMonstersEnabled ~= false
C.wanderingMonstersChancePct = C.wanderingMonstersChancePct or 33
C.wanderingMonstersMaxRange  = C.wanderingMonstersMaxRange  or 2

local OBJ_MONSTER = 54  -- Obj::MONSTER type group

-- Terrain types impassable to wandering monsters
local IMPASSABLE_TERRAIN = {
	water = true,
	rock  = true,
}

-- 4-directional movement deltas (ordered: E, W, S, N)
local DIRECTIONS = { {1,0}, {-1,0}, {0,1}, {0,-1} }

-- Simple deterministic hash: maps (objectId, week) → a pseudo-random direction index
-- Avoids touching global math.randomseed (which would affect all scripts).
local function deterministicDirIdx(objectId, week, extra)
	local h = (objectId * 1000003 + week * 997 + (extra or 0)) % 4
	return h + 1  -- 1-based index
end

-- Returns directions array rotated by a deterministic offset
local function shuffledDirections(objectId, week)
	local offset = deterministicDirIdx(objectId, week, 0)
	local dirs = {}
	for i = 1, 4 do
		dirs[i] = DIRECTIONS[((offset + i - 2) % 4) + 1]
	end
	return dirs
end

-- Try to move objectId from (x,y,z) by (dx,dy)*dist tiles.
-- Returns new (nx,ny,nz) if valid, or nil if blocked.
local function tryMove(x, y, z, dx, dy, dist)
	local nx = x + dx * dist
	local ny = y + dy * dist
	local nz = z
	local terrain = GAME:getTerrainAt(nx, ny, nz)
	if not terrain then return nil end             -- out of bounds
	if IMPASSABLE_TERRAIN[terrain] then return nil end  -- impassable tile
	return nx, ny, nz
end

wogWanderingMonstersSub = TurnStarted.subscribeAfter(EVENT_BUS, function(event)
	if not C.wanderingMonstersEnabled then return end

	local totalDay = GAME:getDate(0)
	-- Only act on first day of each week (days 8, 15, 22, ...)
	-- Day 1 is excluded — monsters just spawned.
	if totalDay < 8 or (totalDay - 1) % 7 ~= 0 then return end

	local week = (totalDay - 1) / 7  -- week number (1 = week 2 of game, etc.)

	local monsterIds = GAME:getMapObjectIds(OBJ_MONSTER)
	if not monsterIds then return end

	local chance = C.wanderingMonstersChancePct
	local maxRange = C.wanderingMonstersMaxRange

	for i = 1, #monsterIds do
		local objectId = monsterIds[i]

		-- Confirm the stack is still alive
		local count = GAME:getMonsterCount(objectId)
		if not count or count <= 0 then goto continue end

		-- Roll for movement using deterministic hash (no global RNG mutation)
		local roll = (objectId * 7919 + week * 1009) % 100 + 1
		if roll > chance then goto continue end

		-- Get current position
		local x, y, z = GAME:getObjectPosition(objectId)
		if not x then goto continue end

		-- Try each direction in shuffled order; pick deterministic distance 1..maxRange
		local dirs = shuffledDirections(objectId, week)
		local dist = (objectId * 1301 + week * 503) % maxRange + 1
		local moved = false
		for _, dir in ipairs(dirs) do
			local nx, ny, nz = tryMove(x, y, z, dir[1], dir[2], dist)
			if nx then
				local pack = ChangeObjPos.new()
				pack:setObjectId(objectId)
				pack:setPosition(nx, ny, nz)
				pack:setInitiator(255)  -- system-initiated move
				SERVER:commitPackage(pack)
				moved = true
				break
			end
		end

		::continue::
	end
end)
