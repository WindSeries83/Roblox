--!strict

return function(t)
	local expect = t.expect
	local PaidRandomPolicy = require(game.ReplicatedStorage.Shared.PaidRandomPolicy)

	t.test("classifies paid random effects by product effect", function()
		expect.truthy(PaidRandomPolicy.RequiresEligibility({ Amount = 500 }))
		expect.truthy(PaidRandomPolicy.RequiresEligibility({ Kind = "LuckPotion" }))
		expect.truthy(PaidRandomPolicy.RequiresEligibility({ Kind = "Vip" }))
		expect.truthy(PaidRandomPolicy.RequiresEligibility({ Kind = "FirstOffer" }))
		expect.truthy(PaidRandomPolicy.RequiresEligibility({ Creature = { Rarity = "Rare" } }))
		expect.falsy(PaidRandomPolicy.RequiresEligibility({ Kind = "ServerBoost" }))
		expect.falsy(PaidRandomPolicy.RequiresEligibility({ Kind = "SeasonPremium" }))
	end)
end
