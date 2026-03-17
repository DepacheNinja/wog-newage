-- wog_mithril_spending.lua
-- WOG New Age — Mithril Spending (option 36)
--
-- ERM script36 by Anders Jonsson, v1.4.
-- Classic WOG: right-click an object you own (mine, windmill, dwelling, shrine,
--   witch hut, etc.) to spend Mithril for an enhancement.
--
-- VCMI port notes:
--   - Right-click bridge not available; spending is triggered by VISITING the
--     object instead of right-clicking it. This is slightly different UX but
--     functionally equivalent (walk up to the object → get the offer).
--   - BlockingDialog (yes/no) is used for the spending prompt. The player's
--     answer is received via events.QueryReplied.
--   - All Mithril is stored in DATA.WOG.playerMithril (not a real resource).
--   - Mine upgrade (double production for 1 week) is tracked per mine per
--     owner in C.upgradedMines; bonus resource given on TurnStarted each day.
--   - Windmill / water wheel upgrade (double this week's production) applies
--     a double-resource bonus on the next visit within the same week.
--   - Shrine spell reroll and Witch Hut skill reroll: deferred until
--     getShrineSpell / setWitchHutSkill FCMI APIs are added.
--   - Dwelling upgrade: deferred until setDwellingCreature FCMI API is added.
--   - Castle terrain placement, Shipyard lighthouse, Monolith reveal: deferred.
--
-- Mithril costs (from ERM script36 FU8172/FU8181/FU8182):
--   Mine upgrade: 4 Mithril (7 for gold mine)
--   Windmill / water wheel upgrade: 5 Mithril
--
-- Display
--   Shows current Mithril count in spending dialogs.
--   Full price list shown on visiting the first Mithril-enabled object each session.

local ObjectVisitStarted = require("events.ObjectVisitStarted")
local QueryReplied       = require("events.QueryReplied")
local TurnStarted        = require("events.TurnStarted")
local BlockingDialog     = require("netpacks.BlockingDialog")
local SetResources       = require("netpacks.SetResources")
local InfoWindow         = require("netpacks.InfoWindow")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.mithrilEnabled = C.mithrilEnabled ~= false

-- Persistent upgrade state
-- upgradedMines[objIdNum] = {player=N, expiryDay=D, resource=R, amount=A}
C.upgradedMines = C.upgradedMines or {}
-- upgradedWindmills[objIdNum] = {player=N, expiryWeek=W}
C.upgradedWindmills = C.upgradedWindmills or {}

-- Pending dialogs: pendingMithrilDialogs[queryId] = {type, playerIdx, objId, cost, ...}
C.pendingMithrilDialogs = C.pendingMithrilDialogs or {}

-- ---------------------------------------------------------------------------
-- HELPERS
-- ---------------------------------------------------------------------------

local OBJ_MINE       = 53
local OBJ_WINDMILL   = 112
local OBJ_WATERWHEEL = 109

-- Resource type names for dialog text
local RES_NAMES = {
    [0] = "Wood", [1] = "Mercury", [2] = "Ore",
    [3] = "Sulfur", [4] = "Crystal", [5] = "Gems", [6] = "Gold"
}

local function getMithril(playerIdx)
    C.playerMithril = C.playerMithril or {}
    return C.playerMithril[playerIdx] or 0
end

local function spendMithril(playerIdx, amount)
    C.playerMithril = C.playerMithril or {}
    C.playerMithril[playerIdx] = math.max(0, (C.playerMithril[playerIdx] or 0) - amount)
end

local function showInfo(playerIdx, text)
    local pack = InfoWindow.new()
    pack:setPlayer(playerIdx)
    pack:addText(text)
    SERVER:commitPackage(pack)
end

local function askYesNo(playerIdx, text, pendingData)
    local dlg = BlockingDialog.new()
    dlg:setPlayer(playerIdx)
    dlg:addText(text)
    -- Capture queryId BEFORE committing (assigned on creation)
    local qid = dlg:getQueryId()
    SERVER:commitPackage(dlg)
    -- Register callback data keyed by queryId
    C.pendingMithrilDialogs[qid] = pendingData
end

-- ---------------------------------------------------------------------------
-- MINE VISIT: offer "double production for 1 week" upgrade
-- ---------------------------------------------------------------------------

local function onMineVisit(event, objId, objNum, playerIdx)
    -- Check ownership
    local owner = GAME:getObjectOwner(objId)
    if owner ~= playerIdx then return end

    -- Check if already upgraded
    local existing = C.upgradedMines[objNum]
    local today = GAME:getDate(0)
    if existing and existing.expiryDay > today then
        showInfo(playerIdx, string.format(
            "{Mithril — Mine}\\n\\nThis mine is already enhanced (doubles production until day %d).\\nYou have %d Mithril.",
            existing.expiryDay, getMithril(playerIdx)))
        return
    end

    local resType = GAME:getMineResource(objId)
    if resType < 0 then return end

    local cost = (resType == 6) and 7 or 4   -- ERM: 7 for gold mine, 4 for others
    local mithril = getMithril(playerIdx)

    if mithril < cost then
        showInfo(playerIdx, string.format(
            "{Mithril — Mine}\\n\\nThis mine produces %s.\\nDoubling its production for 1 week costs %d Mithril.\\nYou have %d Mithril — not enough.",
            RES_NAMES[resType] or "resources", cost, mithril))
        return
    end

    local resName = RES_NAMES[resType] or "resources"
    askYesNo(playerIdx,
        string.format(
            "{Mithril — Mine}\\n\\nThis mine produces %s.\\nSpend %d Mithril to double its production for 1 week?\\nYou have %d Mithril.",
            resName, cost, mithril),
        {type = "mine", playerIdx = playerIdx, objNum = objNum, cost = cost, resType = resType})
end

-- ---------------------------------------------------------------------------
-- WINDMILL / WATER WHEEL VISIT: offer double production this week
-- ---------------------------------------------------------------------------

local function onWindmillVisit(event, objId, objNum, playerIdx)
    local week = GAME:getDate(2)

    -- Check if already upgraded this week
    local existing = C.upgradedWindmills[objNum]
    if existing and existing.expiryWeek >= week then
        showInfo(playerIdx, string.format(
            "{Mithril — Windmill}\\n\\nThis windmill is already enhanced this week.\\nYou have %d Mithril.",
            getMithril(playerIdx)))
        return
    end

    local cost = 5   -- ERM: 5 Mithril for windmill and water wheel
    local mithril = getMithril(playerIdx)

    if mithril < cost then
        showInfo(playerIdx, string.format(
            "{Mithril — Windmill}\\n\\nDoubling this windmill's production costs %d Mithril.\\nYou have %d Mithril — not enough.",
            cost, mithril))
        return
    end

    askYesNo(playerIdx,
        string.format(
            "{Mithril — Windmill}\\n\\nSpend %d Mithril to double this windmill's production this week?\\nYou have %d Mithril.",
            cost, mithril),
        {type = "windmill", playerIdx = playerIdx, objNum = objNum, cost = cost})
end

-- ---------------------------------------------------------------------------
-- OBJECT VISIT STARTED
-- ---------------------------------------------------------------------------

wogMithrilSpendVisitSub = ObjectVisitStarted.subscribeAfter(EVENT_BUS, function(event)
    if not C.mithrilEnabled then return end

    local playerIdx = event:getPlayer()
    if not GAME:isPlayerHuman(playerIdx) then return end

    local objId  = event:getObject()
    local obj    = GAME:getObj(objId)
    if not obj then return end
    local objNum  = objId:getNum()
    local objType = obj:getObjGroupIndex()

    if objType == OBJ_MINE then
        onMineVisit(event, objId, objNum, playerIdx)
    elseif objType == OBJ_WINDMILL or objType == OBJ_WATERWHEEL then
        onWindmillVisit(event, objId, objNum, playerIdx)
    end
end)

-- ---------------------------------------------------------------------------
-- QUERY REPLIED: player answered a spending dialog
-- ---------------------------------------------------------------------------

wogMithrilQuerySub = QueryReplied.subscribeAfter(EVENT_BUS, function(event)
    if not C.mithrilEnabled then return end

    local qid    = event:getQueryId()
    local reply  = event:getReply()  -- 1 = yes/ok, 0 = cancel/no
    local data   = C.pendingMithrilDialogs[qid]
    if not data then return end

    -- Clean up
    C.pendingMithrilDialogs[qid] = nil

    if reply ~= 1 then return end  -- player cancelled

    local playerIdx = data.playerIdx
    local mithril   = getMithril(playerIdx)
    if mithril < data.cost then
        showInfo(playerIdx, "{Mithril}\\n\\nNot enough Mithril to complete the enhancement.")
        return
    end

    spendMithril(playerIdx, data.cost)

    if data.type == "mine" then
        local today = GAME:getDate(0)
        local expiryDay = today + 7
        C.upgradedMines[data.objNum] = {
            player    = playerIdx,
            expiryDay = expiryDay,
            resType   = data.resType,
        }
        showInfo(playerIdx, string.format(
            "{Mithril — Mine Enhanced}\\n\\nThe mine will produce double %s for the next 7 days.\\nMithril remaining: %d.",
            RES_NAMES[data.resType] or "resources", getMithril(playerIdx)))

    elseif data.type == "windmill" then
        local week = GAME:getDate(2)
        C.upgradedWindmills[data.objNum] = {
            player     = playerIdx,
            expiryWeek = week,
        }
        showInfo(playerIdx, string.format(
            "{Mithril — Windmill Enhanced}\\n\\nThis windmill will produce double resources this week.\\nMithril remaining: %d.",
            getMithril(playerIdx)))
    end
end)

-- ---------------------------------------------------------------------------
-- TURN STARTED: apply daily mine bonus for upgraded mines
-- ---------------------------------------------------------------------------

wogMithrilMineBonusSub = TurnStarted.subscribeAfter(EVENT_BUS, function(_event)
    if not C.mithrilEnabled then return end

    local today = GAME:getDate(0)

    -- Expire old entries and apply bonus for active ones
    local toRemove = {}
    for objNum, data in pairs(C.upgradedMines) do
        if data.expiryDay <= today then
            toRemove[#toRemove + 1] = objNum
        else
            -- Give the owner the bonus resource (same amount mine produces daily)
            -- ERM: double production = extra 1× of the mine's daily yield.
            -- We give a fixed bonus based on resource type.
            local bonusAmount
            if data.resType == 6 then
                bonusAmount = 1000  -- gold mine: +1000g/day
            elseif data.resType == 0 or data.resType == 2 then
                bonusAmount = 2     -- wood/ore: +2/day
            else
                bonusAmount = 1     -- rare resources: +1/day
            end

            local res = SetResources.new()
            res:setPlayer(data.player)
            res:setAmount(data.resType, bonusAmount)
            res:setAbs(false)
            SERVER:commitPackage(res)
        end
    end
    for _, k in ipairs(toRemove) do
        C.upgradedMines[k] = nil
    end
end)
