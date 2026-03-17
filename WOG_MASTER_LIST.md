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
| 173 | **Extended Creature Upgrades** | Alt upgrade paths (Santa Gremlins, Sylvan Centaurs, War Zealots) |
| Custom | **Combat Hardening** | +20% XP after every won battle (our custom feature) |
| Custom | **Daily Gold Bonus** | 100 gold/day per human player (placeholder for full income system) |

---

## 🔴 Todo — Lua Scripting (Realistic, No Engine Changes Needed)

These can be done with what the FCMI engine already supports.

### Economy & Resources

| Option | Feature | Description |
|--------|---------|-------------|
| 40 | **First Money** | Hero starts with bonus gold on day 1 |
| 45 | **Castle Upgrading / Town Income** | Build Gold Reserve upgrades in towns for +1000 gold/day each (costs 7000 gold + 2 Mithril) |
| 20 | **Week of Monsters** | Each week a random creature type gets a bonus (double growth, increased stats, etc.) |
| 228 | **Build Twice a Day** | Towns can build two buildings per day instead of one |

### Combat & Battle

| Option | Feature | Description |
|--------|---------|-------------|
| 38 | **Karmic Battles** | In battle, equal-sized armies fight more fairly — reduces "first strike wins" randomness |
| 47 | **Creature Relationships** | Some creatures have bonus/penalty based on army composition (e.g., angels vs. devils) |
| 61 | **Enhanced Protection from Elements** | Protection spells vs. elemental creatures have stronger effects |
| 220 | **Battle Extender** | Allows retreating hero to rejoin battle under certain conditions |
| 245 | **Level 7+ Creatures Gain 50% XP** | Tier 7 creatures earn half experience from battles |

### Hero & Skills

| Option | Feature | Description |
|--------|---------|-------------|
| 23 | **Sorcery Enhancement I** | Sorcery skill gives even bigger spell damage bonus (stacks with base) |
| 35 | **Mysticism Enhancement I** | Hero regenerates more spell points per day |
| 207 | **Mysticism II** | Further increases daily spell point recovery |
| 103 | **Eagle Eye II** | Higher chance to learn spells from enemy use; can learn higher-circle spells |
| 202 | **Eagle Eye I** | Slightly improved Eagle Eye skill |
| 203 | **Estates I** | Estates skill generates more daily gold |
| 191 | **Estates II (Enhanced)** | Further enhances Estates daily income |
| 204 | **First Aid I (Enhanced)** | First Aid Tent heals more HP per turn |
| 190 | **First Aid Enhanced** | Additional First Aid Tent enhancements |
| 205 | **Learning II** | Hero gains significantly more XP from all sources |
| 217 | **Learning I** | Hero gains slightly more XP |
| 206 | **Luck I** | Luck skill gives bigger damage boost on lucky strikes |
| 208 | **Navigation I** | Navigation skill gives more movement over water |
| 209 | **Pathfinding I** | Pathfinding skill reduces terrain movement penalty more |
| 210 | **Resistance II** | Resistance skill grants stronger magic resistance |
| 211 | **Scholar I** | Scholar skill teaches better spells when sharing |
| 212 | **Scouting II** | Scouting skill reveals more map area |
| 213 | **Sorcery II** | Sorcery skill further boosts spell damage |
| 214 | **Armorer I** | Armorer skill reduces physical damage taken more |
| 218 | **Tactics I** | Tactics skill gives more pre-battle movement rows |
| 201 | **Artillery I (Enhanced)** | Artillery skill gives even stronger Ballista bonuses |
| 39 | **Hero Specialization Boost** | Heroes' specialty bonuses scale better with hero level |
| 198 | **Rebalanced Hero Abilities** | Hero starting skills and abilities rebalanced for fairness |
| 194 | **Advanced Witch Huts** | Witch Huts can offer more advanced skills; pay gold to go from Basic to Advanced |

### Creatures & Monsters

| Option | Feature | Description |
|--------|---------|-------------|
| 50 | **Enhanced Monsters** | Wandering monsters on the map have enhanced abilities and behaviors |
| 57 | **Neutral Units** | Controls neutral stack sizes and aggressiveness settings |
| 231 | **Neutral Stack Experience** | Neutral (non-hero-owned) creature stacks also gain experience |
| 165 | **Replace Dragon Fly** | Dragon Flies replaced with a different creature |
| 242 | **Some Level 3s → Ghosts** | Some level 3 creature spawns are replaced by Ghost stacks |
| 900 | **Stack Experience** | All creature stacks gain experience from battles and rank up (0–10 ranks) |
| 229 (=7) | **AI Stack Experience Level** | Value of 7 = how aggressively AI creatures gain experience |

### Spells & Artifacts

| Option | Feature | Description |
|--------|---------|-------------|
| 26 | **Artificer** | Heroes can combine or upgrade artifacts |
| 71 | **Enhanced Artifacts** | Existing artifacts have improved or expanded effects |
| 143 | **New Artifacts** | Adds new WOG-specific artifacts to the game |
| 176 | **Magic Wand** | New artifact that extends spell effects |
| 178 | **Combination Artifacts** | Artifact sets can be assembled into powerful combined pieces |
| 196 | **Power Stones** | Collectible stones that permanently boost hero primary skills |
| 237 | **Barbarian Lord's Axe** | Specific new artifact added to the game |
| 227 | **Monster's Power** | Artifact that scales with army strength |
| 243 | **Gate Key** | New artifact for controlling passage |

