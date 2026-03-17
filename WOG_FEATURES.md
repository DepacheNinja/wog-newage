# WOG New Age — Complete Feature Reference

**Mod:** WOG New Age (`wog-newage`)
**Engine:** FCMI fork of VCMI (`DepacheNinja/fcmi`, branch `develop`)
**Author:** Depache
**Source:** Decoded from WoGSetupEx04222024.dat + classic WOG 3.58f ERM scripts + WoG Features.htm

---

## Status Legend

| Symbol | Meaning |
|--------|---------|
| ✅ | Working in mod now |
| 🔴 | Planned — Lua scripting, no engine changes needed |
| 🏗️ | Needs C++ engine changes first |
| ⚫ | Map object — only works on maps with that object placed |
| ❓ | Unknown / unidentified |

---

## Currently Implemented ✅

### Combined Warfare Skills
**Option:** 193 | **Script:** `scripts/wog_combined_warfare_skills.lua` | **Classic:** `script64.erm` by Tobyn

Three secondary skills — **Ballistics** (ID 10), **Artillery** (ID 20), **First Aid** (ID 27) — are permanently linked as one combined "Warfare" skill.

- Learning or leveling **any one** at hero level-up automatically raises all three to the same level
- Skills only sync upward — a higher skill is never reduced
- Classic WOG also linked them at Witch Huts and Market of Time (forgetting one forgot all three)
- For 9th/10th skill counting: the three count as **one slot** (script01.erm lines 641–643)
- Right-clicking any of the three in the hero screen shows all three effects in the tooltip

**Skill level values:** None=0, Basic=1, Advanced=2, Expert=3

---

### Combat Hardening (Bonus Battle XP)
**Option:** Custom (not classic WOG) | **Script:** `scripts/wog_battle_academy.lua`

After every won battle, the winning hero receives **+20% of the battle XP** as a bonus.

- Does not fire on draws or when there is no hero on the winning side
- Config: `DATA.WOG.battleAcademyBonusPct = 20`

> Note: Classic WOG Script #16 "Battle Academy" is a map object where heroes buy skills/stats for gold — not a battle XP bonus. This is a custom WOG New Age feature.

---

### Daily Gold Income
**Option:** 45 (placeholder) | **Script:** `scripts/wog_weekly_income.lua`

Every day, each human player receives **100 gold** as a flat income bonus.

- Config: `DATA.WOG.dailyGoldBonus = 100`
- Fires on `PlayerGotTurn` every day; AI players excluded
- **This is a simplified placeholder.** The real system (Castle Upgrading) is listed below under 🏗️.

---

### Alternate Creature Upgrades
**Option:** 173 | **Config:** `config/creatures/altUpgradesCreaturePatch.json`

Adds alternate upgrade paths for select creatures:
- **Santa Gremlins** — alternate upgrade for Gremlins (Tower)
- **Sylvan Centaurs** — alternate upgrade (Rampart)
- **War Zealots** — alternate upgrade (Castle/Stronghold)

Pure JSON data, no scripting required.

---

### Warfare Skill Tooltips
**Config:** `config/skills/warfare_skills.json`

Right-clicking any of the three Warfare skills (Ballistics, Artillery, First Aid) in the hero screen shows all three skills' effects at that level, plus the note that they are permanently linked.

---

---

## Economy & Resources 🔴

### Castle Upgrading / Town Income (option 45)
**Classic:** `script45.erm` by Alexis Koz
**Priority: High** — the core economic feature of WOG

Towns can be upgraded with a **Gold Reserve** building that generates permanent daily income. Also, creature dwellings can be upgraded to produce more growth each week.

**Gold Reserve:**
- Cost per upgrade: **7,000 gold + 2 Mithril**
- Bonus: **+1,000 gold/day** per upgrade, per town
- Can be built multiple times per town (once per day)
- Requires City Hall or Capitol to be built
- AI builds one dwelling upgrade per week automatically

