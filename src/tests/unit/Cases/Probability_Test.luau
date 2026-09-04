--!strict

return function(t)
	local expect = t.expect
	local Probability = require(game.ReplicatedStorage.Shared.Probability)
	local Config = require(game.ReplicatedStorage.Shared.Config)

	t.test("probability context applies hard cap and first hatch", function()
		local context = Probability.Build({
			tier = "CommonEgg",
			totalHatched = 0,
			hatchesSinceRare = 0,
			luck = 9,
			mutationBonus = 0,
		})
		expect.equal(context.RarityWeights.Common, Config.FIRST_HATCH_WEIGHTS.Common)
		expect.equal(context.Luck, Config.LUCK_HARD_CAP)
	end)

	t.test("pity boundary forces rare", function()
		local before = Probability.Build({
			tier = "CommonEgg",
			totalHatched = 4,
			hatchesSinceRare = Config.PITY_THRESHOLD - 2,
		})
		local at = Probability.Build({
			tier = "CommonEgg",
			totalHatched = 4,
			hatchesSinceRare = Config.PITY_THRESHOLD - 1,
		})
		expect.falsy(before.PityForced)
		expect.truthy(at.PityForced)
		expect.equal(at.RarityWeights.Rare, 100)
	end)

	t.test("ascension and mutation bonuses accumulate in one context", function()
		local context = Probability.Build({
			tier = "RareEgg",
			totalHatched = 4,
			hatchesSinceRare = 0,
			luck = 0.5,
			ascendChance = 0.2,
			mutationBonus = 0.5,
		})
		expect.equal(context.RarityWeights.Rare, 70)
		expect.near(context.RarityWeights.Epic, 30, 1e-9)
		expect.equal(context.MutationWeights.Shadow, Config.MUTATION_WEIGHTS.Shadow * 1.5)
	end)
end
