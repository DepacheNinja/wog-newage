-- wog_level7_xp.lua
-- WOG New Age — Level 7+ Creatures Gain 50% XP (option 245)
--
-- In classic WOG, when you win a battle against tier-7 creatures,
-- the XP awarded is reduced by 50% to balance the high-tier dominance.
-- (Alternatively: your tier-7 stacks gain only half XP from battles.)
--
-- VCMI approximation: After a battle, if the XP awarded seems very high
-- (suggesting tier-7 opponent), cap the bonus XP. This is approximate
-- since we can't easily detect opponent creature tiers from BattleEnded.
--
-- A more accurate implementation would require BattleEnded to expose
-- the enemy army composition. For now this is a placeholder.
--
-- STATUS: Placeholder — real implementation needs creature tier info
-- from the battle result. Disabled by default.

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG
C.level7XPEnabled = false  -- disabled until battle army info is available