**Creature Dwelling Upgrades:**
Costs vary by creature type and tier. Each upgrade increases weekly growth for that dwelling. Example costs from `script45.erm`:
| Tier | Example Creature | Cost |
|------|-----------------|------|
| 1 | Pikeman | 7 wood + 1000 gold |
| 7 | Angel | 10 ore + 10 crystal + 10 gem + 6000 gold |

**Blocker:** Requires Mithril resource (see 🏗️ section). Current flat daily bonus is the placeholder.

---

### First Money (option 40)
**Classic:** `script40.erm`

Each hero starts with a bonus amount of gold on day 1 of the game. Helps offset early-game economy.

---

### Build Twice a Day (option 228)
**Classic:** `script45.erm` sub-option

Towns can construct two buildings per day instead of the standard one. Speeds up town development.

---

---

## Hero Skills & Specialization 🔴

### Enhanced Secondary Skills (options 201–214, 217–218)
**Classic:** `script48.erm` (by Arstahd) + `script37.erm` (Rebalanced Factions)

Each skill gets a buffed effect at all three levels. These are pure JSON skill overrides — same format as the Warfare tooltips we already added.

| Option | Skill Enhanced | What Changes |
|--------|---------------|-------------|
| 201 | Artillery I | Ballista deals even more bonus damage |
| 202 | Eagle Eye I | Better chance to learn spells; can learn higher-circle spells |
| 103 | Eagle Eye II | Further improvement over Eagle Eye I |
| 203 | Estates I | Estates generates more daily gold |
| 191 | Estates II | Further increases Estates daily gold |
| 204 | First Aid I | First Aid Tent heals more HP per turn |
| 190 | First Aid Enhanced | Additional healing and resurrection improvements |
| 205 | Learning II | Hero gains significantly more XP from all sources |
| 217 | Learning I | Hero gains slightly more XP |
| 206 | Luck I | Luck skill gives bigger bonus damage on lucky strikes |
| 208 | Navigation I | More movement on water per Navigation level |
| 209 | Pathfinding I | Reduces rough terrain movement penalty more |
| 210 | Resistance II | Stronger magic resistance per Resistance level |
| 211 | Scholar I | Teaches better/higher circle spells when sharing |
| 212 | Scouting II | Reveals more map area per Scouting level |
| 213 | Sorcery II | Sorcery further boosts spell damage |
| 214 | Armorer I | Reduces physical damage taken more |
| 218 | Tactics I | More pre-battle movement rows per Tactics level |

---

### Sorcery Enhancement I (option 23)
**Classic:** `script23.erm`

Sorcery skill gives a stronger percentage bonus to spell damage at all three levels on top of the base effect.

---

### Mysticism Enhancement I & II (options 35, 207)
**Classic:** `script35.erm` + `script37.erm` sub-option

Hero regenerates more spell points per day. Mysticism II further increases the daily recovery rate.

---

### Hero Specialization Boost (option 39)
**Classic:** `script39.erm` by Alexis Koz

Hero specialties scale better with hero level. The bonus from a hero's specialty (e.g., +1 to Archers) increases proportionally as the hero levels up rather than staying flat.

---

### Rebalanced Hero Abilities (option 198)
**Classic:** `script37.erm` sub-option

Hero starting skills and class abilities rebalanced so no hero type has a major unfair advantage at game start.

---

### Rebalanced Starting Armies (option 199)
**Classic:** `script37.erm` sub-option

Heroes start with more balanced and fair army compositions.

---

### Advanced Witch Huts (option 194)
**Classic:** `script64.erm` by Tobyn

Witch Huts offer more advanced skill options. Hero can pay **3,000 gold** to upgrade a Basic skill to Advanced at a Witch Hut (normally Witch Huts only give Basic). Also links with the Warfare skill system.

---

---

## Battle & Combat 🔴

### Karmic Battles (option 38)
**Classic:** `script38.erm` by Dieter Averbeck

In battles between similarly-sized armies, combat is more even. Reduces the "first strike wins everything" problem in close engagements by giving disadvantaged attackers a slight compensation.

---

### Creature Relationships (option 47)
**Classic:** `script47.erm`

Certain creature types have bonus or penalty effects when fighting alongside or against specific other types. Example: Angels fighting Devils receive a morale or attack bonus; undead creatures near holy creatures suffer penalties.

