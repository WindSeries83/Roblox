--!strict

local Probability = {}

function Probability.FinalRarityWeights(
	baseWeights: { [string]: number },
	rarityOrder: { string },
	luck: number?,
	ascendChance: number?
): { [string]: number }
	local result: { [string]: number } = {}
	local chance = math.clamp((ascendChance or 0) * (1 + (luck or 0)), 0, 1)
	for rarity, weight in baseWeights do
		local rank = table.find(rarityOrder, rarity) or 0
		local nextRarity = rarityOrder[rank + 1]
		result[rarity] = (result[rarity] or 0) + weight * if nextRarity then 1 - chance else 1
		if nextRarity then
			result[nextRarity] = (result[nextRarity] or 0) + weight * chance
		end
	end
	return result
end

function Probability.FinalHatchWeights(
	tier: string,
	baseWeights: { [string]: { [string]: number } },
	firstHatchWeights: { [string]: number },
	rarityOrder: { string },
	pityThreshold: number,
	luck: number?,
	ascendChance: number?,
	totalHatched: number,
	hatchesSinceRare: number
): { [string]: number }
	if hatchesSinceRare >= pityThreshold - 1 then
		return { Rare = 100 }
	end
	local source = if totalHatched == 0 and tier == "CommonEgg" then firstHatchWeights else baseWeights[tier]
	assert(source, `Unknown egg tier: {tostring(tier)}`)
	return Probability.FinalRarityWeights(source, rarityOrder, luck, ascendChance)
end

return Probability
