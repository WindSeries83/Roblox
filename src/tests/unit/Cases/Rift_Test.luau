return function(t)
	local expect = t.expect
	local Config = require(game.ReplicatedStorage.Shared.Config)

	t.test("relique en défaite = 25 % du taux victoire", function()
		for _, tier in { "T1", "T2", "T3" } do
			expect.near(Config.RIFT_RELIC_WEIGHTS_DEFEAT[tier], Config.RIFT_RELIC_WEIGHTS[tier] * 0.25, 0.01)
		end
	end)

	t.test("cooldown de réentrée présent et positif", function()
		expect.truthy(Config.RIFT_REENTRY_COOLDOWN >= 1)
	end)
end
