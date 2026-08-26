return function(t)
	local expect = t.expect
	local MarketService = require(game.ServerScriptService.Services.MarketService)
	local Config = require(game.ReplicatedStorage.Shared.Config)

	local function Creature(id: string, power: number)
		return { Id = id, Power = power, SpeciesId = "Riftling", Rarity = "Common", Mutation = false, Level = 1 }
	end

	local function Listing(id: string, sellerId: number, price: number, withdrawAt: number?)
		local listing = {
			Id = id,
			SellerUserId = sellerId,
			SellerName = `p{sellerId}`,
			Creature = Creature(`c_{id}`, 10),
			Price = price,
			ListedAt = 1,
		}
		if withdrawAt then
			listing.WithdrawAt = withdrawAt
		end
		return listing
	end

	t.test("ValidatePrice rejects non-integers and out of range", function()
		expect.falsy(MarketService.ValidatePrice(5.5))
		expect.falsy(MarketService.ValidatePrice("100"))
		expect.falsy(MarketService.ValidatePrice(0))
		expect.falsy(MarketService.ValidatePrice(Config.MARKET_MAX_PRICE + 1))
		expect.truthy(MarketService.ValidatePrice(10))
		expect.truthy(MarketService.ValidatePrice(Config.MARKET_MAX_PRICE))
	end)

	t.test("Payout applies fee with floor", function()
		expect.equal(MarketService.Payout(100, 0.05), 95)
		expect.equal(MarketService.Payout(10, 0.05), 9)
		expect.equal(MarketService.Payout(200, 0), 200)
	end)

	t.test("CanBuy rejects self purchase", function()
		local ok, reason = MarketService.CanBuy(Listing("l1", 1, 100), 1, {}, 1, 500)
		expect.falsy(ok)
		expect.truthy(reason)
	end)

	t.test("CanBuy rejects insufficient essence", function()
		local ok = MarketService.CanBuy(Listing("l1", 2, 100), 1, {}, 1, 50)
		expect.falsy(ok)
	end)

	t.test("CanBuy rejects when buyer sanctuary is full", function()
		local creatures = {}
		for i = 1, 10 do
			table.insert(creatures, Creature(`c{i}`, 1))
		end
		local ok = MarketService.CanBuy(Listing("l1", 2, 100), 1, creatures, 1, 500)
		expect.falsy(ok)
	end)

	t.test("CanBuy accepts valid purchase", function()
		local ok = MarketService.CanBuy(Listing("l1", 2, 100), 1, {}, 1, 500)
		expect.truthy(ok)
	end)

	t.test("CanBuy rejects listing pending withdraw", function()
		local ok = MarketService.CanBuy(Listing("l1", 2, 100, 9999), 1, {}, 1, 500)
		expect.falsy(ok)
	end)

	t.test("CanList rejects bad price and missing creature", function()
		local ok, reason = MarketService.CanList(3, Creature("c1", 10), { Creature("c1", 10) }, 0)
		expect.falsy(ok)
		expect.truthy(reason)
		ok = MarketService.CanList(100, nil, {}, 0)
		expect.falsy(ok)
	end)

	t.test("CanList rejects unowned creature", function()
		local ok = MarketService.CanList(100, Creature("c1", 10), { Creature("c2", 10) }, 0)
		expect.falsy(ok)
	end)

	t.test("CanList rejects at max listings", function()
		local ok = MarketService.CanList(100, Creature("c1", 10), { Creature("c1", 10) }, 5)
		expect.falsy(ok)
	end)

	t.test("CanList accepts valid sale", function()
		local ok = MarketService.CanList(100, Creature("c1", 10), { Creature("c1", 10) }, 0)
		expect.truthy(ok)
	end)

	t.test("CanClaim refuse listing vendu, soi-même, inexistant ; accepte sinon", function()
		expect.truthy(MarketService.CanClaim({ SellerUserId = 1, Price = 100 }, 2))
		local ok = MarketService.CanClaim({ SellerUserId = 2 }, 2)
		expect.falsy(ok)
		local ok2 = MarketService.CanClaim({ SellerUserId = 1, SoldAt = os.time() }, 2)
		expect.falsy(ok2)
		expect.falsy(MarketService.CanClaim(nil, 2))
		local ok3 = MarketService.CanClaim({ SellerUserId = 1, WithdrawAt = os.time() + 60 }, 2)
		expect.falsy(ok3)
	end)
end
