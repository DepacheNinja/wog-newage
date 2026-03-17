-- wog_artificer.lua
-- WOG New Age — Artificer (option 26)
--
-- ERM script26 by Perfecto (idea by Dieter Averbeck), v2.2.3.
-- Classic WOG: place object 63/52 on map; hero visits to upgrade one equipped
-- artifact to the next tier.  Up to 2 upgrades per Artificer per day;
-- the second visit costs double.
--
-- VCMI port notes:
--   - Object type key: "wogArtificer" (registered in config/objects/wog_artificer.json)
--   - Interactive dialog not available server-side; auto-selects the most expensive
--     artifact the hero can currently afford (largest gold cost wins).
--   - Mithril secondary-resource cost is skipped until Mithril system is implemented.
--   - Ban checks (e.g. Orb of Inhibition, Sea Captain's Hat) are omitted for now.
--
-- Upgrade table built from ERM FU160 slot checks and FU166 (FU171) corrections:
--   Default:    newId = oldId + 1
--   Exceptions: 45→108, 69→99, 70→98, 71→123, 83→126, 94→96, 97→99, 116→115, 117→116
--
-- Cost table from ERM FU171 lines (gold only):
--   1000:  7,13,19,25,46,47,48,49,50,51,76,103,104,118
--   1500:  8,14,20,26,54,57,60,63,66,73,119
--   2000:  9,15,21,27,31,37,41,77,120
--   2500:  10,16,22,28,117,121
--   3000:  38,42,55,58,61,64,67,74,116
--   4000:  32,39,43,94,95
--   5000:  45,71,79,80,81,82
--   6000:  33
--   7500:  11,17,23,29,70
--   8000:  34,69,97
--   10000: 35,83,86,87,88,89

local ObjectVisitStarted = require("events.ObjectVisitStarted")
local InfoWindow         = require("netpacks.InfoWindow")
local SetResources       = require("netpacks.SetResources")
local GiveHeroArtifact   = require("netpacks.GiveHeroArtifact")
local EraseHeroArtifact  = require("netpacks.EraseHeroArtifact")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.artificerEnabled = C.artificerEnabled ~= false

-- ---------------------------------------------------------------------------
-- UPGRADE TABLE
-- artId (before) → artId (after)
-- Source: ERM FU160 slot checks (which IDs are eligible per slot) combined
-- with FU166/FU171 upgrade logic (x2 = x1+1, with named corrections).
-- ---------------------------------------------------------------------------
local UPGRADE_TABLE = {
    -- Head (slot 0): 19→20→21→22→23→24 (Helm of Alabaster Unicorn chain → Thunder Helmet)
    [19] = 20,   -- Helm of the Alabaster Unicorn → Skull Helmet
    [20] = 21,   -- Skull Helmet → Helm of Chaos
    [21] = 22,   -- Helm of Chaos → Crown of the Supreme Magi
    [22] = 23,   -- Crown of the Supreme Magi → Hellstorm Helmet
    [23] = 24,   -- Hellstorm Helmet → Thunder Helmet

    -- Shoulders (slot 1)
    [42] = 43,   -- Dragon Wing Tabard → Necklace of Dragonteeth
    [55] = 56,   -- Vampire's Cowl → Dead Man's Boots
    [58] = 59,   -- Surcoat of Counterpoise → Boots of Polarity
    [83] = 126,  -- Recanter's Cloak → Orb of Inhibition (ERM exception)

    -- Neck (slot 2)
    [33] = 34,   -- Celestial Necklace of Bliss → Lion's Shield of Courage
    [43] = 44,   -- Necklace of Dragonteeth → Crown of Dragontooth
    [54] = 55,   -- Amulet of the Undertaker → Vampire's Cowl
    [57] = 58,   -- Garniture of Interference → Surcoat of Counterpoise
    [66] = 67,   -- Statesman's Medal → Diplomat's Ring
    [71] = 123,  -- Necklace of Ocean Guidance → Sea Captain's Hat (ERM exception)
    [76] = 77,   -- Collar of Conjuring → Ring of Conjuring
    [97] = 99,   -- Necklace of Swiftness → Cape of Velocity (ERM exception)

    -- Right hand (slot 3)
    [7]  = 8,    -- Centaur Axe → Blackshard of the Dead Knight
    [8]  = 9,    -- Blackshard of the Dead Knight → Greater Gnoll's Flail
    [9]  = 10,   -- Greater Gnoll's Flail → Ogre's Club of Havoc
    [10] = 11,   -- Ogre's Club of Havoc → Sword of Hellfire
    [11] = 12,   -- Sword of Hellfire → Titan's Gladius
    [35] = 36,   -- Sword of Judgement → Helm of Heavenly Enlightenment
    [38] = 39,   -- Red Dragon Flame Tongue → Dragon Scale Shield

    -- Left hand (slot 4)
    [13] = 14,   -- Shield of the Dwarven Lords → Shield of the Yawning Dead
    [14] = 15,   -- Shield of the Yawning Dead → Buckler of the Gnoll King
    [15] = 16,   -- Buckler of the Gnoll King → Targ of the Rampaging Ogre
    [16] = 17,   -- Targ of the Rampaging Ogre → Shield of the Damned
    [17] = 18,   -- Shield of the Damned → Sentinel's Shield
    [34] = 35,   -- Lion's Shield of Courage → Sword of Judgement
    [39] = 40,   -- Dragon Scale Shield → Dragon Scale Armor

    -- Torso (slot 5)
    [25] = 26,   -- Breastplate of Petrified Wood → Rib Cage
    [26] = 27,   -- Rib Cage → Scales of the Greater Basilisk
    [27] = 28,   -- Scales of the Greater Basilisk → Tunic of the Cyclops King
    [28] = 29,   -- Tunic of the Cyclops King → Breastplate of Brimstone
    [29] = 30,   -- Breastplate of Brimstone → Titan's Cuirass
    [31] = 32,   -- Armor of Wonder → Sandals of the Saint

    -- Right ring / Left ring (slots 6 and 7 — same eligible IDs)
    [37] = 38,   -- Quiet Eye of the Dragon → Red Dragon Flame Tongue
    [45] = 108,  -- Still Eye of the Dragon → Pendant of Courage (ERM exception)
    [67] = 68,   -- Diplomat's Ring → Ambassador's Sash
    [69] = 99,   -- Ring of the Wayfarer → Cape of Velocity (ERM exception)
    [70] = 98,   -- Equestrian's Gloves → Boots of Speed (ERM exception)
    [77] = 78,   -- Ring of Conjuring → Cape of Conjuring
    [94] = 96,   -- Ring of Vitality → Vial of Lifeblood (ERM exception)
    [95] = 96,   -- Ring of Life → Vial of Lifeblood (x1+1=96 — same destination, correct)

    -- Feet (slot 8)
    [32] = 33,   -- Sandals of the Saint → Celestial Necklace of Bliss
    [41] = 42,   -- Dragonbone Greaves → Dragon Wing Tabard

    -- Misc slots 1-4 and 5 (slots 9-12, 18)
    [60] = 61,   -- Bow of Elven Cherrywood → Bowstring of the Unicorn's Mane
    [61] = 62,   -- Bowstring of the Unicorn's Mane → Angel Feather Arrows
    [63] = 64,   -- Bird of Perception → Stoic Watchman
    [64] = 65,   -- Stoic Watchman → Emblem of Cognizance
    [73] = 74,   -- Charm of Mana → Talisman of Mana
    [74] = 75,   -- Talisman of Mana → Mystic Orb of Mana
    [116] = 115, -- Endless Bag of Gold → Endless Sack of Gold (ERM exception: 116→115)
    [117] = 116, -- Endless Purse of Gold → Endless Bag of Gold (ERM exception: 117→116)
    [118] = 119, -- Legs of Legion → Loins of Legion
    [119] = 120, -- Loins of Legion → Torso of Legion
    [120] = 121, -- Torso of Legion → Arms of Legion
    [121] = 122, -- Arms of Legion → Head of Legion
}

-- ---------------------------------------------------------------------------
-- GOLD COST TABLE
-- Source: ERM FU171 VRv4135 lines (gold only; Mithril costs omitted).
-- ---------------------------------------------------------------------------
local UPGRADE_COST = {}
for _, id in ipairs({7,13,19,25,46,47,48,49,50,51,76,103,104,118}) do UPGRADE_COST[id] = 1000 end
for _, id in ipairs({8,14,20,26,54,57,60,63,66,73,119})            do UPGRADE_COST[id] = 1500 end
for _, id in ipairs({9,15,21,27,31,37,41,77,120})                  do UPGRADE_COST[id] = 2000 end
for _, id in ipairs({10,16,22,28,117,121})                         do UPGRADE_COST[id] = 2500 end
for _, id in ipairs({38,42,55,58,61,64,67,74,116})                 do UPGRADE_COST[id] = 3000 end
for _, id in ipairs({32,39,43,94,95})                              do UPGRADE_COST[id] = 4000 end
for _, id in ipairs({45,71,79,80,81,82})                           do UPGRADE_COST[id] = 5000 end
UPGRADE_COST[33] = 6000
for _, id in ipairs({11,17,23,29,70})                              do UPGRADE_COST[id] = 7500 end
for _, id in ipairs({34,69,97})                                    do UPGRADE_COST[id] = 8000 end
for _, id in ipairs({35,83,86,87,88,89})                           do UPGRADE_COST[id] = 10000 end

-- Equipped artifact slots checked (matches ERM HE-1:A1/?v410x/slotNum)
local EQUIPPED_SLOTS = {0,1,2,3,4,5,6,7,8,9,10,11,12,18}

-- Daily visit tracking per Artificer object instance
-- key = objectId integer, value = {day=N, count=M}
C.artificerVisits = C.artificerVisits or {}

-- ---------------------------------------------------------------------------
-- EVENT HANDLER
-- ---------------------------------------------------------------------------
wogArtificerSub = ObjectVisitStarted.subscribeAfter(EVENT_BUS, function(event)
    if not C.artificerEnabled then return end

    local objId = event:getObject()
    local obj   = GAME:getObj(objId)
    if not obj then return end
    if obj:getSubtypeName() ~= "wogArtificer" then return end

    local playerIdx = event:getPlayer()
    if not GAME:isPlayerHuman(playerIdx) then return end

    local heroId = event:getHero()
    local hero   = GAME:getHero(heroId)
    if not hero then return end

    -- Daily limit tracking
    local today     = GAME:getDate(0)
    local objNum    = objId:getNum()
    local visitData = C.artificerVisits[objNum] or {day = 0, count = 0}
    if visitData.day ~= today then
        visitData = {day = today, count = 0}
    end

    if visitData.count >= 2 then
        local pack = InfoWindow.new()
        pack:setPlayer(playerIdx)
        pack:addText("{Artificer}\n\nThe Artificer is exhausted for today. Return tomorrow.")
        SERVER:commitPackage(pack)
        return
    end

    -- Second visit costs double (ERM: v4135 * v160; v160=1 first visit, 2 second)
    local costMult = (visitData.count == 1) and 2 or 1

    -- Collect upgradeable artifacts equipped on this hero
    local candidates = {}
    for _, slot in ipairs(EQUIPPED_SLOTS) do
        local artId = hero:getArtifactAtSlot(slot)
        if artId >= 0 and UPGRADE_TABLE[artId] then
            local baseCost = UPGRADE_COST[artId] or 1000
            local cost     = baseCost * costMult
            candidates[#candidates + 1] = {
                slot     = slot,
                artId    = artId,
                newArtId = UPGRADE_TABLE[artId],
                cost     = cost,
            }
        end
    end

    if #candidates == 0 then
        local pack = InfoWindow.new()
        pack:setPlayer(playerIdx)
        pack:addText("{Artificer}\n\nThe Artificer studies your equipment carefully, but finds nothing worthy of improvement.")
        SERVER:commitPackage(pack)
        return
    end

    -- Sort descending by cost; pick the most expensive one the hero can afford
    table.sort(candidates, function(a, b) return a.cost > b.cost end)

    local gold   = GAME:getPlayerResource(playerIdx, 6)  -- 6 = gold
    local chosen = nil
    for _, c in ipairs(candidates) do
        if gold >= c.cost then
            chosen = c
            break
        end
    end

    if not chosen then
        -- Can't afford any upgrade — report the cheapest option
        local cheapest = candidates[#candidates]
        local pack = InfoWindow.new()
        pack:setPlayer(playerIdx)
        pack:addText(string.format(
            "{Artificer}\n\nThe Artificer would need at least %d gold to improve your weakest artifact, but your treasury falls short.",
            cheapest.cost))
        SERVER:commitPackage(pack)
        return
    end

    -- Remove old artifact from its slot
    local erase = EraseHeroArtifact.new()
    erase:setHeroId(heroId)
    erase:addSlot(chosen.slot)
    SERVER:commitPackage(erase)

    -- Give upgraded artifact (prefer same slot; engine falls back to FIRST_AVAILABLE)
    local give = GiveHeroArtifact.new()
    give:setHeroId(heroId)
    give:setArtTypeId(chosen.newArtId)
    give:setSlot(chosen.slot)
    SERVER:commitPackage(give)

    -- Deduct gold (relative, negative amount)
    local res = SetResources.new()
    res:setPlayer(playerIdx)
    res:setAmount(6, -chosen.cost)
    res:setAbs(false)
    SERVER:commitPackage(res)

    -- Update visit tracker
    visitData.count              = visitData.count + 1
    C.artificerVisits[objNum]    = visitData

    -- Confirmation message
    local doubleNote = costMult == 2 and "\n(Second upgrade today — double price.)" or ""
    local pack = InfoWindow.new()
    pack:setPlayer(playerIdx)
    pack:addText(string.format(
        "{Artificer}\n\nThe skilled Artificer upgrades your equipment for %d gold.%s",
        chosen.cost, doubleNote))
    SERVER:commitPackage(pack)
end)
