-- wog_setup.lua
-- WOG New Age — Pre-Game Configuration Screen
--
-- Fires once on Day 1 of a brand-new game (not on save-game loads).
-- Asks the first human player to configure key WOG feature groups via
-- a chain of BlockingDialog yes/no prompts.
--
-- All features default to their recommended state (matching the classic
-- WOG 3.58f setup used by this mod). Masters of Life defaults to OFF
-- because the user's WOG setup has it disabled.
--
-- Day-1 one-time events (First Money, map seeding, etc.) have already
-- fired with defaults by the time the setup screen appears. All other
-- features (recurring TurnStarted, ObjectVisitStarted, etc.) respect
-- the player's choices immediately.

local TurnStarted    = require("events.TurnStarted")
local QueryReplied   = require("events.QueryReplied")
local BlockingDialog = require("netpacks.BlockingDialog")
local InfoWindow     = require("netpacks.InfoWindow")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

-- Prevent double-trigger across players / save-game reloads
C.setupStarted  = C.setupStarted  or false
C.setupComplete = C.setupComplete or false

-- Pending dialog chain: queryId → {step, playerIdx}
C.setupDialogs = C.setupDialogs or {}

-- ---------------------------------------------------------------------------
-- SETUP QUESTIONS
-- flags   : list of C.xxxEnabled keys to set based on the answer
-- default : true = ON by default (Yes recommended), false = OFF (No recommended)
-- text    : BlockingDialog body text
-- ---------------------------------------------------------------------------
local SETUP_QUESTIONS = {
	{
		flags   = {"mithrilEnabled"},
		default = true,
		text    = "{WOG New Age — Mithril System}\\n\\n"
		       .. "Mithril is a rare resource found in mines, windmills, "
		       .. "and resource piles. Spend it to enhance map objects: "
		       .. "double mine production, reroll shrine spells, upgrade "
		       .. "creature dwellings, boost universities, and more.\\n\\n"
		       .. "Enable the Mithril system? (Recommended: YES)"
	},
	{
		flags   = {"stackExpEnabled"},
		default = true,
		text    = "{WOG New Age — Stack Experience}\\n\\n"
		       .. "Army stacks accumulate XP from battles and gain "
		       .. "+1 primary stat per 5000 XP milestone.\\n\\n"
		       .. "Enable Stack Experience? (Recommended: YES)"
	},
	{
		flags   = {"creatureRelationsEnabled", "espionageEnabled"},
		default = true,
		text    = "{WOG New Age — Creature Relations & Espionage}\\n\\n"
		       .. "Creature Relations: hate/allied pairs cause morale "
		       .. "penalties and synergy XP bonuses in battle.\\n"
		       .. "Espionage: heroes with Scouting gain weekly intel "
		       .. "on enemy hero positions.\\n\\n"
		       .. "Enable these features? (Recommended: YES)"
	},
	{
		flags   = {"specialTerrainEnabled", "upgradedDwellingsEnabled", "replaceDragonFlyEnabled"},
		default = true,
		text    = "{WOG New Age — Map Modifications}\\n\\n"
		       .. "Patches of special terrain are added to maps.\\n"
		       .. "Starting towns receive upgraded creature dwellings.\\n"
		       .. "Most Dragon Fly hives are replaced with Wyverns.\\n\\n"
		       .. "Enable map modifications? (Recommended: YES)"
	},
	{
		flags   = {"mastersOfLifeEnabled"},
		default = false,
		text    = "{WOG New Age — Masters of Life}\\n\\n"
		       .. "Each day, tier-1 creatures in hero armies are "
		       .. "upgraded to their faction's advanced tier-1 form "
		       .. "(e.g., Peasants → upgraded tier-1 creature).\\n"
		       .. "This option is disabled by default in this setup.\\n\\n"
		       .. "Enable Masters of Life? (Recommended: NO)"
	},
	{
		flags   = {"autoWogifyEnabled"},
		default = true,
		text    = "{WOG New Age — Auto-WoGification}\\n\\n"
		       .. "Automatically scatter WOG adventure objects on this map: "
		       .. "Artificers, Death Chambers, Power Stones, and Special "
		       .. "Treasure Chests at random locations scaled to map size.\\n"
		       .. "Only activates on maps with no existing WOG objects.\\n\\n"
		       .. "Auto-WoGify this map? (Recommended: YES)"
	},
}

