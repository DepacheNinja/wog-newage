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
| 40 | **First Money** | Each player receives 5000 gold on day 1 |
| 38 | **Karmic Battles** | Close battles: winner +5% XP, loser +10% consolation XP |
| 203/191 | **Estates Enhancement** | Extra gold per day = heroLevel × multiplier |
| 35/207 | **Mysticism Enhancement** | +2/3/5 extra SP/day at basic/adv/expert on top of base |
| 205/217 | **Learning Enhancement** | Passive 100/200/300 XP/day per skill level |
| 211 | **Scholar Enhancement** | Weekly 40%/50%/60% chance to research new spell (level 1-4) |
| 23/213 | **Sorcery Enhancement** | Spell damage: 10/20/30% (was 5/10/15%) via JSON |
| 214 | **Armorer Enhancement** | Damage reduction: 10/15/20% (was 5/10/15%) via JSON |
| 210 | **Resistance Enhancement** | Magic resist: 10/20/30% (was 5/10/20%) via JSON |
| 208 | **Navigation Enhancement** | Water movement: 60/110/165% (was 50/100/150%) via JSON |
| 209 | **Pathfinding Enhancement** | Terrain penalty: 35/60/75% reduction via JSON |
| 103/202 | **Eagle Eye Enhancement** | Chance 50/65/80% (was 40/50/60%), learns up to level 3/4/5 (was 2/3/4) via JSON |
| 212 | **Scouting Enhancement** | Sight radius 2/3/5 (was 1/2/3) via JSON |
| 218 | **Tactics Enhancement** | Deployment zone +1 row per level via JSON |
| 206 | **Luck I Enhancement** | Lucky strikes deal +50% initial damage extra (total ~3× normal) via ApplyDamage |
| 201 | **Artillery I Enhanced** | Ballista double-damage hits: +25/50/75% extra per skill level via ApplyDamage |
| 194 | **Advanced Witch Huts** | Witch Huts teach at Advanced level; deducts 1000g from player |
| 39 | **Hero Specialization Boost** | +1 primary skill at milestone levels (5/10/15/20/25/30) |
| 220 | **Battle Extender** | 1000 gold refund to losing human player; full retreat pending |
| 47 | **Creature Relationships** | 5% synergy XP bonus post-battle; morale/attack pending |
| 900 | **Stack Experience (approx.)** | Army XP tracked; +1 primary stat per 5000 XP milestone |
| 71 | **Enhanced Artifacts** | Conjuring set adds spell damage; Pendant of Death gives undead +5 ATT/DEF |
| 20 | **Week of Monsters** | +2 ATK/+2 DEF/+1 growth via EntitiesChanged; creature type updateFrom now works (engine fix); announces WOM creature each week |
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
| 237 | **Barbarian Lord's Axe** | Extra strike for non-shooters; relic combo of 4 artifacts via wake-of-gods.artifacts |
| 227 | **Monster's Power** | Prayer cast on creatures by terrain/alignment via wake-of-gods.artifacts |
| 243 | **Gate Key** | Gate Key map object via wake-of-gods.artifacts |
| 51 | **Enhanced Commanders** | Full Commander system (6 types, leveling, abilities) via wake-of-gods.Commanders |
| 186 | **Choose Commanders** | Select commander type from 6 options via wake-of-gods.Commanders |
| 66 | **Commander Witch Huts** | Commanders learn skills from Witch Huts via wake-of-gods.Commanders |
| 76 | **Commander Sanctuary** | Commander recovery/rest location via wake-of-gods.Commanders |
| 219 | **Commander Artifacts** | Full commander artifact equip system via wake-of-gods.Commanders |
| 176 | **Magic Wand** | Upgrades tier-7 creatures to level-8 (supremeArchangel, diamondDragon, etc.) via wake-of-gods.level8Units dependency |
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

---

## 🟡 Partial — In Place But Needs More Work

| Option | Feature | Status |
|--------|---------|--------|
| 47 | **Creature Relationships** | Allied pair XP done; hate pair +15% damage via ApplyDamage getAttacker/getCreatureId; morale/luck pending (needs bonus API) |
| 61 | **Enhanced Protection from Elements** | Protection spells (protectFire/Air/Water/Earth) now reduce physical elemental attacks by 35% via ApplyDamage + hasBonusFromSpell() FCMI API |
| 57 | **Neutral Units** | Wandering monster stacks scaled ×1.5 on day 1 via getMapObjectIds(54)/getMonsterCount/ChangeStackCount FCMI APIs |
| 50 | **Enhanced Monsters** | Surviving neutral stacks grow +10%/week (capped at 3× day-1 count) via weekly TurnStarted + ChangeStackCount |
| 231 | **Neutral Stack Experience** | Neutral stacks that defeat a hero grow +20% (stack count proxy for XP) via BattleStarted/BattleEnded + getAttackerArmyId/getDefenderArmyId FCMI APIs |
| 220 | **Battle Extender** | Gold refund; need retreat intercept for true rejoin mechanic |
| 900 | **Stack Experience** | Hero-level approximation; need per-stack tracking + creature stat API |
| 39 | **Hero Specialization Boost** | Milestone primary skill boost; true specialty scaling needs hero type API |

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
| 26 | **Artificer** | Combine or upgrade artifacts (complex UI mechanic, not yet impl.) |
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
| 135 | **Wandering Monsters** | Moving monster groups on map |
| 170 | **Mithril in Resource Stacks** | 1 in 15 piles contains Mithril |
| 171 | **Mithril in Windmills/Gardens** | 1 in 10 windmills have Mithril |
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
| 22 | **Monster Mutterings** | Hovering shows creature thoughts |
| 24 | **Enhanced Hint Text** | Better hover descriptions |
| 75 | **Abbreviated Skill Descriptions** | Shorter skill tooltips |
| ~~248~~ | ~~**Display WoGification Messages**~~ | Done — moved to ✅ |
| ~~230~~ | ~~**Display Map Rules**~~ | Done — moved to ✅ |

---

## 🏗️ Hard — Needs Engine Changes First

| Option | Feature | Why It's Hard |
|--------|---------|--------------:|
| 54 | **Enhanced War Machines I** | Needs battle creature manipulation API |
| 36 | **Mithril Enhancements** | Needs 8th resource type in engine |
| 149 | **Mithril Display** | Depends on Mithril resource |
| ~~52~~ | ~~**Mirror of the Home-Way**~~ | Done via dependency — wake-of-gods.mapObjects implements it via configurable handler + townPortal spell cast |
| 58 | **Espionage** | Hero scouting/intel system |
| 70 | **Death Chamber** | Special hero leveling |
| 244 | **Summon Elementals Script** | New battle spell effects |
| 192 | **Transfer Owner** | Transfer towns/heroes/mines mid-game |

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

## Summary Count

| Status | Count |
|--------|-------|
| ✅ Done | 73 |
| 🟡 Partial | 4 |
| 🔴 Todo (Lua, doable) | ~6 |
| 🏗️ Hard (needs engine) | 8 |
| ⚫ Map objects | 14 |
| ❓ Resolved unknowns | 10 |
| **Total enabled** | **~130** |
