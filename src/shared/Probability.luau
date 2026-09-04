--!strict

local Config = require(script.Parent.Config)
local Rarities = require(script.Parent.Data.Rarities)
local Probability = {}

type Input = {
	tier: string,
	totalHatched: number,
	hatchesSinceRare: number,
	luck: number?,
	ascendChance: number?,
	mutationBonus: number?,
}

type Context = {
	RarityWeights: { [string]: number },
	MutationWeights: { [string]: number },
	Luck: number,
	AscendChance: number,
	PityForced: boolean,
}

local function Ascended(weights: { [string]: number }, chance: number): { [string]: number }
	local result: { [string]: number } = {}
	local order = Rarities.ORDER
	for rarity, weight in weights do
		local rank = table.find(order, rarity)
		local nextRarity = rank and order[rank + 1]
		result[rarity] = (result[rarity] or 0) + weight * (if nextRarity then 1 - chance else 1)
		if nextRarity then
			result[nextRarity] = (result[nextRarity] or 0) + weight * chance
		end
	end
	return result
end

function Probability.Build(input: Input): Context
	local luck = math.clamp(input.luck or 0, 0, Config.LUCK_HARD_CAP)
	local pityForced = input.hatchesSinceRare >= Config.PITY_THRESHOLD - 1
	local base = if pityForced
		then { Rare = 100 }
		elseif input.totalHatched == 0 and input.tier == "CommonEgg" then Config.FIRST_HATCH_WEIGHTS
		else Config.EGG_RARITY_WEIGHTS[input.tier]
	assert(base, `Unknown egg tier: {input.tier}`)
	local ascendChance = math.clamp((input.ascendChance or 0) * (1 + luck), 0, 1)
	local mutations: { [string]: number } = {}
	for mutation, weight in Config.MUTATION_WEIGHTS do
		mutations[mutation] = if mutation == "None" then weight else weight * (1 + (input.mutationBonus or 0))
	end
	return {
		RarityWeights = if pityForced then base else Ascended(base, ascendChance),
		MutationWeights = mutations,
		Luck = luck,
		AscendChance = ascendChance,
		PityForced = pityForced,
	}
end

return Probability
