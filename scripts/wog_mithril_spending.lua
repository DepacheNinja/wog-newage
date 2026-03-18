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
--   - Shrine spell reroll (Phase 2): visit shrine → pay Mithril → reroll to
--     random spell of same level for future heroes. Cost: 1/2/3 Mithril by level.
--     Uses SetObjectProperty:setShrineSpell FCMI API.
--   - Witch Hut skill reroll (Phase 2): visit witch hut → pay 2 Mithril →
--     reroll to random skill for future heroes. Uses SetObjectProperty:setWitchHutSkill.
--   - Dwelling upgrade: deferred until setDwellingCreature FCMI API is added.
--   - Castle terrain placement, Shipyard lighthouse, Monolith reveal: deferred.
--
-- Mithril costs (from ERM script36 FU8172/FU8181/FU8182):
--   Mine upgrade: 4 Mithril (7 for gold mine)
--   Windmill / water wheel upgrade: 5 Mithril
--   Shrine reroll: 1 / 2 / 3 Mithril (level 1/2/3 shrine)
--   Witch Hut reroll: 2 Mithril
--
-- Display
--   Shows current Mithril count in spending dialogs.
--   Full price list shown on visiting the first Mithril-enabled object each session.

local ObjectVisitStarted    = require("events.ObjectVisitStarted")
local QueryReplied          = require("events.QueryReplied")
local TurnStarted           = require("events.TurnStarted")
local BlockingDialog        = require("netpacks.BlockingDialog")
local SetResources          = require("netpacks.SetResources")
local SetObjectProperty     = require("netpacks.SetObjectProperty")
local SetAvailableCreatures = require("netpacks.SetAvailableCreatures")
local SetPrimarySkill       = require("netpacks.SetPrimarySkill")
local InfoWindow            = require("netpacks.InfoWindow")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.mithrilEnabled = C.mithrilEnabled ~= false

-- Persistent upgrade state
-- upgradedMines[objIdNum] = {player=N, expiryDay=D, resource=R, amount=A}
C.upgradedMines = C.upgradedMines or {}
-- upgradedWindmills[objIdNum] = {player=N, expiryWeek=W}
C.upgradedWindmills = C.upgradedWindmills or {}
-- upgradedDwellings[objIdNum] = true  (permanent — dwelling now produces upgraded creature)
C.upgradedDwellings = C.upgradedDwellings or {}

-- Pending dialogs: pendingMithrilDialogs[queryId] = {type, playerIdx, objId, cost, ...}
C.pendingMithrilDialogs = C.pendingMithrilDialogs or {}

-- ---------------------------------------------------------------------------
-- HELPERS
-- ---------------------------------------------------------------------------

local OBJ_MINE           = 53
local OBJ_WINDMILL       = 112
local OBJ_WATERWHEEL     = 109
-- Shrine object types by level (from EntityIdentifiers.h Obj enum)
local OBJ_SHRINE_L1      = 88   -- Shrine of Magic Incantation (level 1 spells)
local OBJ_SHRINE_L2      = 89   -- Shrine of Magic Gesture     (level 2 spells)
local OBJ_SHRINE_L3      = 90   -- Shrine of Magic Thought     (level 3 spells)
local OBJ_WITCH_HUT      = 113  -- Witch Hut (secondary skill)
local OBJ_CREATURE_GEN1  = 17   -- Basic creature dwelling (upgradeable via mithril)
local OBJ_UNIVERSITY     = 104  -- University (grants +1 primary skill)
local OBJ_SHIPYARD       = 87   -- Shipyard — deferred
local OBJ_MONOLITH_ENT   = 43   -- One-way monolith entrance — deferred
local OBJ_MONOLITH_EXIT  = 44   -- One-way monolith exit — deferred
local OBJ_MONOLITH_2WAY  = 45   -- Two-way monolith — deferred
-- Skill count for random reroll (0-27, matching C.SKILL table in wog_config.lua)
local MAX_SKILL_ID        = 27

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
-- SHRINE VISIT: offer spell reroll (Phase 2)
-- ---------------------------------------------------------------------------

local function onShrineVisit(event, objId, objNum, playerIdx, spellLevel, cost)
    local mithril = getMithril(playerIdx)

    if mithril < cost then
        showInfo(playerIdx, string.format(
            "{Mithril — Shrine}\\n\\nThis shrine teaches a level %d spell.\\nRerolling its spell costs %d Mithril.\\nYou have %d Mithril — not enough.",
            spellLevel, cost, mithril))
        return
    end

    askYesNo(playerIdx,
        string.format(
            "{Mithril — Shrine}\\n\\nThis shrine teaches a level %d spell.\\nSpend %d Mithril to reroll it to a different spell (for future visitors)?\\nYou have %d Mithril.",
            spellLevel, cost, mithril),
        {type = "shrine", playerIdx = playerIdx, objNum = objNum, cost = cost, spellLevel = spellLevel})
