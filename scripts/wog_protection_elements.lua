-- wog_protection_elements.lua
-- WOG New Age — Enhanced Protection from Elements (option 61)
--
-- In vanilla H3, Protection from Air/Fire/Water/Earth only reduces SPELL damage
-- from that school. Elemental creatures deal physical damage, so they bypass it.
--
-- WOG option 61 extends protection to physical attacks from opposing elementals:
--   Fire Elementals (114,129) vs target with protectFire (31) → 30/50% reduction
--   Air Elementals (112,127)  vs target with protectAir (30)  → 30/50% reduction
--   Water Elementals (115,123) vs target with protectWater (32) → 30/50% reduction
--   Earth Elementals (113,125) vs target with protectEarth (33) → 30/50% reduction
--
-- Reduction amount: 30% (basic) or 50% (advanced/expert).
-- VCMI currently stores the highest spell level bonus value on the unit —
-- we check hasBonusFromSpell and apply a fixed 35% as a practical middle ground
-- (between basic 30% and advanced/expert 50%) since we cannot easily query level.

local ApplyDamage = require("events.ApplyDamage")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.protectionElementsEnabled = C.protectionElementsEnabled ~= false
C.protectionReductionPct    = C.protectionReductionPct or 35

-- Spell index → set of elemental creature IDs that this spell protects against
-- Spell indices from fcmi/config/spells/timed.json:
--   protectAir=30, protectFire=31, protectWater=32, protectEarth=33
-- Creature indices from fcmi/config/creatures/conflux.json:
--   airElemental=112, stormElemental=127
--   fireElemental=114, energyElemental=129
--   waterElemental=115, iceElemental=123
--   earthElemental=113, magmaElemental=125
local ELEMENT_MAP = {
	-- spellId → creature IDs of the threatening elementals
	[30] = {[112] = true, [127] = true},  -- protectAir  → Air/Storm Elementals
	[31] = {[114] = true, [129] = true},  -- protectFire → Fire/Energy Elementals
	[32] = {[115] = true, [123] = true},  -- protectWater → Water/Ice Elementals
	[33] = {[113] = true, [125] = true},  -- protectEarth → Earth/Magma Elementals
}

-- Reverse: creature ID → protection spell ID
local ELEMENTAL_SPELL = {}
for spellId, creatures in pairs(ELEMENT_MAP) do
	for creatureId, _ in pairs(creatures) do
		ELEMENTAL_SPELL[creatureId] = spellId
	end
end

wogProtectionElementsSub = ApplyDamage.subscribeBefore(EVENT_BUS, function(event)
	if not C.protectionElementsEnabled then return end

	local attacker = event:getAttacker()
	if not attacker then return end
	local target = event:getTarget()
	if not target then return end

	-- Only physical (non-ranged, non-ballista) melee attacks from elementals
	if event:isRanged() or event:isBallistaDmg() then return end

	local attackerCreatureId = attacker:getCreatureId()
	if attackerCreatureId == nil then return end

	-- Is the attacker an elemental type we track?
	local spellId = ELEMENTAL_SPELL[attackerCreatureId]
	if not spellId then return end

	-- Does the target have the matching protection spell active?
	if not target:hasBonusFromSpell(spellId) then return end

	-- Apply physical protection reduction
	local current = event:getDamage()
	if current <= 0 then return end
	local reduced = math.floor(current * (100 - C.protectionReductionPct) / 100)
	if reduced >= current then return end
	event:setDamage(reduced)
end)
