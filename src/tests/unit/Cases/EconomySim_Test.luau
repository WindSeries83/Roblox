return function(t)
	local expect = t.expect
	local ok, EconomySim = pcall(function()
		return require(game.ServerStorage.Tools.EconomySim)
	end)
	if not ok then
		EconomySim = require("src/tools/EconomySim")
	end
	local Config = require(game.ReplicatedStorage.Shared.Config)

	t.test("exécute AFK, attentif et payeur modéré sur une durée choisie", function()
		for _, profile in { "afk", "attentive", "moderate_payer" } do
			local result = EconomySim.Run("progression", {
				profileKind = profile,
				durationDays = 1,
				runs = 1,
			})
			expect.equal(result.Profile, profile)
			expect.equal(result.DurationDays, 1)
			expect.equal(result.DurationSeconds, 24 * 60 * 60)
			expect.equal(result.Results[1].DurationSeconds, result.DurationSeconds)
			expect.truthy(result.Metrics.RebirthSpeed.Modeled)
			expect.truthy(result.Metrics.EggAvailability.Modeled)
			expect.truthy(result.Metrics.LuckCap.EffectiveBonus <= Config.LUCK_HARD_CAP)
			expect.falsy(result.Metrics.Inflation.Modeled)
			expect.falsy(result.Metrics.OfflineYield.Modeled)
			expect.falsy(result.Metrics.MarketValue.Modeled)
		end
	end)

	t.test("la matrice couvre les trois profils et 1, 7, 14, 30 jours", function()
		local matrix = EconomySim.RunMatrix("progression", { runs = 1 })
		for _, profile in { "afk", "attentive", "moderate_payer" } do
			for _, days in { 1, 7, 14, 30 } do
				local result = matrix.Results[profile][days]
				expect.truthy(result ~= nil)
				expect.equal(result.Profile, profile)
				expect.equal(result.DurationDays, days)
				expect.equal(result.DurationSeconds, days * 24 * 60 * 60)
			end
		end
		expect.truthy(matrix.NonPayerProgression ~= nil)
		expect.equal(matrix.NonPayerProgression[1].Profile, "attentive")
	end)

	t.test("les caps et gates restent visibles sans activer la monétisation", function()
		local result = EconomySim.Run("progression", {
			profileKind = "moderate_payer",
			durationDays = 7,
			runs = 1,
		})
		local attentive = EconomySim.Run("progression", {
			profileKind = "attentive",
			durationDays = 7,
			runs = 1,
		})
		local luck = result.Metrics.LuckCap
		expect.equal(luck.Cap, Config.LUCK_HARD_CAP)
		expect.truthy(luck.EffectiveBonus <= luck.Cap)
		expect.truthy(result.Metrics.PaidBasket.Modeled)
		expect.equal(result.Metrics.PaidBasket.SimulationOnly, true)
		expect.equal(result.Metrics.PaidBasket.LiveActivation, false)
		expect.truthy(result.Metrics.PaidBasket.EssenceRateAfter > result.Metrics.PaidBasket.EssenceRateBefore)
		expect.equal(attentive.Metrics.PaidBasket.Modeled, false)
		expect.truthy(
			result.Metrics.PaidBasket.EssenceRateMultiplier > attentive.Metrics.PaidBasket.EssenceRateMultiplier
		)
		expect.equal(result.Metrics.PaidBasket.Items.PassiveBoost.Multiplier, Config.PASSIVE_BOOST_MULT)
		expect.equal(result.Metrics.PaidBasket.Items.VipLuck.Bonus, Config.VIP_LUCK_BONUS)
		expect.falsy(result.Metrics.PaidConversion.Modeled)
		expect.truthy(result.Metrics.PaidConversion.Reason ~= nil)
		expect.truthy(result.Metrics.EggAvailability.HighestUnlockedTier ~= nil)
	end)
end
