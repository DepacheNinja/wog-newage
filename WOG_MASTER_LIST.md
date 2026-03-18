# WOG New Age — Master Feature List

Decoded from WoGSetupEx04222024.dat. All options you have enabled, organized by category.

**Status codes:**
- ✅ Done — working in mod
- 🟡 Partial — something is in place, needs more work
- 🔴 Todo — needs Lua scripting
- 🏗️ Hard — needs engine (C++) changes first
- ⚫ Map object — only works if the map has that object placed (not automatic)
- ❓ Unknown — couldn't identify yet

---

## ✅ Already Working

| Option | Feature | Notes |
|--------|---------|-------|
| 193 | **Combined Warfare Skills** | Ballistics + Artillery + First Aid synced as one |
| 173 | **Extended Creature Upgrades** | Alt upgrade paths (Santa Gremlins, Sylvan Centaurs, War Zealots, hellSteed→Nightmare for Inferno, Dracolich for Necropolis) |
| Custom | **Combat Hardening** | +20% XP after every won battle |
| Custom | **Daily Gold Bonus** | 100 gold/day per human player |
| 40 | **First Money** | Each player receives 12000 gold + 20 wood/ore + 10 mercury/sulfur/crystal/gems on day 1 (ERM-correct) |
| 38 | **Combat Veteran Bonus** | Custom approximation — WOG option 38 summons extra creatures in neutral battles based on per-hero Karmic Counter, requiring FCMI battle manipulation API not yet available. Implemented as: close battles: winner +5% XP, loser +10% consolation XP |
| 203/191 | **Estates Enhancement** | Extra gold per day = heroLevel × multiplier |
| 35/207 | **Mysticism Enhancement** | 10/20/30% of max SP/day; Intelligence skill multiplies effective mana (Basic ×1.25, Advanced ×1.5, Expert ×2.0) — ERM-correct |
| 205/217 | **Learning Enhancement** | Passive 100/200/300 XP/day per skill level |
| 211 | **Scholar Enhancement** | Weekly 40%/50%/60% chance to research new spell (level 1-4) |
| 23/213 | **Sorcery Enhancement** | Spell damage: 10/20/30% (was 5/10/15%) via JSON |
| 214 | **Armorer Enhancement** | Damage reduction: 10/15/20% (was 5/10/15%) via JSON |
| ~~210~~ | ~~**Resistance Enhancement**~~ | User disabled (✗ in options) — JSON overrides removed from enhanced_skills.json. Vanilla H3 values restored. |
| 208 | **Navigation Enhancement** | Water movement: 60/110/165% (was 50/100/150%) via JSON |
| 209 | **Pathfinding Enhancement** | Terrain penalty: 35/60/75% reduction via JSON |
| 103/202 | **Eagle Eye Enhancement** | Chance 50/65/80% (was 40/50/60%), learns up to level 3/4/5 (was 2/3/4) via JSON |
| ~~212~~ | ~~**Scouting Enhancement**~~ | User disabled (✗ in options) — JSON overrides removed from enhanced_skills.json. Vanilla H3 values restored. |
| 218 | **Tactics Enhancement** | Deployment zone +1 row per level via JSON |
| 206 | **Luck I Enhancement** | Lucky strikes deal +50% initial damage extra (total ~3× normal) via ApplyDamage |
| 201/54 | **Artillery I Enhanced** | ERM formula: (artilleryLevel + heroLevel) × 20 − 20 % extra on ballista double-hit; falls back to +25/50/75% if hero:getLevel() unavailable |
| 194 | **Advanced Witch Huts** | Witch Huts teach at Advanced level; deducts 1000g from player |
| 39 | **Hero Specialization Boost** | +1 primary skill at milestone levels (5/10/15/20/25/30); getHeroTypeId() API now available for further enhancement |
| ~~220~~ | ~~**Battle Extender**~~ | User disabled (✗ in options) — removed from mod.json scripts. wog_battle_extender.lua kept on disk but not loaded. |
| 135 | **Wandering Monsters** | Surviving neutral stacks move 1-2 tiles/week (ChangeObjPos netpack; 33% chance per stack/week) |
| 47 | **Creature Relationships** | Hate pairs: daily intra-army conflict (ERM formula: (14−2×Dip)×moraleMult%, 10−luck% HP loss); Allied pairs: +1 morale + 5% synergy XP (upgrade mechanic requires ChangeCreatureType API not yet in FCMI) |
| 900 | **Stack Experience (approx.)** | Army XP tracked; +1 primary stat per 5000 XP milestone |
| 71 | **Enhanced Artifacts** | Conjuring set adds spell damage; Pendant of Death gives undead +5 ATT/DEF |
| 20 | **Week of Monsters** | ERM-correct: +33% ATK/DEF/Speed/HP/Damage (floor, min +1), +50% growth; week 1 always skipped; war machines (catapult/ballista/firstAidTent) get HP+DEF only; Speed/HP/Damage via pcall (graceful fallback if FCMI API unavailable) |
| 245 | **Level 7+ Creatures XP Reduction** | BattleStarted tracks tier 7 presence; BattleEnded deducts 50% XP if loser had tier 7 |
| 45 | **Castle Town Income** | +250g/day per town with City Hall, +500g/day with Capitol (approx. Gold Reserve feature) |
| 248 | **Display WoGification Messages** | Shows list of active WOG features to human players on day 1 |
| 39 | **Hero Specialization Boost** | +1 primary skill at milestone levels (5/10/15/20/25/30) — now enabled |
| 132 | **Upgrading Treasure Chests** | Extra 500 gold or XP per chest visit via ObjectVisitStarted |
| 198 | **Rebalanced Hero Abilities** | Newly hired heroes get Wisdom/Offense/Armorer if their stat profile warrants it (via HeroHired engine event) |
| 196 | **Power Stones** | 4 collectible gem objects on map (+1 Attack/Defense/SpellPower/Knowledge each); uses ZCBON sprites from WOG Commanders |
| 199 | **Rebalanced Starting Armies** | Each hero gets +8 tier-1 faction creatures in slot 6 on day 1 (via InsertNewStack netpack + getFactionId) |
| Custom | **Building Construction Bonuses** | Gold + rare resources rewarded when building Mage Guild 5, Castle, Capitol |
| 230 | **Display Map Rules** | Shows active map-level rules (starting armies, income, buildings, chests) to human players on day 1 |
| 211 | **Scholar I — Enhanced Sharing** | JSON effects raise max spell-sharing level: Basic→3, Advanced→4, Expert→5 (was 2/3/4) |
| 142 | **Special Terrain Effects** | Magic Plains/Lucid Pools: +10% max mana/day; Evil Fog: -10% current mana/day; Holy Ground: mana bonus/drain based on faction; Rock Land: +50 XP/day |
| 143 | **New Artifacts** | 17 new WOG artifacts (Dragonheart, Crimson Shield, etc.) via wake-of-gods.artifacts dependency |
| 178 | **Combination Artifacts** | Assembled relic sets (Barbarian Lord's Axe = 4 components) via wake-of-gods.artifacts |
| ~~237~~ | ~~**Barbarian Lord's Axe**~~ | BANNED by user — artifact still exists in wake-of-gods.artifacts (cannot selectively remove without forking dependency). Will not appear on maps unless placed by map maker. |
| ~~227~~ | ~~**Monster's Power**~~ | BANNED by user — same limitation: exists in wake-of-gods.artifacts dependency but will not spawn randomly. |
| 243 | **Gate Key** | Gate Key map object via wake-of-gods.artifacts |
| 51 | **Enhanced Commanders** | Full Commander system (6 types, leveling, abilities) via wake-of-gods.Commanders |
| 186 | **Choose Commanders** | Select commander type from 6 options via wake-of-gods.Commanders |
| 66 | **Commander Witch Huts** | Commanders learn skills from Witch Huts via wake-of-gods.Commanders |
| 76 | **Commander Sanctuary** | Commander recovery/rest location via wake-of-gods.Commanders |
| 219 | **Commander Artifacts** | Full commander artifact equip system via wake-of-gods.Commanders |
| ~~176~~ | ~~**Magic Wand**~~ | BANNED by user — artifact exists in wake-of-gods.artifacts but will not spawn (not placed on maps). Level-8 creatures still load via level8Units dependency (user wants the creatures, just not the wand). |
| 173/174 | **Extended/Universal Creature Upgrades** | Alt paths: Santa Gremlin, Sylvan Centaur, War Zealot, hellSteed→Nightmare (Inferno), Dracolich (Necropolis) |
| 228 | **Build Twice a Day** | Towns can construct 2 buildings per day via game settings override in mod.json |
| 229 | **AI Stack Experience Level** | Stack experience enabled via wake-of-gods.stackExperience dependency (modules.stackExperience = true) |
| 134 | **Resource Piles** | Vanilla VCMI correctly implements H3 resource pile objects |
| 133 | **Upgraded Dwellings** | Starting towns receive upgraded creature dwellings on day 1 (via NewStructures netpack) |
| 200 | **Refugee Camp Sync** | All Refugee Camps synced to same creature weekly (SetAvailableCreatures + getDwellingCreatureId APIs) |
| 165 | **Replace Dragon Fly** | Dragon Fly/Fire Dragon Fly dwellings → Wyvern on day 1 (getCreatureIdByIdentifier + SetAvailableCreatures) |
| 242 | **Some Level 3s → Ghosts** | 1 in 3 tier-3 neutral dwellings replaced with WOG Ghost on day 1 |
| 195 | **Replace Objects** | WOG map objects available via wake-of-gods.mapObjects dependency |
| 52 | **Mirror of the Home-Way** | Works via wake-of-gods.mapObjects (configurable handler, townPortal spell at expert) |
| 75 | **Abbreviated Skill Descriptions** | All enhanced_skills.json descriptions shortened to compact 1-2 line format with actual WOG values |
| 244 | **Summon Elementals Script** | Already implemented in VCMI core — Summon Elementals spell works natively |
| 58 | **Espionage** | Adv. Scouting: weekly enemy hero count; Expert Scouting: enemy x,y positions (via InfoWindow) |
| 54 | **Enhanced War Machines I** | Ballista attacks twice at Basic (3× at Expert); First Aid heals 100/150/200 HP (was 50/75/100); Ammo Cart already unlimited in VCMI — all via JSON skill overrides in enhanced_skills.json |
| 70 | **Death Chamber** | Map object (wogDeathChamber) — hero visits to gain exactly 1 level; uses zobj007 sprite from wake-of-gods.mapObjects; configurable JSON object with heroLevel reward |

---

## 🟡 Partial — In Place But Needs More Work

| Option | Feature | Status |
|--------|---------|--------|
| 900 | **Stack Experience** | Hero-level approximation (wog_stack_experience.lua disabled); real engine module active via dependency |

---

## 🔴 Todo — Lua Scripting (Realistic, No Engine Changes Needed)

### Economy & Resources

| Option | Feature | Description |
|--------|---------|-------------|
| ~~45~~ | ~~**Castle Upgrading / Town Income**~~ | Done — moved to ✅ |
| ~~132~~ | ~~**Upgrading Treasure Chests**~~ | Done — moved to ✅ |
| ~~Custom~~ | ~~**Building Construction Bonuses**~~ | Done — moved to ✅ |
| ~~228~~ | ~~**Build Twice a Day**~~ | Done — mod.json "settings": {"towns": {"buildingsPerTurnCap": 2}} |

### Combat & Battle

| Option | Feature | Description |
|--------|---------|-------------|
| ~~61~~ | ~~**Enhanced Protection from Elements**~~ | Done — moved to ✅ |

### Hero & Skills

| Option | Feature | Description |
|--------|---------|-------------|
| ~~211~~ | ~~**Scholar I**~~ | Done — JSON effects added (Basic→level 3, Advanced→level 4, Expert→level 5 sharing) |
| ~~201~~ | ~~**Artillery I (Enhanced)**~~ | Done — moved to ✅ |
| ~~39~~ | ~~**Hero Specialization Boost**~~ | Done — moved to ✅ |
| ~~198~~ | ~~**Rebalanced Hero Abilities**~~ | Done — moved to ✅ |

### Creatures & Monsters

| Option | Feature | Description |
|--------|---------|-------------|
| ~~50~~ | ~~**Enhanced Monsters**~~ | Done — moved to ✅ |
| ~~57~~ | ~~**Neutral Units**~~ | Done — moved to ✅ |
| ~~231~~ | ~~**Neutral Stack Experience**~~ | Done — moved to ✅ |
| ~~165~~ | ~~**Replace Dragon Fly**~~ | Done — getDwellingCreatureId + SetAvailableCreatures: serpentFly/fireDragonFly dwellings → wyvern on day 1 |
| ~~242~~ | ~~**Some Level 3s → Ghosts**~~ | Done — replaces 1 in 3 tier-3 neutral dwellings with WOG Ghost on day 1 |
| ~~229~~ | ~~**AI Stack Experience Level**~~ | Done via dependency — wake-of-gods.stackExperience enables modules.stackExperience |

### Spells & Artifacts

| Option | Feature | Description |
|--------|---------|-------------|
| ~~26~~ | ~~**Artificer**~~ | Done — map object "wogArtificer" (sprite zobj012) upgrades one equipped artifact per visit; up to 2/day, second costs 2×. Auto-selects most-expensive affordable artifact. Gold costs from ERM script26 table. (Interactive selection and Mithril cost deferred.) |
| ~~143~~ | ~~**New Artifacts**~~ | Done via dependency — moved to ✅ |
| ~~176~~ | ~~**Magic Wand**~~ | Done via dependency — wake-of-gods.level8Units defines Magic Wand (upgrades tier-7 creatures to level-8) |
| ~~178~~ | ~~**Combination Artifacts**~~ | Done via dependency — moved to ✅ |
| ~~196~~ | ~~**Power Stones**~~ | Done — moved to ✅ |
| ~~237~~ | ~~**Barbarian Lord's Axe**~~ | Done via dependency — moved to ✅ |
| ~~227~~ | ~~**Monster's Power**~~ | Done via dependency — moved to ✅ |
| ~~243~~ | ~~**Gate Key**~~ | Done via dependency — moved to ✅ |

### Map Rules

| Option | Feature | Description |
|--------|---------|-------------|
| ~~133~~ | ~~**Upgraded Dwellings**~~ | Done — NewStructures netpack adds upgraded dwellings to starting towns on day 1 |
| ~~135~~ | ~~**Wandering Monsters**~~ | Done — ChangeObjPos: monsters move 1-2 tiles/week; moved to ✅ |
| ~~170~~ | ~~**Mithril in Resource Stacks**~~ | Done — wog_mithril_accumulation.lua marks 1 in 15 piles on day 1; visiting gives bonus Mithril |
| ~~171~~ | ~~**Mithril in Windmills/Gardens**~~ | Done — wog_mithril_accumulation.lua marks 1 in 10 windmills/water wheels weekly; visiting gives bonus Mithril |
| ~~134~~ | ~~**Resource Piles**~~ | Done — vanilla VCMI already implements H3 resource piles correctly |
| ~~174~~ | ~~**Universal Upgrading**~~ | Done — hellSteed/Nightmare (Inferno alt) + Dracolich (Necropolis alt) added via creature patch |
| ~~199~~ | ~~**Rebalanced Starting Armies**~~ | Done — moved to ✅ |
| ~~195~~ | ~~**Replace Objects**~~ | Done via dependency — wake-of-gods.mapObjects adds arcaneTower, junkMerchant, mushrooms, sphinx, fountains, etc. |
| ~~200~~ | ~~**Refugee Camp Sync**~~ | Done — SetAvailableCreatures + getDwellingCreatureId FCMI APIs; weekly sync of all camps |
| ~~142~~ | ~~**Special Terrain**~~ | Done — moved to ✅ |

### Commanders

| Option | Feature | Description |
|--------|---------|-------------|
| ~~51~~ | ~~**Enhanced Commanders**~~ | Done via dependency — moved to ✅ |
| ~~186~~ | ~~**Choose Commanders**~~ | Done via dependency — moved to ✅ |
| ~~66~~ | ~~**Commander Witch Huts**~~ | Done via dependency — moved to ✅ |
| ~~76~~ | ~~**Commander Sanctuary**~~ | Done via dependency — moved to ✅ |
| ~~219~~ | ~~**Commander Artifacts**~~ | Done via dependency — moved to ✅ |

### Quality of Life

| Option | Feature | Description |
|--------|---------|-------------|
| 22 | **Monster Mutterings** | Blocked — requires client-side tooltip/hover UI hook; server-side Lua only |
| 24 | **Enhanced Hint Text** | Blocked — requires client-side UI, not achievable via server Lua scripting |
| ~~75~~ | ~~**Abbreviated Skill Descriptions**~~ | Done — all enhanced_skills.json descriptions shortened to compact 1-2 line format |
| ~~248~~ | ~~**Display WoGification Messages**~~ | Done — moved to ✅ |
| ~~230~~ | ~~**Display Map Rules**~~ | Done — moved to ✅ |

---

## 🏗️ Hard — Needs Engine Changes First

| Option | Feature | Why It's Hard |
|--------|---------|--------------:|
| ~~54~~ | ~~**Enhanced War Machines I**~~ | Done — JSON skill overrides; ballista attacks 2× (Basic) or 3× (Expert); first aid heals doubled |
| 36 | **Mithril Enhancements** | Needs 8th resource type in engine |
| 149 | **Mithril Display** | Depends on Mithril resource |
| ~~52~~ | ~~**Mirror of the Home-Way**~~ | Done via dependency — wake-of-gods.mapObjects implements it via configurable handler + townPortal spell cast |
| ~~58~~ | ~~**Espionage**~~ | Done — Adv. Scouting: weekly enemy hero count; Expert: x,y positions (wog_espionage.lua) |
| ~~70~~ | ~~**Death Chamber**~~ | Done — configurable map object (wogDeathChamber) gives exactly 1 level on visit; uses zobj007 sprite |
| ~~244~~ | ~~**Summon Elementals Script**~~ | Done — VCMI core already implements Summon Elementals spell natively |
| 192 | **Transfer Owner** | SetObjectProperty/GiveHero APIs now available; needs map scripting trigger to be useful |

---

## ⚫ Map Object Features

| Option | Feature | Object Type |
|--------|---------|------------|
| 6 | **Hourglass of Asmodeus** | Special hero on map |
| 7 | **Fishing Well** | Special well object |
| 8 / 108 | **Junk Merchant** | Shop object on map |
| 10 | **Magic Mushrooms** | Map objects with random bonuses |
| 16 | **Battle Academy** | Buy skills for gold |
| 28 / 185 | **School of Wizardry** | Purchase spells |
| 43 | **Obelisk Runes** | Obelisks with spell bonuses |
| 44 | **Emerald Tower** | Tower with special rewards |
| 65 | **Monolith Toll** | Two-way monoliths cost resources |
| 69 | **Custom Alliances** | Alliance system via map event |
| 104 | **Arcane Tower** | Tower with magic bonuses |
| 105 | **Loan Bank** | Borrow gold |
| 109 | **Market of Time** | Forget skills for 2000 gold |
| 5 | **Banks + Resource Trading Post** | Transfer resources button |

---

## ❓ Resolved "Unknown" Options

| Option | Resolution |
|--------|-----------|
| 113 | UI section label for Custom Scripts page 7 (not a feature) |
| 116 | UI section label for Custom Scripts page 7 |
| 118 | UI section label for Custom Scripts page 7 |
| 122-127 | UI section labels for Custom Scripts pages (not individual features) |
| 183 | Mysticism Enhancement Script (sub-option of 35) |
| 187 | Spellbook Script (sub-option of 27) |
| 180 | Living Scrolls Script (sub-option of 33 — map object) |
| 182 | Cards of Prophecy Script (sub-option of 34) |
| 239 | Unknown sub-option |
| 902 | Artifacts may be left by right-clicking (hard-coded WOG feature) |

---

---

## 🔍 ERM Source Audit — New Gaps Found (March 2026)

Cross-referenced all ERM scripts with user screenshots (March 17). From reading the actual .erm files:

| Script | Option | Feature | ERM Description | Status |
|--------|--------|---------|-----------------|--------|
| script19 | 19 | **Masters of Life** | Daily: upgrades peasants + tier-1 creatures in hero armies to their upgraded form. Skips Necromancers. Uses HE:C (ChangeCreatureType). | 🔴 Todo — implementable with SetStackType FCMI API |
| script27 | 27 | **Spellbook (Enhanced)** | Spellbooks picked up from map come pre-loaded with spells. Level/quantity depends on hero's Wisdom + Luck. ERM: OB5/0 trigger (artifact pickup). | 🔴 Todo — needs ObjectVisitStarted + giveSpell API |
| script31 | 31 | **Treasure Chest 2** | Special 5th chest type: gold+scroll, Tomes of Knowledge, or deed to an unowned mine. Tomes raise a skill to Expert after 1 week. | ⚫ Map object — requires the specific chest type placed by map maker |
| script33 | 33 | **Living Scrolls** | Equipped spell scrolls have 20% chance each combat round to auto-cast their spell (Basic level). Excludes adventure/elemental/clone/armageddon spells. | 🏗️ Hard — requires BattleRoundStarted event + spell casting API |
| script25 opt17 | — | **Extension Heroes (9th-10th Skills)** | Heroes can gain more than 8 secondary skills (9 or 10 slots). Needs game setting override. | 🏗️ Hard — requires engine investigation (hero.maxSkills setting?) |
| script02 | 02 | **Artifact Boost** | Once/week timer: specific "weak" artifacts gain special per-hero effects (e.g., Bird of Perception gives 6 Royal Griffins). Complex per-artifact logic. | 🔴 Todo — implementable but extensive (14+ artifact cases) |

### Confirmed "Mines change resources once per week" = script20 resource weeks ✅
Already implemented in wog_week_of_monsters.lua (10% weekly chance of resource week → double mine output for that resource).

### Confirmed User-Disabled Options (removed from implementation)
| Option | Feature | Action Taken |
|--------|---------|-------------|
| 220 | Battle Extender | Removed from mod.json scripts |
| 210 | Resistance I/II Enhancement | Removed core:resistance from enhanced_skills.json |
| 212 | Scouting I/II Enhancement | Removed core:scouting from enhanced_skills.json |
| 176 | Magic Wand | Removed wake-of-gods.level8Units dependency |

---

## Summary Count

| Status | Count |
|--------|-------|
| ✅ Done | 82 |
| 🟡 Partial | 1 |
| ⛔ Blocked (client-side only) | 2 |
| 🏗️ Hard (needs engine) | 4 |
| ⚫ Map objects | 14 |
| ❓ Resolved unknowns | 10 |
| **Total enabled** | **~130** |
