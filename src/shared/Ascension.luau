local Config = require(script.Parent.Config)
local Gameplay = require(script.Parent.Gameplay)
local Rarities = require(script.Parent.Data.Rarities)

local Ascension = {}

Ascension.MAX_RANK = 7

function Ascension.RollFrom(baseRarity: string, luck: number?, chanceOverride: number?): string
	local rank = Gameplay.RarityRank(baseRarity)
	if rank <= 0 or rank >= Ascension.MAX_RANK then
		return baseRarity
	end
	if Random.new():NextNumber() < (chanceOverride or Config.ASCEND_CHANCE) * (1 + (luck or 0)) then
		return Rarities.ORDER[rank + 1]
	end
	return baseRarity
end

function Ascension.SecretTrigger(eggTier: string, eclipseActive: boolean, relicTier: string?): boolean
	return eggTier == "RareEgg" and eclipseActive == true and relicTier == "T3"
end

return Ascension
