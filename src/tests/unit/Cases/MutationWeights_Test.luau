return function(t)
	local expect = t.expect
	local Config = require(game.ReplicatedStorage.Shared.Config)
	local Gameplay = require(game.ReplicatedStorage.Shared.Gameplay)
	local Mutations = require(game.ReplicatedStorage.Shared.Data.Mutations)

	-- Hatch weights stay strictly positive so every mutation remains reachable.
	t.test("hatch weights are positive and sum above zero", function()
		local total = 0
		for _, weight in Config.MUTATION_WEIGHTS do
			expect.truthy(weight > 0)
			total += weight
		end
		expect.truthy(total > 0)
	end)

	-- Zero bonus returns exactly the config weights.
	t.test("MutationWeights(0) matches config weights", function()
		expect.deepEqual(Gameplay.MutationWeights(0), Config.MUTATION_WEIGHTS)
	end)

	-- Bonus points go to every non-None mutation, None stays untouched.
	t.test("MutationWeights(0.1) adds ten points to each non-None mutation", function()
		local weights = Gameplay.MutationWeights(0.1)
		for mutation, weight in Config.MUTATION_WEIGHTS do
			if mutation == "None" then
				expect.equal(weights[mutation], weight)
			else
				expect.equal(weights[mutation], weight + 10)
			end
		end
	end)

	-- Long-run distribution stays near config odds and never leaves the table.
	t.test("20000 rolls stay in bounds and hit Celestial", function()
		local counts = {}
		for _ = 1, 20000 do
			local roll = Gameplay.WeightedRoll(Config.MUTATION_WEIGHTS)
			expect.truthy(roll ~= nil and Config.MUTATION_WEIGHTS[roll] ~= nil)
			counts[roll] = (counts[roll] or 0) + 1
		end
		local shadowShare = counts.Shadow / 20000
		expect.truthy(shadowShare >= 0.08 and shadowShare <= 0.12)
		expect.truthy((counts.Celestial or 0) > 0)
	end)

	-- Breed weights roll only None or mutations known to the data.
	t.test("breed weights are positive and roll known mutations", function()
		local total = 0
		for _, weight in Config.BREED_MUTATION_WEIGHTS do
			expect.truthy(weight > 0)
			total += weight
		end
		expect.truthy(total > 0)
		for _ = 1, 20000 do
			local roll = Gameplay.WeightedRoll(Config.BREED_MUTATION_WEIGHTS)
			expect.truthy(roll == "None" or Mutations[roll] ~= nil)
		end
	end)
end
