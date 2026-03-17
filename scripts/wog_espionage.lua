-- wog_espionage.lua
-- WOG New Age — Espionage (option 58)
--
-- Classic WOG: Heroes with high Scouting (or the Intelligence specialty)
-- can gather intel on enemy hero positions and resources once per week.
--
-- Approximation: At the start of each week, human players who have at least
-- one hero with Advanced or Expert Scouting receive an intelligence report:
--   - Positions of all visible enemy heroes (x,y,z coordinates)
--   - Which enemy players are still active
--
-- The report is shown once per week via InfoWindow. The detail level scales
-- with the best Scouting skill among the player's heroes:
--   Basic Scouting:    No report (scout is too inexperienced)
--   Advanced Scouting: Enemy hero count per player
--   Expert Scouting:   Enemy hero positions (x, y, level)
--
-- SecondarySkill IDs: SCOUTING = 3

local PlayerGotTurn = require("events.PlayerGotTurn")
local InfoWindow    = require("netpacks.InfoWindow")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.espionageEnabled = C.espionageEnabled ~= false

local SCOUTING = 3  -- SecondarySkill::SCOUTING enum value

-- Track which player+week combos have seen the report already
local reportedThisWeek = {}

wogEspionageSub = PlayerGotTurn.subscribeAfter(EVENT_BUS, function(event)
	if not C.espionageEnabled then return end

	local totalDay = GAME:getDate(0)
	-- Only report on the first day of each week (days 1, 8, 15, ...)
	if (totalDay - 1) % 7 ~= 0 then return end

	local playerIdx = event:getPlayer()
	if not GAME:isPlayerHuman(playerIdx) then return end

	local week = math.floor((totalDay - 1) / 7)
	local reportKey = playerIdx * 1000 + week
	if reportedThisWeek[reportKey] then return end
	reportedThisWeek[reportKey] = true

	-- Find best Scouting level among all of this player's heroes
	local heroIds = GAME:getPlayerHeroes(playerIdx)
	if not heroIds or #heroIds == 0 then return end

	local bestScouting = 0
	for i = 1, #heroIds do
		local heroId = heroIds[i]
		local hero = GAME:getHero(heroId)
		if hero then
			local level = hero:getSecSkillLevel(SCOUTING)
			if level and level > bestScouting then
				bestScouting = level
			end
		end
	end

	-- Basic (1): no report; need at least Advanced (2)
	if bestScouting < 2 then return end

	-- Gather intel on enemy players
	local lines = {"[Espionage Report — Week " .. (week + 1) .. "]", ""}

	local foundAny = false
	for enemyIdx = 0, 7 do
		if enemyIdx == playerIdx then goto nextPlayer end

		local enemyHeroes = GAME:getPlayerHeroes(enemyIdx)
		if not enemyHeroes or #enemyHeroes == 0 then goto nextPlayer end

		if bestScouting == 2 then
			-- Advanced: only count of heroes per enemy player
			lines[#lines + 1] = "Player " .. (enemyIdx + 1) .. ": " .. #enemyHeroes .. " hero(es) in the field"
			foundAny = true
		else
			-- Expert: hero positions
			lines[#lines + 1] = "Player " .. (enemyIdx + 1) .. ":"
			for j = 1, #enemyHeroes do
				local eid = enemyHeroes[j]
				local ex, ey, ez = GAME:getHeroPosition(eid)
				if ex then
					local loc = "  Hero at (" .. ex .. ", " .. ey .. ")"
					if ez and ez > 0 then loc = loc .. " underground" end
					lines[#lines + 1] = loc
				end
			end
			foundAny = true
		end

		::nextPlayer::
	end

	if not foundAny then return end

	local msg = table.concat(lines, "\n")
	local pack = InfoWindow.new()
	pack:setPlayer(playerIdx)
	pack:addText(msg)
	SERVER:commitPackage(pack)
end)
