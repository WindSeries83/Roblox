--!strict

return function(t)
	local expect = t.expect
	local Leaderboard = require(game.ReplicatedStorage.Shared.Leaderboard)

	t.test("free players and Starter alone stay eligible", function()
		expect.truthy(Leaderboard.IsLightEligible({ Entitlements = {}, PaidPurchases = {} }))
		expect.truthy(Leaderboard.IsLightEligible({
			Entitlements = { StarterBundle = true },
			PaidPurchases = { Pass_StarterBundle = true },
		}))
	end)

	t.test("any other paid entitlement leaves the light board", function()
		expect.falsy(Leaderboard.IsLightEligible({ Entitlements = { PassiveBoost = true } }))
		expect.falsy(Leaderboard.IsLightEligible({ PaidPurchases = { Product_123 = true } }))
	end)
end