---

### Enhanced Protection From the Elements (option 61)
**Classic:** `script61.erm` by Petyo Georgiev

Protection spells (Protection from Fire/Water/Earth/Air) have significantly stronger effects against elemental creatures, making them actually useful as a counter strategy.

---

### Battle Extender (option 220)
**Classic:** `script41.erm`

Allows a retreating hero to potentially rejoin battle under certain conditions, adding a tactical dimension to the retreat mechanic.

---

### Level 7+ Creatures Gain 50% XP (option 245)
**Classic:** `script00.erm` global rule

Tier 7 creatures (Dragons, Angels, etc.) earn only half experience from battles compared to lower-tier creatures, keeping stack experience balanced across all tiers.

---

---

## Creatures & Monsters 🔴

### Stack Experience System (option 900)
**Classic:** `script00.erm` + `script50.erm`

All creature stacks in a hero's army gain experience from battles and can rank up from **Rank 0 to Rank 10**.

- Each surviving creature stack gains XP equal to the hero's battle XP
- Ranks are shown by `^` symbols on the creature portrait (one per rank; sword icon = 5 ranks)
- Each rank gives the creature type-specific bonuses: Attack, Defense, Speed, Damage, or new abilities
- Right-click the creature portrait on the hero screen to see the Stack Experience screen with all rank bonuses
- Combining two stacks with different experience levels averages their XP

**AI Stack Experience Level** (option 229, value=7): Controls how aggressively AI creatures accumulate experience. Value 7 = standard WOG difficulty.

---

### Neutral Stack Experience (option 231)
**Classic:** `script50.erm` sub-option

Neutral (wandering, unowned) creature stacks on the adventure map also accumulate experience over time, making late-game neutral creatures progressively more dangerous.

---

### Enhanced Monsters (option 50)
**Classic:** `script50.erm` by Arstahd

Wandering monsters on the map have expanded behaviors and enhanced abilities. Some monsters have special passive effects or combat tricks that make them more interesting to fight.

---

### Neutral Units (option 57)
**Classic:** `script57.erm` by Alexandru Balahura

Controls neutral creature stack sizes and aggression settings. Affects how many creatures appear in each neutral stack and how quickly they become hostile.

---

### Replace Dragon Fly (option 165)
**Classic:** `script24.erm` sub-option

Dragon Flies on the map are replaced with a different creature type (from the enhanced hint text script).

---

### Some Level 3s → Ghosts (option 242)
**Classic:** `script37.erm` sub-option

Some Level 3 creature spawns on the adventure map are replaced with Ghost stacks, adding undead variety.

---

---

## Artifacts 🔴

### Enhanced Artifacts (option 71)
**Classic:** `script71.erm` by Arstahd

Existing HoMM3 artifacts have improved or expanded effects. Some artifacts that were underwhelming get meaningful buffs.

### New Artifacts (option 143)
**Classic:** `script02.erm` + `script25.erm`

New WOG-specific artifacts are added to the game's artifact pool and can appear in shops, on the map, and in chests.

### Artificer (option 26)
**Classic:** `script26.erm`

Heroes can combine or upgrade existing artifacts. Allows transforming weaker artifacts into more powerful versions by paying resources.

### Combination Artifacts (option 178/179)
**Classic:** `script33.erm`

Artifact sets can be assembled into powerful combined pieces when all components are collected.

### Power Stones (option 196)
**Classic:** `script08.erm` sub-option

Collectible stones found on the map that permanently boost a hero's primary skills when picked up.

### Magic Wand (option 176)
New artifact that extends spell effects — either range, duration, or power.

### Monster's Power (option 227)
New artifact whose power scales with the size or strength of the hero's army.

### Barbarian Lord's Axe of Ferocity (option 237)
A specific powerful new artifact added to the game.

### Gate Key (option 243)
New artifact that controls passage through certain map structures.

---

---

## Map Rules & Options 🔴

### Week of Monsters (option 20)
**Classic:** `script20.erm` by Timothy Pulver

