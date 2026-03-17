-- wog_upgraded_dwellings.lua
-- WOG New Age — Upgraded Dwellings (option 133)
--
-- On day 1, every human player's starting towns automatically receive
-- the upgraded version of any basic dwelling they already have built.
-- This mirrors WOG 3.58f option 133: players start with upgraded creature
-- dwellings instead of having to pay for the upgrade themselves.
--
-- BuildingID layout (from EntityIdentifiers.h):
--   Basic:    DWELL_LVL_1=30 ... DWELL_LVL_7=36
--   Upgraded: DWELL_LVL_1_UP=37 ... DWELL_LVL_7_UP=43
-- Upgraded ID = basic ID + 7.

local PlayerGotTurn = require("events.PlayerGotTurn")
local NewStructures = require("netpacks.NewStructures")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.upgradedDwellingsEnabled = C.upgradedDwellingsEnabled ~= false

local DWELL_LVL_1    = 30  -- tier-1 basic dwelling
local DWELL_LVL_7    = 36  -- tier-7 basic dwelling
local DWELL_LVL_1_UP = 37  -- tier-1 upgraded dwelling (DWELL_LVL_1 + 7)

local appliedToPlayers = {}

wogUpgradedDwellingsSub = PlayerGotTurn.subscribeAfter(EVENT_BUS, function(event)
	if not C.upgradedDwellingsEnabled then return end

	-- Only on the very first turn of the game
	local totalDay = GAME:getDate(0)
	if totalDay ~= 1 then return end

	local playerIdx = event:getPlayer()
	if not GAME:isPlayerHuman(playerIdx) then return end
	if appliedToPlayers[playerIdx] then return end
	appliedToPlayers[playerIdx] = true

	local towns = GAME:getPlayerTowns(playerIdx)
	if not towns then return end

	for _, townId in ipairs(towns) do
		local pack = NewStructures.new()
		pack:setTownId(townId)

		local hasAny = false
		for tier = 0, 6 do
			local basicId = DWELL_LVL_1 + tier
			local upgId   = DWELL_LVL_1_UP + tier
			-- Add upgraded dwelling if base is built and upgrade is not yet present
			if GAME:townHasBuilding(townId, basicId) and not GAME:townHasBuilding(townId, upgId) then
				pack:addBuilding(upgId)
				hasAny = true
			end
		end

		if hasAny then
			SERVER:commitPackage(pack)
		end
	end
end)
