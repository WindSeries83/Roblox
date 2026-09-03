--!strict

local MarketTransaction = {}

MarketTransaction.STATES = {
	Escrowed = "Escrowed",
	Open = "Open",
	Claimed = "Claimed",
	BuyerApplied = "BuyerApplied",
	SellerApplied = "SellerApplied",
	Settled = "Settled",
}

function MarketTransaction.ApplySellerCredit(
	data: any,
	listing: any,
	payout: number,
	grant: () -> number
): (boolean, (() -> ())?)
	local marketLedger = data.MarketLedger
	local credits = marketLedger.Credits
	local economyLedger = data.EconomyLedger or {}
	data.EconomyLedger = economyLedger
	local transactionId = listing.Id
	if credits[transactionId] then
		return true, nil
	end

	local ledgerKey = `market-credit:{transactionId}`
	local hadGrant = economyLedger[ledgerKey] == true
	local previousEssence = data.Essence
	local previousTotalEarned = data.Stats.TotalEssenceEarned
	local previousMarketSales = data.Stats.MarketSales
	local previousLastPlayed = data.LastPlayed
	local previousCredit = credits[transactionId]
	local previousGrant = economyLedger[ledgerKey]
	local history = data.MarketHistory

	if not hadGrant and grant() <= 0 then
		return false, nil
	end

	credits[transactionId] = true
	data.Stats.MarketSales += 1
	local historyEntry = {
		TransactionId = transactionId,
		CreatureId = listing.Creature.Id,
		SpeciesId = listing.Creature.SpeciesId,
		Price = listing.Price,
		Payout = payout,
		SoldAt = os.time(),
	}
	table.insert(history, historyEntry)

	local rolledBack = false
	return true,
		function()
			if rolledBack then
				return
			end
			rolledBack = true
			credits[transactionId] = previousCredit
			economyLedger[ledgerKey] = previousGrant
			data.Essence = previousEssence
			data.Stats.TotalEssenceEarned = previousTotalEarned
			data.Stats.MarketSales = previousMarketSales
			data.LastPlayed = previousLastPlayed
			local index = table.find(history, historyEntry)
			if index then
				table.remove(history, index)
			end
		end
end

function MarketTransaction.ApplyBuyerPurchase(data: any, listing: any, spend: () -> boolean): (boolean, (() -> ())?)
	local buys = data.MarketLedger.Buys
	local transactionId = listing.Id
	if buys[transactionId] == "BuyerApplied" then
		return true, nil
	end
	if buys[transactionId] ~= nil then
		return false, nil
	end

	local previousEssence = data.Essence
	local previousLastPlayed = data.LastPlayed
	if not spend() then
		return false, nil
	end

	local creature = listing.Creature
	table.insert(data.Creatures, creature)
	buys[transactionId] = "BuyerApplied"
	local appliedLastPlayed = os.time()
	data.LastPlayed = appliedLastPlayed
	local spent = math.max(0, previousEssence - data.Essence)
	local rolledBack = false
	return true,
		function()
			if rolledBack then
				return
			end
			rolledBack = true
			if buys[transactionId] == "BuyerApplied" then
				buys[transactionId] = nil
			end
			for index = #data.Creatures, 1, -1 do
				if data.Creatures[index] == creature then
					table.remove(data.Creatures, index)
					break
				end
			end
			data.Essence += spent
			if data.LastPlayed == appliedLastPlayed then
				data.LastPlayed = previousLastPlayed
			end
		end
end

local NEXT = {
	Escrowed = { Open = true },
	Open = { Claimed = true },
	Claimed = { Open = true, BuyerApplied = true },
	BuyerApplied = { SellerApplied = true },
	SellerApplied = { Settled = true },
}

function MarketTransaction.State(listing: any): string
	return listing.TransactionState
		or if listing.SettledAt then "Settled" else if listing.SoldAt then "Claimed" else "Open"
end

function MarketTransaction.Transition(listing: any, expected: string, next: string, fields: { [string]: any }?): boolean
	if MarketTransaction.State(listing) ~= expected then
		return false
	end
	if expected ~= next and not (NEXT[expected] and NEXT[expected][next]) then
		return false
	end
	listing.TransactionState = next
	if expected == "Claimed" and next == "Open" then
		listing.BuyerUserId = nil
		listing.SoldBy = nil
		listing.ClaimedAt = nil
		listing.BuyerAppliedAt = nil
	end
	if fields then
		for key, value in fields do
			listing[key] = value
		end
	end
	return true
end

function MarketTransaction.IsSettled(listing: any): boolean
	return MarketTransaction.State(listing) == "Settled"
end

return MarketTransaction
