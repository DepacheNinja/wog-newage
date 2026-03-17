-- wog_mithril_accumulation.lua
-- WOG New Age — Mithril Accumulation (options 170/171)
--
-- ERM script36 by Anders Jonsson, v1.4.
-- Classic WOG:
--   Option 170: At game start (day 1 only), replaces 1 in 15 resource piles and
--     1 in 15 campfires with Mithril stacks. Each pile/campfire gives Mithril
--     equal to the original amount (half for wood/ore/gold).
--   Option 171: Weekly (day 1 of each week), 1 in 10 windmills, water wheels,
--     and mystical gardens give Mithril instead of their normal resource.
--
-- VCMI port notes:
--   - Mithril is stored as DATA.WOG.playerMithril[playerIdx] (custom counter,
--     not a real game resource — VCMI has only 7 resources, 0-6).
--   - Resource pile / campfire replacement: we MARK selected piles on day 1
--     (stored by ObjectInstanceID in C.mithrilPiles). When a hero visits one,
--     ObjectVisitStarted fires, Mithril is added, and the pile is removed.
--     The hero also receives the pile's normal resource (small deviation from
--     ERM which replaces rather than supplements — acceptable approximation).
--   - Windmill / water wheel / mystical garden: 1 in 10 are marked weekly in
--     C.mithrilWindmills. On visit, bonus Mithril is given in addition to the
--     normal resource (same deviation noted above).
--   - Campfire Mithril amounts: 3-6 bars (ERM: half the campfire gold amount
--     expressed as bars). Fixed at 4 per Mithril campfire as ERM average.
--   - Resource pile Mithril amounts: proportional to pile value
--     (wood/ore/gold: half amount, other: full amount; minimum 3, maximum 10).
--   - Day-1 seeding never re-runs on save/load (guarded by C.mithrilSeeded).
--
-- Frequencies (ERM defaults, configurable via wog_config.lua):
--   C.mithrilPileFreq      = 15  (1 in N resource piles get Mithril)
--   C.mithrilCampfireFreq  = 15  (1 in N campfires get Mithril)
--   C.mithrilWindmillFreq  = 10  (1 in N windmills/wheels/gardens get Mithril)

local ObjectVisitStarted = require("events.ObjectVisitStarted")
local TurnStarted        = require("events.TurnStarted")
local SetResources       = require("netpacks.SetResources")
local RemoveMapObject    = require("netpacks.RemoveMapObject")
local InfoWindow         = require("netpacks.InfoWindow")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.mithrilAccumEnabled  = C.mithrilAccumEnabled  ~= false
C.mithrilPileFreq      = C.mithrilPileFreq      or 15
C.mithrilCampfireFreq  = C.mithrilCampfireFreq  or 15
C.mithrilWindmillFreq  = C.mithrilWindmillFreq  or 10

-- Persistent state (survives save/load via DATA.WOG)
C.mithrilSeeded        = C.mithrilSeeded        or false
C.playerMithril        = C.playerMithril        or {}
-- mithrilPiles[objIdNum] = mithrilAmount
C.mithrilPiles         = C.mithrilPiles         or {}
-- mithrilWindmills[objIdNum] = mithrilAmount  (reset each week)
C.mithrilWindmills     = C.mithrilWindmills     or {}
-- week number when windmills were last seeded
C.mithrilWindmillWeek  = C.mithrilWindmillWeek  or 0

-- ---------------------------------------------------------------------------
-- HELPERS
-- ---------------------------------------------------------------------------

-- ERM object type indices (getObjGroupIndex returns these)
local OBJ_RESOURCE  = 79   -- resource pile
local OBJ_CAMPFIRE  = 12   -- campfire
local OBJ_WINDMILL  = 112  -- windmill
local OBJ_WATERWHEEL = 109 -- water wheel
local OBJ_GARDEN    = 55   -- mystical garden

-- ERM resource subtypes for resource piles
local RES_WOOD = 0; local RES_ORE = 2; local RES_GOLD = 6

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function playerMithril(playerIdx)
    C.playerMithril[playerIdx] = C.playerMithril[playerIdx] or 0
    return C.playerMithril[playerIdx]
end

local function addMithril(playerIdx, amount)
    C.playerMithril[playerIdx] = (C.playerMithril[playerIdx] or 0) + amount
end

-- Notify a human player they found Mithril
local function notifyMithril(playerIdx, found, total)
    local pack = InfoWindow.new()
    pack:setPlayer(playerIdx)
    pack:addText(string.format(
        "{Mithril}\\n\\nYou found %d bar%s of Mithril!\\nYou now have %d bar%s.",
        found, found == 1 and "" or "s",
        total, total == 1 and "" or "s"))
    SERVER:commitPackage(pack)
end

-- ---------------------------------------------------------------------------
-- DAY-1 SEEDING: mark 1/N resource piles and campfires as Mithril sources
-- ---------------------------------------------------------------------------

local function seedMithrilPiles()
    local freq = clamp(C.mithrilPileFreq, 2, 49)
    local objIds = GAME:getMapObjectIds()
    local pileCount = 0
    local marked = 0
    -- First pass: count piles
    for _, objId in ipairs(objIds) do
        local obj = GAME:getObj(objId)
        if obj and obj:getObjGroupIndex() == OBJ_RESOURCE then
            pileCount = pileCount + 1
        end
    end
    if pileCount == 0 then return end
    -- Start at a random offset (ERM: random 1..min(10,pileCount))
    local startIdx = math.random(1, math.min(10, pileCount))
    local idx = 0
    for _, objId in ipairs(objIds) do
        local obj = GAME:getObj(objId)
        if obj and obj:getObjGroupIndex() == OBJ_RESOURCE then
            idx = idx + 1
            -- From startIdx onward, mark every freq-th pile
            if idx >= startIdx and ((idx - startIdx) % freq) == 0 then
                local subtype = obj:getObjTypeIndex()  -- resource type 0-6
                -- ERM: halve amount for wood/ore/gold; fixed Mithril amount
                -- Since we can't read pile amount from Lua, use a fixed range
                -- based on resource type (approximation of ERM FU8179 logic)
                local amount
                if subtype == RES_WOOD or subtype == RES_ORE or subtype == RES_GOLD then
                    amount = math.random(3, 5)  -- halved small amounts
                else
                    amount = math.random(4, 8)  -- full amounts for rares
                end
                amount = clamp(amount, 3, 10)
                local objNum = objId:getNum()
                C.mithrilPiles[objNum] = amount
                marked = marked + 1
            end
        end
    end
