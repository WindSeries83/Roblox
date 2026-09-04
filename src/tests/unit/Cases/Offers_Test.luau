return function(t)
	local expect = t.expect
	local Offers = require(game.ReplicatedStorage.Shared.Offers)
	local DAY = 86400
	local required = {
		StarterBundle = true,
		LuckPotionSmall = true,
		LuckPotionBig = true,
		ServerBoost = true,
		Vip30Days = true,
		ReturnD2 = true,
		ReturnD7 = true,
		SeasonPremium = true,
	}

	t.test("catalog covers the six required offer journeys", function()
		local count = 0
		for key, offer in Offers.All do
			count += 1
			expect.truthy(required[key])
			for _, field in { "Id", "Sku", "Audience", "Trigger", "Duration", "ValueText", "PriceText", "Enabled" } do
				expect.truthy(offer[field] ~= nil)
			end
			expect.equal(offer.Enabled, false)
		end
		expect.equal(count, 8)
	end)

	t.test("commercial offers stay unavailable until a real SKU is validated", function()
		for _, offer in Offers.All do
			expect.falsy(Offers.IsAvailable(offer))
		end
		local validated = {
			Id = "Validated",
			Sku = 123,
			Audience = "All",
			Trigger = "Shop",
			Duration = 0,
			Enabled = true,
			ValueText = "Value",
			PriceText = "100 Robux",
		}
		expect.truthy(Offers.IsAvailable(validated))
		expect.falsy(Offers.IsAvailable({ Id = 0, Enabled = true, Sku = 123, ValueText = "x", PriceText = "y" }))
		expect.falsy(Offers.IsAvailable({
			Id = "Validated",
			Enabled = true,
			Sku = 123,
			Audience = "All",
			Trigger = "Shop",
			Duration = 0,
			ValueText = "x",
			PriceText = "À définir",
		}))
	end)

	t.test("visibility requires value and the server feature trigger", function()
		local offer = {
			Id = "StarterBundle",
			Sku = 123,
			Audience = "FirstHatch",
			Trigger = "AfterFirstCreature",
			Duration = 0,
			ValueText = "Pack",
			PriceText = "100 Robux",
			Enabled = true,
		}
		expect.falsy(Offers.IsVisible(offer, { Stats = { TotalHatched = 0 } }, { Shop = true }, 100))
		expect.truthy(Offers.IsVisible(offer, { Stats = { TotalHatched = 1 } }, { Shop = true }, 100))
	end)

	t.test("unvalidated catalog never reaches a visible snapshot", function()
		local visible = Offers.VisibleFor({ Stats = { TotalHatched = 10 }, Season = {} }, { Shop = true }, 100)
		for _ in visible do
			expect.falsy(true)
		end
	end)

	t.test("policy filters paid random offers by their server definitions", function()
		local catalog = {
			LuckPotionSmall = true,
			LuckPotionBig = true,
			Vip30Days = true,
			StarterBundle = true,
			ServerBoost = true,
		}
		local products = {
			LuckPotionSmall = { Kind = "LuckPotion" },
			LuckPotionBig = { Kind = "LuckPotion" },
			Vip30Days = { Kind = "Vip" },
			FirstPurchaseOffer = { Kind = "FirstOffer", Creature = { Rarity = "Rare" } },
			ServerBoostProduct = { Kind = "ServerBoost" },
		}
		local restricted =
			Offers.FilterPaidRandom(catalog, { Loaded = true, ArePaidRandomItemsRestricted = true }, products)
		for _, key in { "LuckPotionSmall", "LuckPotionBig", "Vip30Days", "StarterBundle" } do
			expect.falsy(restricted[key])
		end
		expect.truthy(restricted.ServerBoost)
		local unrestricted =
			Offers.FilterPaidRandom(catalog, { Loaded = true, ArePaidRandomItemsRestricted = false }, products)
		expect.truthy(unrestricted.LuckPotionSmall)
		expect.truthy(unrestricted.Vip30Days)
		expect.truthy(unrestricted.ServerBoost)
	end)

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
end
