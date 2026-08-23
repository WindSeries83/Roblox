return function(t)
	local expect = t.expect
	local Offers = require(game.ReplicatedStorage.Shared.Offers)
	local DAY = 86400

	t.test("return day thresholds", function()
		expect.equal(Offers.ReturnDay(0), nil)
		expect.equal(Offers.ReturnDay(DAY - 1), nil)
		expect.equal(Offers.ReturnDay(DAY), "D2")
		expect.equal(Offers.ReturnDay(6 * DAY - 1), "D2")
		expect.equal(Offers.ReturnDay(6 * DAY), "D7")
	end)

	t.test("return gift due once per day-key", function()
		local data = { Offers = { ReturnGifts = {} } }
		expect.truthy(Offers.ReturnGiftDue(data, "D2"))
		data.Offers.ReturnGifts.D2 = true
		expect.falsy(Offers.ReturnGiftDue(data, "D2"))
		expect.truthy(Offers.ReturnGiftDue(data, "D7"))
	end)

	t.test("first purchase eligibility", function()
		local fresh = { LastPlayed = 0, Offers = {} }
		expect.falsy(Offers.FirstPurchaseEligible(fresh))

		local flagged = { LastPlayed = os.time(), Offers = { FirstPurchaseEligible = true } }
		expect.truthy(Offers.FirstPurchaseEligible(flagged))

		local returning = { LastPlayed = os.time() - 2 * DAY, Offers = {} }
		expect.truthy(Offers.FirstPurchaseEligible(returning))

		flagged.Offers.FirstPurchaseClaimed = true
		expect.falsy(Offers.FirstPurchaseEligible(flagged))
	end)
end
