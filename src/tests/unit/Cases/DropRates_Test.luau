return function(t)
	local expect = t.expect
	local Config = require(game.ReplicatedStorage.Shared.Config)
	local Gameplay = require(game.ReplicatedStorage.Shared.Gameplay)

	t.test("percentages sum to 100 within tolerance", function()
		local total = 0
		for _, rate in Gameplay.DropRates(Config.EGG_RARITY_WEIGHTS.CommonEgg) do
			total += rate.Percent
		end
		expect.near(total, 100, 0.05)
	end)

	t.test("rates are sorted descending", function()
		local rates = Gameplay.DropRates(Config.EGG_RARITY_WEIGHTS.CommonEgg)
		expect.truthy(#rates > 1)
		for i = 2, #rates do
			expect.truthy(rates[i - 1].Percent >= rates[i].Percent)
		end
	end)

	t.test("single weight yields one entry at 100 percent", function()
		local rates = Gameplay.DropRates({ A = 1 })
		expect.equal(#rates, 1)
		expect.equal(rates[1].Id, "A")
		expect.equal(rates[1].Percent, 100)
	end)

	t.test("equal thirds round to 33.33 each", function()
		local rates = Gameplay.DropRates({ A = 1, B = 1, C = 1 })
		expect.equal(#rates, 3)
		local total = 0
		for _, rate in rates do
			expect.equal(rate.Percent, 33.33)
			total += rate.Percent
		end
		expect.near(total, 99.99, 0.05)
	end)

	t.test("empty or nil weights yield an empty table", function()
		expect.deepEqual(Gameplay.DropRates({}), {})
		expect.deepEqual(Gameplay.DropRates(nil), {})
	end)
end
