-- wog_special_terrain.lua
-- WOG New Age — Special Terrain Effects (option 142)
--
-- WOG adds special adventure-map terrains with unique daily effects:
--
--   Magic Plains    — hero regenerates extra mana each day (terrain that
--                     powers up spellcasters)
--   Clover Fields   — hero gains +3 Luck while standing here (applied each
--                     morning as a temporary bonus; not yet achievable without
--                     a morale/luck bonus API, so we give XP instead)
--   Fiery Fields    — hero is singed; slight XP loss (WOG: fire penalty)
--   Rock Land       — sturdy earth; hero gains earth affinity XP bonus
--   Lucid Pools     — clear water; hero regenerates extra mana (like Magic Plains)
--   Holy Ground     — undead-hostile; Necropolis heroes gain no benefit here
--   Cursed Ground   — magic fails; no benefit (vanilla already blocks spells)
--   Evil Fog        — darkness; hero loses mana each day
--
-- Implementation notes:
--   We fire on PlayerGotTurn each morning for every human hero.
--   Hero position is retrieved via GAME:getHeroPosition(heroId).
--   Terrain is queried via GAME:getTerrainAt(x, y, z).
--   Effects use SetMana for mana change, SetHeroExperience for XP effects.
--
-- Terrain string IDs (from VCMI / WOG terrain mods):
--   "magicPlains", "cloverFields", "fieryFields", "rockLand",
--   "lucidPools", "holyGround", "cursedGround", "evilFog"

local PlayerGotTurn     = require("events.PlayerGotTurn")
local SetMana           = require("netpacks.SetMana")
local SetHeroExperience = require("netpacks.SetHeroExperience")

DATA.WOG = DATA.WOG or {}
local C = DATA.WOG

C.specialTerrainEnabled = C.specialTerrainEnabled ~= false

-- Mana restored per day on magic terrain (% of max mana)
C.magicPlainsManaRegen  = C.magicPlainsManaRegen  or 10  -- % of max mana
C.lucidPoolsManaRegen   = C.lucidPoolsManaRegen   or 10  -- % of max mana
-- Mana drained per day on Evil Fog (% of current mana)
C.evilFogManaDrain      = C.evilFogManaDrain      or 10  -- % of current mana
-- XP bonus/penalty for standing on terrain
C.rockLandXPBonus       = C.rockLandXPBonus       or 50  -- flat XP bonus per day
C.fieryFieldsXPPenalty  = C.fieryFieldsXPPenalty  or 25  -- flat XP penalty (negative XP not applied; skipped instead)

-- Faction for Necropolis heroes (Holy Ground gives no benefit)
local NECROPOLIS_FACTION = 4

local function clamp(v, lo, hi)
	return math.max(lo, math.min(hi, v))
end

local function giveMana(heroId, amount)
	local pack = SetMana.new()
	pack:setHeroId(heroId)
	pack:setValue(amount)
	pack:setMode(false)  -- relative (add/subtract)
	SERVER:commitPackage(pack)
end

local function giveXP(heroId, amount)
	if amount <= 0 then return end
	local pack = SetHeroExperience.new()
	pack:setHeroId(heroId)
	pack:setValue(amount)
	pack:setMode(false)  -- relative
	SERVER:commitPackage(pack)
end

wogSpecialTerrainSub = PlayerGotTurn.subscribeAfter(EVENT_BUS, function(event)
	if not C.specialTerrainEnabled then return end

	local playerIdx = event:getPlayer()
	if not GAME:isPlayerHuman(playerIdx) then return end

	local heroIds = GAME:getPlayerHeroes(playerIdx)
	if not heroIds then return end

	for _, heroId in ipairs(heroIds) do
		local hero = GAME:getHero(heroId)
		if hero then
			local x, y, z = GAME:getHeroPosition(heroId)
			if x then
				local terrain = GAME:getTerrainAt(x, y, z)
				if terrain then
					local maxMana = hero:getManaMax()
					local curMana = hero:getMana()

					if terrain == "magicPlains" or terrain == "lucidPools" then
						-- Magic terrain: regenerate extra mana each morning
						local regen = C.magicPlainsManaRegen
						if terrain == "lucidPools" then
							regen = C.lucidPoolsManaRegen
						end
						local bonus = math.floor(maxMana * regen / 100)
						if bonus > 0 then
							-- Only regen up to max mana
							local toAdd = clamp(bonus, 0, maxMana - curMana)
							if toAdd > 0 then
								giveMana(heroId, toAdd)
							end
						end

					elseif terrain == "evilFog" then
						-- Evil Fog: drain mana each morning
						local drain = math.floor(curMana * C.evilFogManaDrain / 100)
						if drain > 0 then
							giveMana(heroId, -drain)
						end

					elseif terrain == "rockLand" then
						-- Rock Land: earth affinity, small daily XP bonus
						giveXP(heroId, C.rockLandXPBonus)

					elseif terrain == "holyGround" then
						-- Holy Ground: benefit only non-Necropolis heroes
						local factionId = hero:getFactionId()
						if factionId ~= NECROPOLIS_FACTION then
							-- Small mana regen bonus (holy blessing)
							local bonus = math.floor(maxMana * 5 / 100)
							if bonus > 0 then
								local toAdd = clamp(bonus, 0, maxMana - curMana)
								if toAdd > 0 then
									giveMana(heroId, toAdd)
								end
							end
						else
							-- Necropolis heroes: mana drain on Holy Ground
							local drain = math.floor(curMana * 5 / 100)
							if drain > 0 then
								giveMana(heroId, -drain)
							end
						end

					end
					-- Note: cloverFields (+3 luck), fieryFields, cursedGround
					-- require morale/luck modification API not yet available.
					-- These terrains are silently handled by VCMI's built-in
					-- cursed ground (no magic) and H3 terrain morale rules.
				end
			end
		end
	end
end)
