return function(t)
	local expect = t.expect
	local DuelSim = require(game.ReplicatedStorage.Shared.DuelSim)

	local function Creature(id: string, power: number)
		return { Id = id, Power = power }
	end

	t.test("TeamPower sums creature power", function()
		expect.equal(DuelSim.TeamPower({ Creature("a", 10), Creature("b", 5) }), 15)
		expect.equal(DuelSim.TeamPower({}), 0)
	end)

	t.test("Resolve is deterministic for a given seed", function()
		local a = DuelSim.Resolve(100, 50, 12345)
		local b = DuelSim.Resolve(100, 50, 12345)
		expect.equal(a, b)
	end)

	t.test("Resolve always loses with zero attack power", function()
		expect.falsy(DuelSim.Resolve(0, 50, 1))
		expect.falsy(DuelSim.Resolve(0, 0, 1))
	end)

	t.test("Resolve favors the stronger side across seeds", function()
		local strongWins = 0
		local weakWins = 0
		for seed = 1, 100 do
			if DuelSim.Resolve(90, 10, seed) then
				strongWins += 1
			else
				weakWins += 1
			end
		end
		expect.truthy(strongWins > weakWins)
		expect.truthy(weakWins > 0, "upset possible")
	end)

	t.test("Resolve is 50/50 for equal power", function()
		local wins = 0
		local total = 200
		for seed = 1, total do
			if DuelSim.Resolve(50, 50, seed) then
				wins += 1
			end
		end
		expect.near(wins / total, 0.5, 0.15)
	end)
end
