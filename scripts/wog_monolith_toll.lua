-- wog_monolith_toll.lua
-- WOG New Age — Monolith Costs (option 65)
--
-- ERM script65 v1.1 by Steven Lynch.
-- Two-way monolith use costs gold proportional to the current week:
--   Human players : floor((totalDays - 1) / 7) + 1  × 100 gold
--   AI players    : floor((totalDays - 1) / 7) + 1  × 50  gold
--
-- One-way monolith entrances (OBJ=43): show an informational message only.
-- One-way exits (OBJ=44) are never visited by the hero (they are destinations).
--
-- VCMI limitation: we cannot block the teleport itself from Lua once
-- ObjectVisitStarted fires. The toll is collected (or denied) and the
-- hero still travels. This matches the spirit of the ERM script.

local ObjectVisitStarted = require("events.ObjectVisitStarted")
local QueryReplied       = require("events.QueryReplied")
local BlockingDialog     = require("netpacks.BlockingDialog")
local InfoWindow         = require("netpacks.InfoWindow")
local SetResources       = require("netpacks.SetResources")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.monolithTollEnabled = C.monolithTollEnabled ~= false

-- Pending dialogs: queryId → {playerIdx, cost}
C.monolithTollDialogs = C.monolithTollDialogs or {}

local GOLD               = 6
local OBJ_MONOLITH_IN    = 43   -- One-way entrance
local OBJ_MONOLITH_TWO   = 45   -- Two-way monolith

-- ---------------------------------------------------------------------------
-- Calculate toll cost based on current date
--   weeks = floor((totalDays - 1) / 7) + 1   (minimum 1 at game start)
-- ---------------------------------------------------------------------------
local function calculateCost(isHuman)
	local day   = GAME:getDate(0)
	local week  = GAME:getDate(1)
	local month = GAME:getDate(2)
	local totalDays   = (month - 1) * 28 + (week - 1) * 7 + day
	local completeWeeks = math.floor((totalDays - 1) / 7) + 1
	return completeWeeks * (isHuman and 100 or 50)
end

-- ---------------------------------------------------------------------------
-- Deduct gold from player (delta, negative amount)
-- ---------------------------------------------------------------------------
local function chargeGold(playerIdx, amount)
	local pack = SetResources.new()
	pack:setPlayer(playerIdx)
	pack:setAbs(false)
	pack:setAmount(GOLD, -amount)
	SERVER:commitPackage(pack)
end

-- ---------------------------------------------------------------------------
-- ObjectVisitStarted: intercept monolith visits
-- ---------------------------------------------------------------------------
wogMonolithTollSub = ObjectVisitStarted.subscribeAfter(EVENT_BUS, function(event)
	if not C.monolithTollEnabled then return end

	local obj       = event:getObject()
	if not obj then return end
	local objType   = obj:getObjectType()

	-- One-way entrance: informational message for humans only
	if objType == OBJ_MONOLITH_IN then
		local playerIdx = event:getPlayer()
		if not GAME:isPlayerHuman(playerIdx) then return end
		local iw = InfoWindow.new()
		iw:setPlayer(playerIdx)
		iw:addText("{One-Way Monolith}\\n\\n"
		        .. "This monolith only travels in one direction. "
		        .. "There is no toll for one-way monolith use.")
		SERVER:commitPackage(iw)
		return
	end

	-- Two-way monolith: charge toll
	if objType ~= OBJ_MONOLITH_TWO then return end

	local playerIdx = event:getPlayer()
	local isHuman   = GAME:isPlayerHuman(playerIdx)
	local cost      = calculateCost(isHuman)
	local gold      = GAME:getPlayerResource(playerIdx, GOLD)

	if isHuman then
		-- Show yes/no dialog asking player to pay
		local dlg = BlockingDialog.new()
		dlg:setPlayer(playerIdx)
		dlg:addText("{Monolith Toll}\\n\\n"
		         .. "Using this two-way monolith costs "
		         .. tostring(cost) .. " gold.\\n"
		         .. "You currently have " .. tostring(gold) .. " gold.\\n\\n"
		         .. "Pay the toll and travel? (Recommended: YES)")
		local qid = dlg:getQueryId()
		SERVER:commitPackage(dlg)
		C.monolithTollDialogs[qid] = {playerIdx = playerIdx, cost = cost}
	else
		-- AI: deduct silently if it has enough gold (never go negative)
		if gold >= cost then
			chargeGold(playerIdx, cost)
		elseif gold > 0 then
			-- Drain remaining gold (ERM: take what it has)
			chargeGold(playerIdx, gold)
		end
		-- AI always gets to use the monolith regardless
	end
end)

-- ---------------------------------------------------------------------------
-- QueryReplied: handle human player's toll response
-- ---------------------------------------------------------------------------
wogMonolithTollQuerySub = QueryReplied.subscribeAfter(EVENT_BUS, function(event)
	local qid  = event:getQueryId()
	local data = C.monolithTollDialogs[qid]
	if not data then return end
	C.monolithTollDialogs[qid] = nil

	local reply     = event:getReply()   -- 1 = Yes, 0 = No
	local playerIdx = data.playerIdx
	local cost      = data.cost
	local gold      = GAME:getPlayerResource(playerIdx, GOLD)

	if reply == 1 then
		if gold >= cost then
			chargeGold(playerIdx, cost)
		else
			-- Agreed but can't afford — inform player, no charge
			local iw = InfoWindow.new()
			iw:setPlayer(playerIdx)
			iw:addText("{Monolith Toll}\\n\\n"
			        .. "You do not have enough gold to pay the toll of "
			        .. tostring(cost) .. " gold.\\n"
			        .. "The monolith transports you anyway... but you owe a debt.")
			SERVER:commitPackage(iw)
		end
	else
		-- Player said No — note: teleport cannot be blocked from Lua
		local iw = InfoWindow.new()
		iw:setPlayer(playerIdx)
		iw:addText("{Monolith Toll}\\n\\n"
		        .. "You refused to pay the toll of " .. tostring(cost) .. " gold.\\n"
		        .. "The monolith transports you regardless.")
		SERVER:commitPackage(iw)
	end
end)
