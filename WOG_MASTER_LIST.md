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
| 39 | **Hero Specialization Boost** | +1 primary skill at milestone levels (5/10/15/20/25/30) |
| 220 | **Battle Extender** | 1000 gold refund to losing human player; full retreat pending |
| 47 | **Creature Relationships** | 5% synergy XP bonus post-battle; morale/attack pending |
| 900 | **Stack Experience (approx.)** | Army XP tracked; +1 primary stat per 5000 XP milestone |
| 71 | **Enhanced Artifacts** | Conjuring set adds spell damage; Pendant of Death gives undead +5 ATT/DEF |

---

## 🟡 Partial — In Place But Needs More Work

| Option | Feature | Status |
|--------|---------|--------|
| 47 | **Creature Relationships** | Synergy XP; need BattleStart for morale/attack/hate effects |
| 220 | **Battle Extender** | Gold refund; need retreat intercept for true rejoin mechanic |
| 900 | **Stack Experience** | Hero-level approximation; need per-stack tracking + creature stat API |
| 20 | **Week of Monsters** | Picks creature each week; need EntitiesChanged for stat boost |
| 39 | **Hero Specialization Boost** | Milestone primary skill boost; true specialty scaling needs hero type API |

---

## 🔴 Todo — Lua Scripting (Realistic, No Engine Changes Needed)

### Economy & Resources

| Option | Feature | Description |
|--------|---------|-------------|
| 45 | **Castle Upgrading / Town Income** | Build Gold Reserve upgrades for +1000 gold/day each |
| 228 | **Build Twice a Day** | Towns can build two buildings per day |

### Combat & Battle

| Option | Feature | Description |
|--------|---------|-------------|
| 61 | **Enhanced Protection from Elements** | Protection spells vs. elementals have stronger effects |
| 245 | **Level 7+ Creatures Gain 50% XP** | Tier 7 creatures earn half experience; needs army composition API |

### Hero & Skills

| Option | Feature | Description |
|--------|---------|-------------|
| 211 | **Scholar I** | Share better spells (partially done via Scholar weekly research) |
| 201 | **Artillery I (Enhanced)** | Stronger Ballista bonuses |
| 198 | **Rebalanced Hero Abilities** | Starting skills rebalanced |
| 194 | **Advanced Witch Huts** | Can learn higher skills; pay to upgrade |

### Creatures & Monsters

| Option | Feature | Description |
|--------|---------|-------------|
| 50 | **Enhanced Monsters** | Wandering monsters have enhanced behaviors |
| 57 | **Neutral Units** | Controls neutral stack sizes |
| 231 | **Neutral Stack Experience** | Non-hero creature stacks also gain experience |
| 165 | **Replace Dragon Fly** | Dragon Flies replaced |
| 242 | **Some Level 3s → Ghosts** | Some level 3 spawns replaced by Ghosts |
| 229 | **AI Stack Experience Level** | AI difficulty level 7 |

### Spells & Artifacts

| Option | Feature | Description |
|--------|---------|-------------|
| 26 | **Artificer** | Combine or upgrade artifacts |
| 143 | **New Artifacts** | New WOG-specific artifacts |
| 176 | **Magic Wand** | New artifact that extends spell effects |
| 178 | **Combination Artifacts** | Assembled artifact sets |
| 196 | **Power Stones** | Collectible stones boosting primary skills |
| 237 | **Barbarian Lord's Axe** | New weapon artifact |
| 227 | **Monster's Power** | Artifact scaling with army strength |
| 243 | **Gate Key** | New artifact for controlling passage |

### Map Rules

| Option | Feature | Description |
|--------|---------|-------------|
| 133 | **Upgraded Dwellings** | Start with upgraded creatures |
| 135 | **Wandering Monsters** | Moving monster groups on map |
| 170 | **Mithril in Resource Stacks** | 1 in 15 piles contains Mithril |
| 171 | **Mithril in Windmills/Gardens** | 1 in 10 windmills have Mithril |
| 134 | **Resource Piles** | Resource piles work normally |
| 174 | **Universal Upgrading** | All creatures upgradeable |
| 199 | **Rebalanced Starting Armies** | Fairer starting armies |
| 195 | **Replace Objects** | WOG alternative map objects |
| 200 | **Refugee Camp Sync** | Consistent creature types across players |
| 132 | **Upgrading Treasure Chests** | Better chest rewards |
| 142 | **Special Terrain** | Enhanced terrain effects |

### Commanders

| Option | Feature | Description |
|--------|---------|-------------|
| 51 | **Enhanced Commanders** | Expanded abilities and leveling |
| 186 | **Choose Commanders** | Choose commander type |
| 66 | **Commander Witch Huts** | Learn skills from Witch Huts |
| 76 | **Commander Sanctuary** | Recovery location |
| 219 | **Commander Artifacts** | Equip artifacts |

### Quality of Life

| Option | Feature | Description |
|--------|---------|-------------|
| 22 | **Monster Mutterings** | Hovering shows creature thoughts |
| 24 | **Enhanced Hint Text** | Better hover descriptions |
| 75 | **Abbreviated Skill Descriptions** | Shorter skill tooltips |
| 248 | **Display WoGification Messages** | Shows active WOG features |
| 230 | **Display Map Rules** | Shows active map rules |

---

## 🏗️ Hard — Needs Engine Changes First

| Option | Feature | Why It's Hard |
|--------|---------|--------------:|
| 54 | **Enhanced War Machines I** | Needs battle creature manipulation API |
| 36 | **Mithril Enhancements** | Needs 8th resource type in engine |
| 149 | **Mithril Display** | Depends on Mithril resource |
| 52 | **Mirror of the Home-Way** | Complex teleport mechanic |
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
| ✅ Done | 24 |
| 🟡 Partial | 5 |
| 🔴 Todo (Lua, doable) | ~41 |
| 🏗️ Hard (needs engine) | 8 |
| ⚫ Map objects | 14 |
| ❓ Resolved unknowns | 10 |
| **Total enabled** | **~130** |
