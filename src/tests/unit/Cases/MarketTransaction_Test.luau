return function(t)
	local expect = t.expect
	local MarketTransaction = require(game.ReplicatedStorage.Shared.MarketTransaction)

	t.test("transaction advances once through every durable state", function()
		local listing = { TransactionState = "Escrowed" }
		expect.truthy(MarketTransaction.Transition(listing, "Escrowed", "Open"))
		expect.truthy(MarketTransaction.Transition(listing, "Open", "Claimed", { SoldBy = 42 }))
		expect.falsy(MarketTransaction.Transition(listing, "Open", "Claimed"))
		expect.truthy(MarketTransaction.Transition(listing, "Claimed", "BuyerApplied"))
		expect.truthy(MarketTransaction.Transition(listing, "BuyerApplied", "SellerApplied"))
		expect.truthy(MarketTransaction.Transition(listing, "SellerApplied", "Settled"))
		expect.truthy(MarketTransaction.IsSettled(listing))
	end)

	t.test("transaction rejects skipping a durable step", function()
		local listing = { TransactionState = "Open" }
		expect.falsy(MarketTransaction.Transition(listing, "Open", "Settled"))
		expect.equal(MarketTransaction.State(listing), "Open")
	end)

	t.test("two stale buyers have one durable claim winner", function()
		local durable = { TransactionState = "Open" }
		local first = MarketTransaction.Transition(durable, "Open", "Claimed", { BuyerUserId = 10 })
		local second = MarketTransaction.Transition(durable, "Open", "Claimed", { BuyerUserId = 20 })
		expect.truthy(first)
		expect.falsy(second)
		expect.equal(durable.BuyerUserId, 10)
	end)

	t.test("seller save failure rolls back and replay credits exactly once", function()
		local listing = {
			Id = "listing-1",
			Price = 100,
			Creature = { Id = "creature-1", SpeciesId = "Riftling" },
		}
		local data = {
			Essence = 0,
			Stats = { TotalEssenceEarned = 0, MarketSales = 0 },
			LastPlayed = 7,
			MarketHistory = {},
			EconomyLedger = {},
			MarketLedger = { Credits = {} },
		}
		local grants = 0
		local function process(saveOk: boolean): boolean
			local applied, rollback = MarketTransaction.ApplySellerCredit(data, listing, 95, function()
				grants += 1
				data.Essence += 95
				data.Stats.TotalEssenceEarned += 95
				data.EconomyLedger["market-credit:listing-1"] = true
				return 95
			end)
			expect.truthy(applied)
			if not saveOk then
				if rollback then
					rollback()
				end
				return false
			end
			return true
		end

		expect.falsy(process(false))
		expect.equal(data.Essence, 0)
		expect.falsy(data.MarketLedger.Credits[listing.Id])
		expect.falsy(data.EconomyLedger["market-credit:listing-1"])
		expect.equal(#data.MarketHistory, 0)
		expect.equal(grants, 1)

		expect.truthy(process(true))
		expect.equal(data.Essence, 95)
		expect.truthy(data.MarketLedger.Credits[listing.Id])
		expect.truthy(data.EconomyLedger["market-credit:listing-1"])
		expect.equal(#data.MarketHistory, 1)
		expect.equal(grants, 2)

		local replay, rollback = MarketTransaction.ApplySellerCredit(data, listing, 95, function()
			grants += 1
			return 95
		end)
		expect.truthy(replay)
		expect.falsy(rollback)
		expect.equal(grants, 2)
		expect.equal(#data.MarketHistory, 1)
	end)

	t.test("buyer save failure rolls back debit, creature, ledger and last played", function()
		local listing = {
			Id = "listing-2",
			Creature = { Id = "creature-2", SpeciesId = "Riftling" },
		}
		local data = {
			Essence = 100,
			Creatures = {},
			LastPlayed = 19,
			MarketLedger = { Buys = {} },
		}
		local spends = 0
		local function process(saveOk: boolean): boolean
			local applied, rollback = MarketTransaction.ApplyBuyerPurchase(data, listing, function()
				spends += 1
				data.Essence -= 40
				return true
			end)
			expect.truthy(applied)
			if not saveOk then
				if rollback then
					rollback()
				end
				return false
			end
			return true
		end

		expect.falsy(process(false))
		expect.equal(data.Essence, 100)
		expect.equal(#data.Creatures, 0)
		expect.falsy(data.MarketLedger.Buys[listing.Id])
		expect.equal(data.LastPlayed, 19)

		expect.truthy(process(true))
		expect.equal(data.Essence, 60)
		expect.equal(#data.Creatures, 1)
		expect.equal(data.MarketLedger.Buys[listing.Id], "BuyerApplied")
		expect.equal(spends, 2)

		local replay, rollback = MarketTransaction.ApplyBuyerPurchase(data, listing, function()
			spends += 1
			return true
		end)
		expect.truthy(replay)
		expect.falsy(rollback)
		expect.equal(spends, 2)
		expect.equal(data.Essence, 60)
		expect.equal(#data.Creatures, 1)
	end)

	t.test("failed buyer claim can reopen only through the durable rollback transition", function()
		local listing = { TransactionState = "Claimed", BuyerUserId = 10, SoldBy = 10, ClaimedAt = 1 }
		expect.truthy(MarketTransaction.Transition(listing, "Claimed", "Open", {
			BuyerUserId = nil,
			SoldBy = nil,
			ClaimedAt = nil,
		}))
		expect.equal(MarketTransaction.State(listing), "Open")
		expect.falsy(listing.BuyerUserId)
	end)
end