Each week a random creature type gets a special bonus: doubled growth rate, increased stats in combat, or other effects. Announced at the start of each week.

---

### Upgraded Dwellings (option 133)
**Classic:** `script67.erm` (Neutral Town)

Some creature dwellings on the map start with upgraded creatures available for recruitment from the beginning.

---

### Wandering Monsters (option 135)
Enables monster groups that actively move around the adventure map rather than staying in fixed positions.

---

### Resource Piles (option 134)
Resource pile objects on the map function normally (some WOG configurations altered their behavior).

---

### Universal Upgrading (option 174)
**Classic:** `script25.erm` option

All creatures can be upgraded regardless of which town type or dwelling owns them.

---

### Refugee Camp Sync (option 200)
**Classic:** `script09.erm` sub-option

Refugee camps offer consistent creature types across all players in the same game session.

---

### Upgrading Treasure Chests (option 132)
**Classic:** `script29.erm` sub-option

Treasure chests on the map can be upgraded for larger gold or XP rewards.

---

### Special Terrain (option 142)
**Classic:** `script63.erm` (Passable Terrain)

Special terrain types (Magic Plains, Holy Ground, Lucid Pools, etc.) have their full WOG-enhanced effects rather than just visual changes.

---

### Spell Bans (options 146–153, 221–223, 246–247)
**Classic:** `script25.erm` Map Options

Certain spells are removed from availability in Mage Guilds, Spell Shrines, Scholars, Scrolls, and hero starting spells.

| Option | Ban |
|--------|-----|
| 146 | Spells banned from Mage Guilds |
| 147 | Spells banned from Spell Shrines |
| 148 | Spells banned from Scholar sharing |
| 150 | Spells banned from Spell Scrolls |
| 151 | Spells banned from hero starting spells |
| 152 | Summon Boat banned |
| 153 | Water Walk banned |
| 221 | Scuttle Boat banned |
| 222 | Visions banned |
| 223 | Armageddon banned |
| 246 | View Air banned |
| 247 | View Earth banned |

---

---

## Commanders 🔴

### Enhanced Commanders (option 51)
**Classic:** `script51.erm` by Arstahd

Commanders have expanded abilities, a full skill tree, and a leveling system. Each town type has a unique commander with its own stats and specialties.

### Choose Commanders (option 186)
Player can choose which commander to assign rather than being assigned one randomly.

### Commander Witch Huts (option 66)
**Classic:** `script66.erm`

Commanders can visit Witch Huts to learn new skills, just like heroes.

### Commander Sanctuary (option 76)
**Classic:** `script76.erm`

A special location where commanders can recover from defeat.

### Commander Artifacts (option 219)
Commanders can equip artifacts that enhance their abilities.

---

---

## Quality of Life 🔴

### Monster Mutterings (option 22)
**Classic:** `script22.erm` by Timothy Pulver

When hovering over enemy creatures in battle, they display flavor text "thoughts" based on their creature type. Purely atmospheric/cosmetic.

### Enhanced Hint Text (option 24)
**Classic:** `script24.erm` by Timothy Pulver

Better, more informative hover descriptions for adventure map objects.

### Abbreviated Skill Descriptions (option 75)
**Classic:** `script75.erm` by Hermann the Weird

Shorter, cleaner tooltip text for secondary skills in the hero screen.

### Display WoGification Messages (option 248)
Shows a message at game start listing which WOG features are active.

### Display Map Rules (option 230)
Shows which map rules (spell bans, etc.) are active at game start.

---

---

## Needs Engine Changes 🏗️

These require C++ work in FCMI before Lua can implement them.

### Enhanced War Machines I (option 54)
**Classic:** `script54.erm` by Overlord
**Blocker:** Battle creature manipulation API (change creature type mid-battle, track machine XP per-hero)

War machines gain experience and level up. Upgrading is done at the War Machine Factory or Trade screen once per town per day.

