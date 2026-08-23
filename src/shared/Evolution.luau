local Config = require(script.Parent.Config)
local Stages = require(script.Parent.Data.Stages)
local Species = require(script.Parent.Data.Species)
local Rarities = require(script.Parent.Data.Rarities)
local Mutations = require(script.Parent.Data.Mutations)
local Equipment = require(script.Parent.Data.Equipment)

local Evolution = {}

function Evolution.StageDef(stage: number)
	return Stages[stage]
end

function Evolution.XPToNext(level: number): number
	return Config.LEVEL_XP_BASE * level
end

function Evolution.EquippedMaxLevelBonus(equipment: { any }): number
	local bonus = 0
	for _, item in equipment do
		if item.Type == "Heart" then
			local def = Equipment.Heart.Tiers[item.Tier]
			if def then
				bonus += def.MaxLevelBonus
			end
		end
	end
	return bonus
end

function Evolution.MaxLevelFor(creature: any): number
	local stage = Evolution.StageDef(creature.Stage)
	if not stage then
		return Config.BASE_MAX_LEVEL
	end
	return stage.MaxLevel + Evolution.EquippedMaxLevelBonus(creature.Equipment)
end

function Evolution.ComputePower(creature: any): number
	local species = Species[creature.SpeciesId]
	local rarity = Rarities[creature.Rarity]
	local mutation = creature.Mutation ~= false and Mutations[creature.Mutation] or nil
	if not species or not rarity then
		return 0
	end
	local stage = Evolution.StageDef(creature.Stage or 1)
	local levelMult = 1 + Config.LEVEL_POWER_BONUS * ((creature.Level or 1) - 1)
	return math.round(
		species.BasePower * rarity.PowerMult * (mutation and mutation.Multiplier or 1) * stage.PowerMult * levelMult
	)
end

function Evolution.RateMultFor(stage: number): number
	local def = Evolution.StageDef(stage or 1)
	return def and def.RateMult or 1
end

function Evolution.CanEvolve(creature: any, essence: number): (boolean, string?)
	local stage = creature.Stage
	if stage >= #Stages then
		return false, "stage maximum atteint"
	end
	local nextStage = Stages[stage + 1]
	if nextStage.RequireLevel and creature.Level < nextStage.RequireLevel then
		return false, `niveau {nextStage.RequireLevel} requis`
	end
	if nextStage.Cost and essence < nextStage.Cost then
		return false, "Essence insuffisante"
	end
	if nextStage.RequiresRelic then
		for _, item in creature.Equipment do
			if item.Type == "Relic" then
				return true
			end
		end
		return false, "une Relique équipée est requise"
	end
	return true
end

function Evolution.EvolveCost(creature: any): number
	local nextStage = Stages[creature.Stage + 1]
	return nextStage and nextStage.Cost or 0
end

function Evolution.ConsumeRelic(creature: any): boolean
	for i, item in creature.Equipment do
		if item.Type == "Relic" then
			table.remove(creature.Equipment, i)
			return true
		end
	end
	return false
end

function Evolution.AddXP(creature: any, amount: number): boolean
	local maxLevel = Evolution.MaxLevelFor(creature)
	if creature.Level >= maxLevel then
		creature.XP = 0
		return false
	end
	creature.XP += amount
	local leveled = false
	while creature.Level < maxLevel do
		local needed = Evolution.XPToNext(creature.Level)
		if creature.XP < needed then
			break
		end
		creature.XP -= needed
		creature.Level += 1
		leveled = true
	end
	if creature.Level >= maxLevel then
		creature.XP = 0
	end
	if leveled then
		creature.Power = Evolution.ComputePower(creature)
	end
	return leveled
end

return Evolution