### Map Rules

| Option | Feature | Description |
|--------|---------|-------------|
| 133 | **Upgraded Dwellings** | Some creature dwellings on map start with upgraded creatures available |
| 135 | **Wandering Monsters** | Enables wandering (moving) monster groups on the map |
| 170 | **Mithril in Resource Stacks** | 1 in 15 resource piles contains Mithril instead |
| 171 | **Mithril in Windmills/Gardens** | 1 in 10 windmills/mystical gardens contain Mithril |
| 134 | **Resource Piles** | Resource pile objects on map function normally |
| 174 | **Universal Upgrading** | All creatures can be upgraded regardless of dwelling type |
| 199 | **Rebalanced Starting Armies** | Heroes start with more balanced/fair armies |
| 195 | **Replace Objects** | Certain map objects replaced with WOG alternatives |
| 200 | **Refugee Camp Sync** | Refugee camps offer consistent creature types across players |
| 132 | **Upgrading Treasure Chests** | Treasure chests can be upgraded for better rewards |
| 142 | **Special Terrain** | Special terrain types (Magic Plains, Holy Ground, etc.) have enhanced effects |

### Commanders

| Option | Feature | Description |
|--------|---------|-------------|
| 51 | **Enhanced Commanders** | Commanders have expanded abilities, skills, and leveling |
| 186 | **Choose Commanders** | Player can choose commander type rather than random assignment |
| 66 | **Commander Witch Huts** | Commanders can learn skills from Witch Huts |
| 76 | **Commander Sanctuary** | Special location where commanders can recover |
| 219 | **Commander Artifacts** | Commanders can equip artifacts |

### Quality of Life

| Option | Feature | Description |
|--------|---------|-------------|
| 22 | **Monster Mutterings** | Hovering over enemy creatures shows their "thoughts" (flavor text) |
| 24 | **Enhanced Hint Text** | Better hover descriptions for map objects |
| 75 | **Abbreviated Skill Descriptions** | Shorter, cleaner secondary skill tooltip text |
| 248 | **Display WoGification Messages** | Shows messages at game start listing which WOG features are active |
| 230 | **Display Map Rules** | Shows which map rules are active at game start |

---

## 🏗️ Hard — Needs Engine Changes First

These require C++ engine work before Lua scripts can implement them.

| Option | Feature | Why It's Hard |
|--------|---------|--------------|
| 54 | **Enhanced War Machines I** | Needs battle creature manipulation API (change creature type mid-battle, track machine XP) |
| 36 | **Mithril Enhancements** | Needs 8th resource type in engine |
| 149 | **Mithril Display** | Depends on Mithril resource existing |
| 52 | **Mirror of the Home-Way** | Complex teleport mechanic for heroes |
| 58 | **Espionage** | Hero scouting/intel system |
| 70 | **Death Chamber** | Special hero leveling mechanic |
| 244 | **Summon Elementals Script** | New battle spell effects |
| 192 | **Transfer Owner** | Transfer towns/heroes/mines between players mid-game |

---

## ⚫ Map Object Features

These only work on maps that have the specific objects placed. They're not automatic for all games. You'd need maps made for WOG or to place these objects manually in the map editor.

| Option | Feature | Object Type |
|--------|---------|------------|
| 6 | **Hourglass of Asmodeus** | Special hero that appears on map |
| 7 | **Fishing Well** | Special well object |
| 8 / 108 | **Junk Merchant** | Shop object on map |
| 10 | **Magic Mushrooms** | Map objects that give random bonuses |
| 16 | **Battle Academy** | Academy building — buy skills/primary stats for gold |
| 28 / 185 | **School of Wizardry** | Building where spells can be purchased |
| 43 | **Obelisk Runes** | Enhanced obelisks that give bonuses |
| 44 | **Emerald Tower** | Tower object with special rewards |
| 65 | **Monolith Toll** | Two-way monoliths cost resources to use |
| 69 | **Custom Alliances** | Player alliance system via map event |
| 104 | **Arcane Tower** | Special tower with magic bonuses |
| 105 | **Loan Bank** | Building where gold can be borrowed |
| 109 | **Market of Time** | Building where skills can be forgotten for 2000 gold |
| 5 | **Banks + Resource Trading Post** | Transfer all resources button, trading post buildings |

---

## ❓ Unknown Options

These were enabled in your setup but I couldn't definitively identify them. Need your help.

| Option | Possible Match | Your Input |
|--------|---------------|-----------|
| 113 | ? | |
| 116 | ? | |
| 118 | ? | |
| 122 | ? | |
| 123 | ? | |
| 124 | ? | |
| 126 | ? | |
| 127 | ? | |
| 183 | Mysticism Enhancement Script (sub-option of 35?) | |
| 187 | Spellbook Script (sub-option of 27?) | |
| 180 | Living Scrolls Script (sub-option of 33?) | |
| 182 | Cards of Prophecy Script (sub-option of 34?) | |
| 239 | ? | |
| 902 | Stack Experience (sub-option of 900?) | |

---

## Summary Count

| Status | Count |
|--------|-------|
| ✅ Done | 4 |
| 🔴 Todo (Lua, doable) | ~55 |
| 🏗️ Hard (needs engine) | 8 |
| ⚫ Map objects (need maps) | 14 |
| ❓ Unknown | 14 |
| **Total enabled** | **~130** |