| Machine | HP Formula | Key Effect |
|---------|-----------|-----------|
| Ballista | `level × 50 + 200` | Bonus damage + speed debuff; `(Artillery + level) × 20` bonus |
| Catapult | `ballistics² × 50 + 550` | Extra shots: Basic=2, Advanced=4, Expert=8 per turn |
| Ammo Cart | `level × 10 + 90` | Restores spell points to hero each combat turn |
| First Aid Tent | `level × 25 + 125` | Heals `(FirstAid + level) × 20 + 80` HP; can resurrect |

Upgrade cost = `(machine base gold cost) / 5 × target level`

---

### Mithril Resource System (option 36)
**Classic:** `script36.erm` by Anders Jonsson
**Blocker:** 8th resource type (engine-level addition — use true engine support, not a proxy)

Mithril is a rare resource found across the map. Required for several other features (town income upgrades, dwelling upgrades, etc.).

**Sources:**
- 1 in 15 resource stacks replaced with Mithril (half amount for wood/ore/gold)
- 1 in 15 campfires contain Mithril
- 1 in 10 Windmills and Mystical Gardens contain Mithril

**Mithril Price List:**
| Enhancement | Cost |
|-------------|------|
| Double Wood/Ore Mine production (1 week) | 4 Mithril |
| Double Crystal/Gem/Sulfur/Mercury Mine (1 week) | 4 Mithril |
| Double Gold Mine production (1 week) | 7 Mithril |
| Double Windmill/Water Wheel production | 5 Mithril |
| Upgrade Creature Dwelling (upgraded creatures) | 1–3 Mithril |
| Place Magical Terrain to protect a Town | 1 or 3 Mithril |
| Build Lighthouse near a Shipyard | 3 Mithril |
| Change Spell Shrine spell | 1–3 Mithril |
| Change Witch Hut skill | 2 Mithril |
| Scout around a Monolith's exits | 1 Mithril |
| Protect Mine from "Mines Change Every Week" | 1–5 Mithril |
| Upgrade University | 4 Mithril |
| **Gold Reserve building upgrade** | **7,000 gold + 2 Mithril** |

---

### Mirror of the Home-Way (option 52)
**Classic:** `script52.erm` by Sir Four

A special artifact/object that allows a hero to teleport home to their starting town. Requires reliable object interaction API.

---

### Espionage (option 58)
**Classic:** `script58.erm` by Petyo Georgiev

Heroes with Scouting can gather intelligence on enemy towns and heroes. Requires read access to enemy game state.

---

### Transfer Owner (option 192)
**Classic:** `script64.erm` by Tobyn

Enables mid-game ownership transfer of towns, heroes, mines, dwellings, and other objects between players (including allies). Requires player ownership mutation API.

---

### Death Chamber (option 70)
**Classic:** `script70.erm` by Rich Reed

Special mechanic where heroes can level up beyond normal limits by completing high-difficulty challenges.

---

### Summon Elementals Script (option 244)
**Classic:** `script74.erm`

New battle spells that summon elemental creature stacks of different types.

---

---

## Map Object Features ⚫

These only activate on maps that have the specific WOG objects placed. They are not automatic in every game — you need WOG-compatible maps or to place objects via the map editor.

| Option | Feature | Object |
|--------|---------|--------|
| 6 | **Hourglass of Asmodeus** | Special hero that appears on map; knows all skills |
| 7 | **Fishing Well** | Gives weekly fish = resource bonuses |
| 8/108 | **Junk Merchant** | Shop where junk items can be sold for gold |
| 10 | **Magic Mushrooms** | Gives random weekly bonuses when visited |
| 16 | **Battle Academy** | Buy primary skills, secondary skills, or artifacts for gold |
| 28/185 | **School of Wizardry** | Purchase spells directly |
| 43 | **Obelisk Runes** | Enhanced obelisks that grant special bonuses |
| 44 | **Emerald Tower** | Tower object with unique rewards |
| 65 | **Monolith Toll** | Two-way monoliths cost resources to use |
| 104 | **Arcane Tower** | Special magic-boosting tower |
| 105 | **Loan Bank** | Borrow gold at interest |
| 109 | **Market of Time** | Forget a secondary skill for 2,000 gold (500 movement); Warfare skills all forgotten together |
| 5 | **Resource Trading Post** | Exchange resources at variable rates; bulk transfer button |

