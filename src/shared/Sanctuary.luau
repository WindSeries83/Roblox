local Config = require(script.Parent.Config)

local Sanctuary = {}

Sanctuary.SLOTS_PER_LEVEL = Config.SANCTUARY_SLOTS_PER_LEVEL

function Sanctuary.MaxCreatures(sanctuaryLevel: number, bonusSlots: number?): number
	return Config.MAX_CREATURES_BASE
		+ math.max(0, sanctuaryLevel - 1) * Config.SANCTUARY_SLOTS_PER_LEVEL
		+ (bonusSlots or 0)
end

function Sanctuary.NextLevelCost(sanctuaryLevel: number): number?
	return Config.SANCTUARY_UPGRADE_BASE_COST * (Config.SANCTUARY_UPGRADE_COST_MULT ^ (sanctuaryLevel - 1))
end

function Sanctuary.CanUpgrade(essence: number, sanctuaryLevel: number): (boolean, string?)
	local cost = Sanctuary.NextLevelCost(sanctuaryLevel)
	if not cost then
		return false, "niveau maximum atteint"
	end
	if essence < cost then
		return false, "Essence insuffisante"
	end
	return true
end

function Sanctuary.UpgradeCost(sanctuaryLevel: number): number
	return Sanctuary.NextLevelCost(sanctuaryLevel) or 0
end

-- Tiers d'œufs verrouillés à ce rang : { tier = rang requis }. Absent = débloqué.
function Sanctuary.EggGate(sanctuaryLevel: number): { [string]: number }
	return {
		UncommonEgg = if sanctuaryLevel >= 2 then nil else 2,
		RareEgg = if sanctuaryLevel >= 3 then nil else 3,
	}
end

function Sanctuary.EggLocked(tier: string, sanctuaryLevel: number): number?
	local gate = Sanctuary.EggGate(sanctuaryLevel)
	if gate[tier] then
		return gate[tier]
	end
	return nil
end

return Sanctuary
