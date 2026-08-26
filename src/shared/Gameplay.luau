local HttpService = game:GetService("HttpService")

local Config = require(script.Parent.Config)
local Rarities = require(script.Parent.Data.Rarities)
local Mutations = require(script.Parent.Data.Mutations)
local Species = require(script.Parent.Data.Species)
local Evolution = require(script.Parent.Evolution)

local Gameplay = {}

-- Nom affiché : Name si l'espèce existe, sinon l'id brut (donnée absente/legacy).
function Gameplay.SpeciesName(speciesId: string): string
	local species = Species[speciesId]
	return species and species.Name or speciesId
end

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

function Gameplay.DropRates(weights: { [string]: number }): { { Id: string, Percent: number } }
	if type(weights) ~= "table" then
		return {}
	end
	local total = 0
	for _, weight in weights do
		total += weight
	end
	if total <= 0 then
		return {}
	end
	local rates = {}
	for id, weight in weights do
		table.insert(rates, { Id = id, Percent = math.floor(100 * weight / total * 100 + 0.5) / 100 })
	end
	table.sort(rates, function(a, b)
		return a.Percent > b.Percent
	end)
	return rates
end

function Gameplay.MutationWeights(bonus: number?): { [string]: number }
	local boost = 1 + (bonus or 0)
	local weights = {
		None = Config.MUTATION_WEIGHTS.None,
	}
	for mutation, weight in Config.MUTATION_WEIGHTS do
		if mutation ~= "None" then
			weights[mutation] = weight * boost
		end
	end
	return weights
end

function Gameplay.RollEgg(tier: string, mutationBonus: number?, rarityWeights: { [string]: number }?)
	local weights = rarityWeights or Config.EGG_RARITY_WEIGHTS[tier]
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

	local mutationRoll = Gameplay.WeightedRoll(Gameplay.MutationWeights(mutationBonus))
	local mutation = if mutationRoll == "None" then false else mutationRoll

	return {
		SpeciesId = speciesId,
		Rarity = rarity,
		Mutation = mutation,
	}
end

function Gameplay.CreateCreature(rarity: string, speciesId: string, mutation)
	local creature = {
		Id = HttpService:GenerateGUID(false),
		SpeciesId = speciesId,
		Rarity = rarity,
		Mutation = mutation,
		Level = 1,
		MaxLevel = Config.BASE_MAX_LEVEL,
		XP = 0,
		Stage = 1,
		Power = 0,
		Equipment = {},
		Parents = {},
		Generation = 1,
		HatchedAt = os.time(),
	}
	creature.Power = Evolution.ComputePower(creature)
	return creature
end

function Gameplay.ComputeRate(creatures: { any }): number
	local rate = 0
	for _, creature in creatures do
		local species = Species[creature.SpeciesId]
		local rarity = Rarities[creature.Rarity]
		local mutation = creature.Mutation ~= false and Mutations[creature.Mutation] or nil
		if species and rarity then
			local mult = rarity.EssenceMult
				* (mutation and mutation.Multiplier or 1)
				* Evolution.RateMultFor(creature.Stage)
			rate += species.BaseRate * Config.ESSENCE_BASE_RATE * mult
		end
	end
	return rate
end

function Gameplay.RarityRank(rarity: string): number
	local rank = table.find(Rarities.ORDER, rarity)
	return rank or 0
end

function Gameplay.FindCreature(creatures: { any }, id: string?): any
	for _, creature in creatures do
		if creature.Id == id then
			return creature
		end
	end
	return nil
end

function Gameplay.CheckCooldown(
	store: { [any]: { [string]: number } },
	owner: any,
	action: string,
	seconds: number
): boolean
	local now = os.clock()
	local perOwner = store[owner]
	if not perOwner then
		perOwner = {}
		store[owner] = perOwner
	end
	local last = perOwner[action] or 0
	if now - last < seconds then
		return false
	end
	perOwner[action] = now
	return true
end

-- Consomme une clé une seule fois : true au premier appel, false aux replays.
function Gameplay.ConsumeOnce(map: { [string]: boolean }, key: string): boolean
	if map[key] then
		return false
	end
	map[key] = true
	return true
end

return Gameplay