---

---

## Unknown Options ❓

These were enabled in your setup but couldn't be definitively identified from local scripts. Please check in your classic WOG setup and let me know what these are.

| Option | Best Guess | Confirm? |
|--------|-----------|----------|
| 113 | Possibly related to Tavern Card Game (script13) | ? |
| 116 | Possibly Potion Fountains (script17) sub-option | ? |
| 118 | Possibly Alms House (script18) sub-option | ? |
| 119 | Double Artifact Rule (two artifacts from a chest) | ? |
| 122 | Unknown | ? |
| 123 | Unknown | ? |
| 124 | Unknown | ? |
| 126 | Unknown | ? |
| 127 | Unknown | ? |
| 183 | Mysticism Enhancement script enable flag | ? |
| 187 | Spellbook script enable flag | ? |
| 239 | Unknown | ? |
| 902 | Stack Experience sub-option (equal XP shares?) | ? |

---

---

## Engine Changes Made in FCMI

Changes made to `DepacheNinja/fcmi` (branch `develop`) to support WOG New Age scripts.

### New Events

| Event | Header | Fires When |
|-------|--------|-----------|
| `events.HeroLevelUp` | `include/vcmi/events/HeroLevelUp.h` | After a hero levels up |
| `events.BattleEnded` | `include/vcmi/events/BattleEnded.h` | After any battle ends |

### New Netpacks

| Netpack | Purpose |
|---------|---------|
| `netpacks.SetSecSkill` | Set a hero's secondary skill to a specific level |
| `netpacks.SetPrimarySkill` | Set/modify a hero's primary stat |
| `netpacks.SetHeroExperience` | Add or set hero experience |

### Expanded Lua APIs

**Hero methods added (`HeroInstance`):**

| Method | Returns |
|--------|---------|
| `hero:getLevel()` | Current level |
| `hero:getExperience()` | Total XP |
| `hero:getAttack()` | Primary: Attack |
| `hero:getDefense()` | Primary: Defense |
| `hero:getSpellPower()` | Primary: Spell Power |
| `hero:getKnowledge()` | Primary: Knowledge |
| `hero:getPrimSkillLevel(n)` | Any primary skill (0–3) |
| `hero:getSecSkillLevel(n)` | Any secondary skill level by ID (0–27) |
| `hero:getId()` | ObjectInstanceID |

**HeroLevelUp event methods:**

| Method | Returns |
|--------|---------|
| `event:getPlayer()` | PlayerColor |
| `event:getHero()` | ObjectInstanceID |
| `event:getLevel()` | New level |
| `event:getPrimarySkillGained()` | 0=ATK 1=DEF 2=SP 3=KNO |

**BattleEnded event methods:**

| Method | Returns |
|--------|---------|
| `event:getVictor()` | Winner PlayerColor |
| `event:getLoser()` | Loser PlayerColor |
| `event:getWinnerHeroId()` | ObjectInstanceID (-1 if none) |
| `event:getLoserHeroId()` | ObjectInstanceID (-1 if none) |
| `event:getExpAwarded()` | XP given to winner |

---

---

## Secondary Skill ID Reference

| ID | Skill | | ID | Skill |
|----|-------|-|----|-------|
| 0 | Pathfinding | | 14 | Fire Magic |
| 1 | Archery | | 15 | Air Magic |
| 2 | Logistics | | 16 | Water Magic |
| 3 | Scouting | | 17 | Earth Magic |
| 4 | Diplomacy | | 18 | Scholar |
| 5 | Navigation | | 19 | Tactics |
| 6 | Leadership | | **20** | **Artillery ← Warfare** |
| 7 | Wisdom | | 21 | Learning |
| 8 | Mysticism | | 22 | Offence |
| 9 | Luck | | 23 | Armorer |
| **10** | **Ballistics ← Warfare** | | 24 | Intelligence |
| 11 | Eagle Eye | | 25 | Sorcery |
| 12 | Necromancy | | 26 | Resistance |
| 13 | Estates | | **27** | **First Aid ← Warfare** |