end

local function seedMithrilCampfires()
    local freq = clamp(C.mithrilCampfireFreq, 2, 49)
    local objIds = GAME:getMapObjectIds()
    local campCount = 0
    local marked = 0
    for _, objId in ipairs(objIds) do
        local obj = GAME:getObj(objId)
        if obj and obj:getObjGroupIndex() == OBJ_CAMPFIRE then
            campCount = campCount + 1
        end
    end
    if campCount == 0 then return end
    local startIdx = math.random(1, math.min(10, campCount))
    local idx = 0
    for _, objId in ipairs(objIds) do
        local obj = GAME:getObj(objId)
        if obj and obj:getObjGroupIndex() == OBJ_CAMPFIRE then
            idx = idx + 1
            if idx >= startIdx and ((idx - startIdx) % freq) == 0 then
                local objNum = objId:getNum()
                -- ERM: campfire Mithril amount = half of campfire gold/1000
                -- Fixed at 4 bars (ERM average for a typical campfire)
                C.mithrilPiles[objNum] = 4
                marked = marked + 1
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- WEEKLY SEEDING: mark 1/N windmills, water wheels, mystical gardens
-- ---------------------------------------------------------------------------

local function seedMithrilWindmills()
    local freq = clamp(C.mithrilWindmillFreq, 2, 49)
    C.mithrilWindmills = {}
    local types = {OBJ_WINDMILL, OBJ_WATERWHEEL, OBJ_GARDEN}
    local objIds = GAME:getMapObjectIds()

    for _, objType in ipairs(types) do
        local bucket = {}
        for _, objId in ipairs(objIds) do
            local obj = GAME:getObj(objId)
            if obj and obj:getObjGroupIndex() == objType then
                bucket[#bucket + 1] = objId
            end
        end
        if #bucket > 0 then
            local startIdx = math.random(1, math.min(10, #bucket))
            for i, objId in ipairs(bucket) do
                if i >= startIdx and ((i - startIdx) % freq) == 0 then
                    local objNum = objId:getNum()
                    -- ERM: 1 bar of Mithril per windmill/wheel/garden (v71 frequency check)
                    C.mithrilWindmills[objNum] = math.random(2, 4)
                end
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- TURN STARTED: handle day-1 seeding and weekly windmill reset
-- ---------------------------------------------------------------------------

wogMithrilAccumTurnSub = TurnStarted.subscribeAfter(EVENT_BUS, function(_event)
    if not C.mithrilAccumEnabled then return end

    local day  = GAME:getDate(0)
    local week = GAME:getDate(2)

    -- Day-1 only: seed resource piles and campfires
    if day == 1 and not C.mithrilSeeded then
        seedMithrilPiles()
        seedMithrilCampfires()
        C.mithrilSeeded = true
    end

    -- Weekly (day 1 of each week, once per week)
    local dayOfWeek = ((day - 1) % 7) + 1
    if dayOfWeek == 1 and C.mithrilWindmillWeek ~= week then
        seedMithrilWindmills()
        C.mithrilWindmillWeek = week
    end
end)

-- ---------------------------------------------------------------------------
-- OBJECT VISIT STARTED: give Mithril when hero visits a marked object
-- ---------------------------------------------------------------------------

wogMithrilVisitSub = ObjectVisitStarted.subscribeAfter(EVENT_BUS, function(event)
    if not C.mithrilAccumEnabled then return end

    local playerIdx = event:getPlayer()
    if not GAME:isPlayerHuman(playerIdx) then return end

    local objId  = event:getObject()
    local objNum = objId:getNum()

    -- Check resource pile / campfire Mithril
    local pileAmount = C.mithrilPiles[objNum]
    if pileAmount then
        C.mithrilPiles[objNum] = nil  -- consumed — pile picked up once
        addMithril(playerIdx, pileAmount)
        local total = playerMithril(playerIdx)

        -- Remove the pile from the map (ERM: replaces pile with Mithril object)
        -- The hero also collects the normal resource from the pile (acceptable deviation).
        local remove = RemoveMapObject.new()
        remove:setObjId(objNum)
        SERVER:commitPackage(remove)

        notifyMithril(playerIdx, pileAmount, total)
        return
    end

    -- Check windmill / water wheel / garden Mithril
    local windAmount = C.mithrilWindmills[objNum]
    if windAmount then
        -- Don't consume — windmill can be visited multiple times per week by different heroes
        -- but each player only gets the Mithril once per week (track per player)
        C.mithrilWindmillVisited = C.mithrilWindmillVisited or {}
        local week = GAME:getDate(2)
        local visitKey = objNum .. "_" .. playerIdx .. "_" .. week
        if not C.mithrilWindmillVisited[visitKey] then
            C.mithrilWindmillVisited[visitKey] = true
            addMithril(playerIdx, windAmount)
            local total = playerMithril(playerIdx)
            notifyMithril(playerIdx, windAmount, total)
        end
        return
    end
end)
