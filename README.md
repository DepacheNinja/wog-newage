# WOG New Age

Full WOG experience for VCMI 1.7+. Extends the existing `wake-of-gods` mod with
missing classic WOG 3.58f features ported to VCMI's JSON system.

## Status

Version 0.3.0 — alternate creature upgrade paths corrected and implemented.

## How it works

- **Depends on `wake-of-gods`** — all existing VCMI WOG features are included automatically
- **Adds on top** — this mod layers new features that wake-of-gods is missing
- **wake-of-gods updates won't break this** — it's a separate mod that depends on it, not a fork

---

## What is implemented

### Alternate creature upgrade paths (v0.3.0)

Classic WOG added alternate upgrade paths for certain creatures. In VCMI this works
via the `upgrades` array on creature JSON. When a hero is at a dwelling that produces
the upgraded creature, they get the option to upgrade their army.

| Base creature | WOG alternate upgrade | Available at dwelling |
|---|---|---|
| Master Gremlin (Tower) | Santa Gremlin | Snowman (adventure map) |
| Centaur Captain (Rampart) | Sylvan Centaur | Sylvan Homestead (adventure map) |
| Zealot (Castle) | War Zealot | Lost Friary (adventure map) |

The three WOG alt creatures and their standalone dwellings are already fully defined in
`wake-of-gods`. This mod adds the upgrade connections so heroes can upgrade their armies
when visiting those dwellings.

### Already in wake-of-gods (no re-implementation needed)

| Inferno alt chain | Status |
|---|---|
| HellSteed → Nightmare | Fully in wake-of-gods: HellSteed is inferno level 6 with `upgrades: [nightmare]` |

All other WOG alt creatures (Ghost, Gorynych, Werewolf, Dracolich, Arctic/Lava Sharpshooter,
WogSorceress) are neutral-faction map creatures. They recruit from standalone adventure map
dwellings already added by wake-of-gods. No upgrade connections needed.

---

## What requires Lua scripting (NOT available in VCMI 1.7.3)

VCMI 1.7.3 ships without a Lua DLL — no lua*.dll found in the install folder.
The following classic WOG features cannot be ported until VCMI ships Lua support:

| ERM Script | Feature |
|---|---|
| script45.erm | Town Income Development (buy extra gold/week from town) |
| script05.erm | Loan Bank System (borrow gold, pay daily interest) |
| script19.erm | Masters of Life (auto-upgrade 1st level creatures each turn) |
| script00.erm | Core WOGify initialization, dwelling replacement, option flags |
| script01.erm | Map rules (21 gameplay rule toggles) |
| script09.erm | New secondary skills / Warfare skill |
| script14.erm | Necromancy upgrades |
| script20.erm | Week of Monsters variants |

When VCMI adds Lua, scripts go in `scripts\` subfolder declared in mod.json.
API docs: https://vcmi.eu/developers/Lua_Scripting/

---

## What the map looks like (WOGify)

In classic WOG, the map looked "wogified" because:
1. **WOG map objects** — special shrines, dwellings, etc. placed on WOG-format maps
2. **WOG Graphics Fix** — terrain and creature sprite replacements

Wake-of-gods provides both of these. To see WOG map objects on the adventure map,
play on a WOG-format map (.wog extension) or use random maps where wake-of-gods
adds WOG dwellings, creature banks, and map objects to the generation pool.

On standard H3 maps, WOG objects don't appear because the map maker didn't place them.

---

## Classic scripts reference

All ERM scripts from WOG 3.58f are in `classic-scripts\` for reference.
These are NOT loaded by VCMI.

### Correct script-to-feature mapping

| Script | Actual feature |
|---|---|
| script00.erm | Core WOGify: option selection, dwelling replacement (FU684), init |
| script01.erm | Map rules: 21 gameplay toggles (Warlord's Banners, double movement, etc.) |
| script02.erm | Artifact Boost (weekly creature grants from specific artifacts) |
| script03.erm | Random map generator settings |
| script04.erm | Random hero bonuses |
| script05.erm | Loan Bank System |
| script06.erm | Hourglass of Asmodeus artifact mechanics |
| script07.erm | Creature experience (stack XP — base system already in wake-of-gods) |
| script09.erm | New secondary skills + Warfare skill |
| script10.erm | Commanders expanded (base commanders already in wake-of-gods) |
| script14.erm | Necromancy upgrades |
| script18.erm | Alms House object (daily gold grants) |
| script19.erm | Masters of Life (auto-upgrade tier 1 creatures each turn) |
| script20.erm | Week of Monsters variants |
| script45.erm | Town Income Development (castle upgrading) |

---

## File structure

```
wog-newage\
  mod.json                                  -- mod manifest (v0.3.0)
  README.md                                 -- this file
  classic-scripts\                          -- reference only, original ERM scripts
  config\
      creatures\
          altUpgradesCreaturePatch.json     -- patches masterGremlin, centaurCaptain,
                                           --   zealot with WOG alt upgrades
```