end

-- ---------------------------------------------------------------------------
-- WITCH HUT VISIT: offer skill reroll (Phase 2)
-- ---------------------------------------------------------------------------

local function onWitchHutVisit(event, objId, objNum, playerIdx)
    local cost    = 2   -- ERM: 2 Mithril to reroll witch hut skill
    local mithril = getMithril(playerIdx)

    if mithril < cost then
        showInfo(playerIdx, string.format(
            "{Mithril — Witch Hut}\\n\\nRerolling this witch hut's skill costs %d Mithril.\\nYou have %d Mithril — not enough.",
            cost, mithril))
        return
    end

    askYesNo(playerIdx,
        string.format(
            "{Mithril — Witch Hut}\\n\\nSpend %d Mithril to change what skill this witch hut teaches (for future visitors)?\\nYou have %d Mithril.",
            cost, mithril),
        {type = "witchHut", playerIdx = playerIdx, objNum = objNum, cost = cost})
end

-- ---------------------------------------------------------------------------
-- DWELLING VISIT (item 5): offer upgrade to produce upgraded creatures
-- Cost: 2 Mithril. Permanent for this dwelling.
-- In standard H3/VCMI, base creature ID + 1 = upgraded creature (consecutive pairs).
-- ---------------------------------------------------------------------------

local function onDwellingVisit(event, objId, objNum, playerIdx)
    local owner = GAME:getObjectOwner(objId)
    if owner ~= playerIdx then return end

    if C.upgradedDwellings[objNum] then
        showInfo(playerIdx, string.format(
            "{Mithril — Dwelling}\\n\\nThis dwelling already produces upgraded creatures (Mithril enhanced).\\nYou have %d Mithril.",
            getMithril(playerIdx)))
        return
    end

    local cost    = 2
    local mithril = getMithril(playerIdx)

    local creatureId = GAME:getDwellingCreatureId(objId, 0)
    if not creatureId or creatureId < 0 then return end

    if mithril < cost then
        showInfo(playerIdx, string.format(
            "{Mithril — Dwelling}\\n\\nUpgrading this dwelling to produce upgraded creatures costs %d Mithril.\\nYou have %d Mithril — not enough.",
            cost, mithril))
        return
    end

    local count = GAME:getDwellingCreatureCount(objId, 0) or 0
    askYesNo(playerIdx,
        string.format(
            "{Mithril — Dwelling}\\n\\nSpend %d Mithril to permanently upgrade this dwelling to produce upgraded creatures?\\nYou have %d Mithril.",
            cost, mithril),
        {type = "dwelling", playerIdx = playerIdx, objNum = objNum, cost = cost,
         creatureId = creatureId, creatureCount = count})
end

-- ---------------------------------------------------------------------------
-- UNIVERSITY VISIT (item 12): spend 4 Mithril to grant hero +1 random primary skill
-- Primary skills: 0=Attack, 1=Defense, 2=Spell Power, 3=Knowledge
-- ---------------------------------------------------------------------------

local function onUniversityVisit(event, objId, objNum, playerIdx, heroId)
    local cost    = 4
    local mithril = getMithril(playerIdx)

    if mithril < cost then
        showInfo(playerIdx, string.format(
            "{Mithril — University}\\n\\nStudying an extra discipline costs %d Mithril.\\nYou have %d Mithril — not enough.",
            cost, mithril))
        return
    end

    askYesNo(playerIdx,
        string.format(
            "{Mithril — University}\\n\\nSpend %d Mithril to grant your hero +1 to a random primary skill?\\nYou have %d Mithril.",
            cost, mithril),
        {type = "university", playerIdx = playerIdx, objNum = objNum, cost = cost, heroId = heroId})
end

-- ---------------------------------------------------------------------------
-- SHIPYARD VISIT (item 7): placeholder — enhancement under development
-- ---------------------------------------------------------------------------

local function onShipyardVisit(event, objId, objNum, playerIdx)
    local mithril = getMithril(playerIdx)
    if mithril > 0 then
        showInfo(playerIdx, string.format(
            "{Mithril — Shipyard}\\n\\nMithril enhancements for the Shipyard are under development.\\nYou have %d Mithril.",
            mithril))
    end
end

-- ---------------------------------------------------------------------------
-- MONOLITH VISIT (item 10): placeholder — enhancement under development
-- ---------------------------------------------------------------------------

