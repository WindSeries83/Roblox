local HttpService = game:GetService("HttpService")

local Config = require(script.Parent.Config)
local Rarities = require(script.Parent.Data.Rarities)
local Mutations = require(script.Parent.Data.Mutations)
local Species = require(script.Parent.Data.Species)

local Gameplay = {}

function Gameplay.WeightedRoll(weights: { [string]: number }): string?
	if type(weights) ~= "table" then
		return nil
	end
	local total = 0
	for _, weight in weights do
		total += weight
	end
	if total <= 0 then
		return nil
	end
	local roll = Random.new():NextNumber() * total
	for key, weight in weights do
		roll -= weight
		if roll <= 0 then
			return key
		end
	end
	return (next(weights))
end

function Gameplay.RollEgg(tier: string)
	local weights = Config.EGG_RARITY_WEIGHTS[tier]
	assert(weights, `Unknown egg tier: {tostring(tier)}`)

	local rarity = Gameplay.WeightedRoll(weights)
	assert(rarity, `No rarity roll for tier: {tostring(tier)}`)

	local pool = {}
	for speciesId, def in Species do
		if def.Rarity == rarity then
			table.insert(pool, speciesId)
		end
	end
	assert(#pool > 0, `No species for rarity: {tostring(rarity)}`)
	local speciesId = pool[Random.new():NextInteger(1, #pool)]

	local mutationRoll = Gameplay.WeightedRoll(Config.MUTATION_WEIGHTS)
	local mutation = mutationRoll == "None" and false or mutationRoll

	return {
		SpeciesId = speciesId,
		Rarity = rarity,
		Mutation = mutation,
	}
end

function Gameplay.CreateCreature(rarity: string, speciesId: string, mutation)
	local species = Species[speciesId]
	local rarityDef = Rarities[rarity]
	local mutationDef = mutation ~= false and Mutations[mutation] or nil

	local power = math.round(species.BasePower * rarityDef.PowerMult * (mutationDef and mutationDef.Multiplier or 1))

	return {
		Id = HttpService:GenerateGUID(false),
		SpeciesId = speciesId,
		Rarity = rarity,
		Mutation = mutation,
		Level = 1,
		Power = power,
	}
end

function Gameplay.ComputeRate(creatures: { any }): number
	local rate = 0
	for _, creature in creatures do
		local species = Species[creature.SpeciesId]
		local rarity = Rarities[creature.Rarity]
		local mutation = creature.Mutation ~= false and Mutations[creature.Mutation] or nil
		if species and rarity then
			local mult = rarity.EssenceMult * (mutation and mutation.Multiplier or 1)
			rate += species.BaseRate * Config.ESSENCE_BASE_RATE * mult
		end
	end
	return rate
end

function Gameplay.RarityRank(rarity: string): number
	local rank = table.find(Rarities.ORDER, rarity)
	return rank or 0
end

return Gameplay