-- ---------------------------------------------------------------------------
-- Apply default values for all flags (in case setup is skipped or save-loaded)
-- ---------------------------------------------------------------------------
local function applyDefaults()
	for _, q in ipairs(SETUP_QUESTIONS) do
		for _, flagName in ipairs(q.flags) do
			if C[flagName] == nil then
				C[flagName] = q.default
			end
		end
	end
end

-- ---------------------------------------------------------------------------
-- Show one question in the chain, or finalize if all done
-- ---------------------------------------------------------------------------
local function showStep(playerIdx, step)
	if step > #SETUP_QUESTIONS then
		C.setupComplete = true
		local iw = InfoWindow.new()
		iw:setPlayer(playerIdx)
		iw:addText("{WOG New Age}\\n\\nSetup complete!\\n\\n"
		        .. "Note: Day 1 features (First Money, map seeding, upgraded "
		        .. "dwellings) already activated with default settings. All "
		        .. "other features now use your chosen configuration.")
		SERVER:commitPackage(iw)
		return
	end
	local q   = SETUP_QUESTIONS[step]
	local dlg = BlockingDialog.new()
	dlg:setPlayer(playerIdx)
	dlg:addText(q.text)
	local qid = dlg:getQueryId()
	SERVER:commitPackage(dlg)
	C.setupDialogs[qid] = {step = step, playerIdx = playerIdx}
end

-- ---------------------------------------------------------------------------
-- TurnStarted: trigger setup screen on Day 1 of a new game only
-- ---------------------------------------------------------------------------
wogSetupTurnSub = TurnStarted.subscribeAfter(EVENT_BUS, function(event)
	if C.setupStarted or C.setupComplete then return end

	local day   = GAME:getDate(0)
	local week  = GAME:getDate(1)
	local month = GAME:getDate(2)

	-- Only fire on the literal first turn of a new game
	if day ~= 1 or week ~= 1 or month ~= 1 then
		-- Save-game loaded mid-game: apply defaults silently and done
		applyDefaults()
		C.setupStarted  = true
		C.setupComplete = true
		return
	end

	local playerIdx = event:getPlayer()
	if not GAME:isPlayerHuman(playerIdx) then return end

	C.setupStarted = true
	applyDefaults()   -- ensure all flags have values before dialogs begin

	-- Show intro window then chain the questions
	local iw = InfoWindow.new()
	iw:setPlayer(playerIdx)
	iw:addText("{WOG New Age — Setup}\\n\\n"
	        .. "Welcome to WOG New Age " .. (C.modVersion or "v1.1") .. "!\\n\\n"
	        .. "You will now configure " .. tostring(#SETUP_QUESTIONS) .. " feature groups.\\n"
	        .. "Press YES to enable a feature or NO to disable it.\\n"
	        .. "Defaults are pre-set to the recommended WOG 3.58f configuration.")
	SERVER:commitPackage(iw)

	showStep(playerIdx, 1)
end)

-- ---------------------------------------------------------------------------
-- QueryReplied: advance through the setup question chain
-- ---------------------------------------------------------------------------
wogSetupQuerySub = QueryReplied.subscribeAfter(EVENT_BUS, function(event)
	local qid  = event:getQueryId()
	local data = C.setupDialogs[qid]
	if not data then return end
	C.setupDialogs[qid] = nil

	local q      = SETUP_QUESTIONS[data.step]
	local reply  = event:getReply()   -- 1 = Yes, 0 = No
	local enabled = (reply == 1)

	if q then
		for _, flagName in ipairs(q.flags) do
			C[flagName] = enabled
		end
	end

	showStep(data.playerIdx, data.step + 1)
end)