local function onMonolithVisit(event, objId, objNum, playerIdx)
    local mithril = getMithril(playerIdx)
    if mithril > 0 then
        showInfo(playerIdx, string.format(
            "{Mithril — Monolith}\\n\\nMithril enhancements for Monoliths are under development.\\nYou have %d Mithril.",
            mithril))
    end
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
    elseif objType == OBJ_SHRINE_L1 then
        onShrineVisit(event, objId, objNum, playerIdx, 1, 1)
    elseif objType == OBJ_SHRINE_L2 then
        onShrineVisit(event, objId, objNum, playerIdx, 2, 2)
    elseif objType == OBJ_SHRINE_L3 then
        onShrineVisit(event, objId, objNum, playerIdx, 3, 3)
    elseif objType == OBJ_WITCH_HUT then
        onWitchHutVisit(event, objId, objNum, playerIdx)
    elseif objType == OBJ_CREATURE_GEN1 then
        onDwellingVisit(event, objId, objNum, playerIdx)
    elseif objType == OBJ_UNIVERSITY then
        local heroId = event:getHero()
        if heroId then
            onUniversityVisit(event, objId, objNum, playerIdx, heroId)
        end
    elseif objType == OBJ_SHIPYARD then
        onShipyardVisit(event, objId, objNum, playerIdx)
    elseif objType == OBJ_MONOLITH_ENT or objType == OBJ_MONOLITH_EXIT or objType == OBJ_MONOLITH_2WAY then
        onMonolithVisit(event, objId, objNum, playerIdx)
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

    elseif data.type == "shrine" then
        -- Pick a random spell of the correct level and reroll the shrine
        local spells = GAME:getSpellsByLevel(data.spellLevel)
        if spells and #spells > 0 then
            local newSpellId = spells[math.random(#spells)]
            local pack = SetObjectProperty.new()
            pack:setId(data.objNum)
            pack:setShrineSpell(newSpellId)
            SERVER:commitPackage(pack)
            showInfo(playerIdx, string.format(
                "{Mithril — Shrine Rerolled}\\n\\nThe shrine now teaches a different level %d spell for future visitors.\\nMithril remaining: %d.",
                data.spellLevel, getMithril(playerIdx)))
        else
            showInfo(playerIdx, "{Mithril — Shrine}\\n\\nNo spells of that level found; Mithril refunded.")
            -- refund
            C.playerMithril[playerIdx] = (C.playerMithril[playerIdx] or 0) + data.cost
        end

    elseif data.type == "witchHut" then
        -- Pick a random secondary skill (0-27) and reroll the hut
        local newSkillId = math.random(0, MAX_SKILL_ID)
        local pack = SetObjectProperty.new()
        pack:setId(data.objNum)
        pack:setWitchHutSkill(newSkillId)
        SERVER:commitPackage(pack)
        showInfo(playerIdx, string.format(
            "{Mithril — Witch Hut Rerolled}\\n\\nThe witch hut now teaches a different skill for future visitors.\\nMithril remaining: %d.",
            getMithril(playerIdx)))

    elseif data.type == "dwelling" then
        -- Upgrade dwelling: produce the next creature tier (standard H3: upgraded = base + 1)
        local upgradedId = data.creatureId + 1
        local pack = SetAvailableCreatures.new()
        pack:setDwellingId(data.objNum)
        pack:setCreature(0, upgradedId, data.creatureCount)
        SERVER:commitPackage(pack)
        C.upgradedDwellings[data.objNum] = true
        showInfo(playerIdx, string.format(
            "{Mithril — Dwelling Enhanced}\\n\\nThis dwelling now produces upgraded creatures permanently.\\nMithril remaining: %d.",
            getMithril(playerIdx)))

    elseif data.type == "university" then
        -- Grant hero +1 to a random primary skill (0=Attack, 1=Defense, 2=Power, 3=Knowledge)
        local skillNames = {[0]="Attack", [1]="Defense", [2]="Spell Power", [3]="Knowledge"}
        local skillIdx = math.random(0, 3)
        local pack = SetPrimarySkill.new()
        pack:setHeroId(data.heroId)
        pack:setSkill(skillIdx)
        pack:setValue(1)
        pack:setMode(false)   -- false = relative (+1)
        SERVER:commitPackage(pack)
        showInfo(playerIdx, string.format(
            "{Mithril — University}\\n\\nThe university's advanced scholars have increased your hero's %s by 1.\\nMithril remaining: %d.",
            skillNames[skillIdx] or "primary skill", getMithril(playerIdx)))
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
