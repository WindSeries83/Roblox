--!strict

local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local MarketTransaction = require(ReplicatedStorage.Shared.MarketTransaction)
local Net = require(ReplicatedStorage.Shared.Net)
local Sanctuary = require(ReplicatedStorage.Shared.Sanctuary)
local SafeStore = require(script.Parent.SafeStore)

local MarketService = {}

local log
local saveService
local essenceService
local dataSync
local policyService
local analyticsService

local Store = SafeStore.Get("RiftBeastsMarket_v1", nil)
local listings: { [string]: any } = {}
local cooldowns: { [Player]: { [string]: number } } = {}
local lastAppliedAt = 0

local function ListedCount(player: Player): number
	local count = 0
	for _, listing in listings do
		if listing.SellerUserId == player.UserId then
			count += 1
		end
	end
	return count
end

function MarketService.ValidatePrice(price: any): boolean
	return type(price) == "number"
		and price == price
		and math.floor(price) == price
		and price >= Config.MARKET_MIN_PRICE
		and price <= Config.MARKET_MAX_PRICE
end

function MarketService.Payout(price: number, fee: number?): number
	return math.floor(price * (1 - (fee or Config.MARKET_FEE)))
end

function MarketService.CanBuy(
	listing: any,
	buyerUserId: number,
	buyerCreatures: { any },
	sanctuaryLevel: number,
	essence: number,
	bonusSlots: number?
): (boolean, string?)
	if not listing then
		return false, "Listing introuvable"
	end
	if listing.SellerUserId == buyerUserId then
		return false, "Tu ne peux pas acheter ta propre creature"
	end
	if MarketTransaction.State(listing) ~= "Open" or listing.WithdrawAt then
		return false, "Listing indisponible"
	end
	if essence < listing.Price then
		return false, "Essence insuffisante"
	end
	if #buyerCreatures >= Sanctuary.MaxCreatures(sanctuaryLevel, bonusSlots) then
		return false, "Sanctuaire plein"
	end
	return true
end

function MarketService.CanClaim(listing: any, buyerUserId: number): (boolean, string?)
	if not listing then
		return false, "Listing introuvable"
	end
	if listing.SellerUserId == buyerUserId then
		return false, "Tu ne peux pas acheter ta propre creature"
	end
	if MarketTransaction.State(listing) ~= "Open" or listing.WithdrawAt then
		return false, "Listing indisponible"
	end
	return true
end

function MarketService.CanList(
	price: any,
	creature: any,
	playerCreatures: { any },
	listedCount: number
): (boolean, string?)
	if not MarketService.ValidatePrice(price) then
		return false, "Prix invalide"
	end
	if not creature then
		return false, "Creature introuvable"
	end
	if listedCount >= Config.MARKET_MAX_LISTINGS then
		return false, "Nombre de ventes maximum atteint"
	end
	if not Gameplay.FindCreature(playerCreatures, creature.Id) then
		return false, "Creature introuvable"
	end
	return true
end

local function NotifyServers()
	if not RunService:IsStudio() then
		pcall(function()
			MessagingService:PublishAsync(Config.MARKET_TOPIC, { UpdatedAt = os.time() })
		end)
	end
end

local function UpdateIndex(id: string, add: boolean): boolean
	local ok = pcall(function()
		Store:UpdateAsync("Index", function(old)
			local ids = if type(old) == "table" and type(old.Ids) == "table" then table.clone(old.Ids) else {}
			local pos = table.find(ids, id)
			if add and not pos then
				table.insert(ids, id)
			elseif not add and pos then
				table.remove(ids, pos)
			end
			return { Ids = ids }
		end)
	end)
	if ok then
		NotifyServers()
	end
	return ok
end

local function PersistListing(listing: any): boolean
	local ok = pcall(function()
		Store:SetAsync(`Listing_{listing.Id}`, listing)
	end)
	return ok and UpdateIndex(listing.Id, true)
end

local function RemoveListing(id: string): boolean
	local ok = pcall(function()
		Store:RemoveAsync(`Listing_{id}`)
	end)
	return ok and UpdateIndex(id, false)
end

local function AdvanceListing(id: string, expected: string, next: string, fields: { [string]: any }?): any?
	local updated
	local ok = pcall(function()
		updated = Store:UpdateAsync(`Listing_{id}`, function(old)
			if type(old) ~= "table" or not MarketTransaction.Transition(old, expected, next, fields) then
				return nil
			end
			return old
		end)
	end)
	if not ok or type(updated) ~= "table" or MarketTransaction.State(updated) ~= next then
		return nil
	end
	listings[id] = updated
	return updated
end

local function LoadListings(replace: boolean?)
	if replace then
		table.clear(listings)
	end
	local index
	pcall(function()
		index = Store:GetAsync("Index")
	end)
	local ids = if type(index) == "table" and type(index.Ids) == "table" then index.Ids else {}
	for _, id in ids do
		local data
		pcall(function()
			data = Store:GetAsync(`Listing_{id}`)
		end)
		if type(data) == "table" and type(data.Id) == "string" and not MarketTransaction.IsSettled(data) then
			if MarketTransaction.State(data) ~= "Escrowed" then
				listings[data.Id] = data
			end
		end
	end
end

local function ListingsPayload(): { any }
	local list = {}
	for _, listing in listings do
		if MarketTransaction.State(listing) == "Open" then
			table.insert(list, listing)
		end
	end
	table.sort(list, function(a, b)
		return a.ListedAt > b.ListedAt
	end)
	local payload = {}
	for i = 1, math.min(Config.MARKET_LIST_LIMIT, #list) do
		payload[i] = list[i]
	end
	return payload
end

local function BroadcastListings()
	Net.MarketSync:FireAllClients({ Listings = ListingsPayload() })
end

local function CreditSeller(listing: any): boolean
	local payout = MarketService.Payout(listing.Price, Config.MARKET_FEE)
	local seller = Players:GetPlayerByUserId(listing.SellerUserId)
	local sellerProfile = if seller then saveService:GetProfile(seller) else nil
	if seller and sellerProfile then
		local applied, rollback = MarketTransaction.ApplySellerCredit(sellerProfile.Data, listing, payout, function()
			return essenceService:AddOnce(seller, payout, `MarketSale_{listing.Id}`, `market-credit:{listing.Id}`)
		end)
		if not applied then
			return false
		end
		sellerProfile.Data.LastPlayed = os.time()
		local saved = saveService:SaveProfile(seller, function(data)
			return data.MarketLedger and data.MarketLedger.Credits[listing.Id] == true
		end)
		if not saved then
			if rollback then
				rollback()
			end
			return false
		end
		dataSync:Send(seller)
		return true
	end
	return saveService:QueueProfileMessage(listing.SellerUserId, {
		Type = "MarketCredit",
		TransactionId = listing.Id,
		Payout = payout,
	})
end

local function SettleBuyerApplied(listing: any): boolean
	if MarketTransaction.State(listing) ~= "BuyerApplied" then
		return MarketTransaction.State(listing) == "Settled"
	end
	local settled = CreditSeller(listing)
	if not settled then
		return false
	end
	if not AdvanceListing(listing.Id, "BuyerApplied", "SellerApplied", { SellerAppliedAt = os.time() }) then
		return false
	end
	if not AdvanceListing(listing.Id, "SellerApplied", "Settled", { SettledAt = os.time() }) then
		return false
	end
	listings[listing.Id] = nil
	RemoveListing(listing.Id)
	local buyer = Players:GetPlayerByUserId(listing.BuyerUserId or listing.SoldBy)
	analyticsService:Event("market_sale", {
		ListingId = listing.Id,
		Price = listing.Price,
		Payout = MarketService.Payout(listing.Price, Config.MARKET_FEE),
		SellerUserId = listing.SellerUserId,
	}, buyer)
	return true
end

local function ReopenClaim(id: string): any?
	return AdvanceListing(id, "Claimed", "Open", {
		BuyerUserId = nil,
		SoldBy = nil,
		ClaimedAt = nil,
		BuyerAppliedAt = nil,
	})
end

local function OnMarketList(player: Player, creatureId: any, price: any)
	if not Config.MARKET_ENABLED or not Gameplay.CheckCooldown(cooldowns, player, "List", Config.MARKET_COOLDOWN) then
		return
	end
	if typeof(creatureId) ~= "string" then
		return
	end
	local profile = saveService:GetProfile(player)
	if not profile or not policyService:CanTradePaidItems(player) then
		return
	end
	local creature = Gameplay.FindCreature(profile.Data.Creatures, creatureId)
	local ok, reason = MarketService.CanList(price, creature, profile.Data.Creatures, ListedCount(player))
	if not ok then
		log:Economy("Market", "ListRejected", { Player = player.Name, Reason = reason })
		return
	end
	for _, listing in listings do
		if listing.SellerUserId == player.UserId and listing.Creature.Id == creatureId then
			return
		end
	end
	local listing = {
		Id = HttpService:GenerateGUID(false),
		SellerUserId = player.UserId,
		SellerName = player.Name,
		Creature = creature,
		Price = price,
		ListedAt = os.time(),
		TransactionState = "Escrowed",
	}
	if not PersistListing(listing) then
		return
	end
	profile.Data.MarketLedger.Listings[listing.Id] = true
	for i, owned in profile.Data.Creatures do
		if owned.Id == creatureId then
			table.remove(profile.Data.Creatures, i)
			break
		end
	end
	if profile.Data.CompanionId == creatureId then
		profile.Data.CompanionId = nil
	end
	profile.Data.LastPlayed = os.time()
	if
		not saveService:SaveProfile(player, function(data)
			return data.MarketLedger and data.MarketLedger.Listings[listing.Id] == true
		end)
	then
		table.insert(profile.Data.Creatures, creature)
		profile.Data.MarketLedger.Listings[listing.Id] = nil
		RemoveListing(listing.Id)
		return
	end
	local opened = AdvanceListing(listing.Id, "Escrowed", "Open")
	if opened then
		listings[listing.Id] = opened
		dataSync:Send(player)
		BroadcastListings()
	end
end

local function OnMarketBuy(player: Player, listingId: any)
	if not Config.MARKET_ENABLED or not Gameplay.CheckCooldown(cooldowns, player, "Buy", Config.MARKET_COOLDOWN) then
		return
	end
	if typeof(listingId) ~= "string" then
		return
	end
	local profile = saveService:GetProfile(player)
	local listing = listings[listingId]
	if not profile or not listing or not policyService:CanTradePaidItems(player) then
		return
	end
	local bonusSlots = if profile.Data.Entitlements.MoreSlots then Config.GAMEPASSES.MoreSlots.BonusSlots else 0
	local ok, reason = MarketService.CanBuy(
		listing,
		player.UserId,
		profile.Data.Creatures,
		profile.Data.SanctuaryLevel,
		profile.Data.Essence,
		bonusSlots
	)
	if not ok then
		log:Economy("Market", "BuyRejected", { Player = player.Name, Reason = reason })
		return
	end
	local claimed = AdvanceListing(listingId, "Open", "Claimed", {
		BuyerUserId = player.UserId,
		SoldBy = player.UserId,
		ClaimedAt = os.time(),
	})
	if not claimed then
		LoadListings(true)
		BroadcastListings()
		return
	end
	local previousBuyState = profile.Data.MarketLedger.Buys[claimed.Id]
	local applied, rollback = MarketTransaction.ApplyBuyerPurchase(profile.Data, claimed, function()
		return essenceService:Spend(player, claimed.Price, `MarketBuy_{claimed.Id}`)
	end)
	if not applied then
		if previousBuyState == nil then
			ReopenClaim(claimed.Id)
		end
		return
	end
	if
		not saveService:SaveProfile(player, function(data)
			return data.MarketLedger and data.MarketLedger.Buys[claimed.Id] == "BuyerApplied"
		end)
	then
		if rollback then
			rollback()
		end
		local rollbackSaved = saveService:SaveProfile(player, function(data)
			return data.MarketLedger and data.MarketLedger.Buys[claimed.Id] == nil
		end)
		if rollbackSaved then
			ReopenClaim(claimed.Id)
			BroadcastListings()
		end
		return
	end
	dataSync:Send(player)
	local buyerApplied = AdvanceListing(claimed.Id, "Claimed", "BuyerApplied", { BuyerAppliedAt = os.time() })
	if buyerApplied then
		SettleBuyerApplied(buyerApplied)
	end
	BroadcastListings()
end

local function OnMarketRemove(player: Player, listingId: any)
	if not Config.MARKET_ENABLED or not Gameplay.CheckCooldown(cooldowns, player, "Remove", Config.MARKET_COOLDOWN) then
		return
	end
	if typeof(listingId) ~= "string" then
		return
	end
	local profile = saveService:GetProfile(player)
	local listing = listings[listingId]
	if not profile or not listing or listing.SellerUserId ~= player.UserId then
		return
	end
	if MarketTransaction.State(listing) ~= "Open" then
		return
	end
	if not listing.WithdrawAt then
		local pending =
			AdvanceListing(listing.Id, "Open", "Open", { WithdrawAt = os.time() + Config.MARKET_WITHDRAW_DELAY })
		if pending then
			BroadcastListings()
		end
		return
	end
	if os.time() < listing.WithdrawAt then
		return
	end
	if not profile.Data.MarketLedger.Listings[listing.Id] then
		return
	end
	profile.Data.MarketLedger.Listings[listing.Id] = nil
	table.insert(profile.Data.Creatures, listing.Creature)
	profile.Data.LastPlayed = os.time()
	if
		not saveService:SaveProfile(player, function(data)
			return data.MarketLedger and data.MarketLedger.Listings[listing.Id] == nil
		end)
	then
		return
	end
	listings[listing.Id] = nil
	RemoveListing(listing.Id)
	dataSync:Send(player)
	BroadcastListings()
end

function MarketService:Init(container)
	log = container:Get("Log")
	saveService = container:Get("SaveService")
	essenceService = container:Get("EssenceService")
	dataSync = container:Get("DataSync")
	policyService = container:Get("PolicyService")
	analyticsService = container:Get("AnalyticsService")
end

function MarketService:Start()
	LoadListings()
	if not RunService:IsStudio() then
		pcall(function()
			MessagingService:SubscribeAsync(Config.MARKET_TOPIC, function(message)
				local data = message.Data
				if type(data) == "table" and type(data.UpdatedAt) == "number" and data.UpdatedAt > lastAppliedAt then
					lastAppliedAt = data.UpdatedAt
					LoadListings(true)
					BroadcastListings()
				end
			end)
		end)
	end
	task.spawn(function()
		while true do
			task.wait(60)
			for _, listing in listings do
				local state = MarketTransaction.State(listing)
				if state == "Claimed" and os.time() - (listing.ClaimedAt or os.time()) >= 120 then
					local buyer = Players:GetPlayerByUserId(listing.BuyerUserId or listing.SoldBy)
					local buyerProfile = if buyer then saveService:GetProfile(buyer) else nil
					if buyerProfile then
						if buyerProfile.Data.MarketLedger.Buys[listing.Id] == "BuyerApplied" then
							local applied =
								AdvanceListing(listing.Id, "Claimed", "BuyerApplied", { BuyerAppliedAt = os.time() })
							if applied then
								SettleBuyerApplied(applied)
							end
						elseif buyerProfile.Data.MarketLedger.Buys[listing.Id] == nil then
							local rollbackSaved = saveService:SaveProfile(buyer, function(data)
								return data.MarketLedger and data.MarketLedger.Buys[listing.Id] == nil
							end)
							if rollbackSaved then
								ReopenClaim(listing.Id)
							end
						end
					end
				elseif state == "BuyerApplied" then
					SettleBuyerApplied(listing)
				end
			end
			LoadListings(true)
			BroadcastListings()
		end
	end)
	Players.PlayerAdded:Connect(function(player)
		task.defer(function()
			local profile = saveService:GetProfile(player)
			if profile then
				for id in profile.Data.MarketLedger.Listings do
					local opened = AdvanceListing(id, "Escrowed", "Open")
					if opened then
						listings[id] = opened
					end
				end
				BroadcastListings()
			end
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		cooldowns[player] = nil
	end)
	Net.MarketList.OnServerEvent:Connect(OnMarketList)
	Net.MarketBuy.OnServerEvent:Connect(OnMarketBuy)
	Net.MarketRemove.OnServerEvent:Connect(OnMarketRemove)
	Net.MarketListings.OnServerEvent:Connect(function(player)
		if
			Config.MARKET_ENABLED and Gameplay.CheckCooldown(cooldowns, player, "Query", Config.MARKET_QUERY_COOLDOWN)
		then
			Net.MarketSync:FireClient(player, { Listings = ListingsPayload() })
		end
	end)
end

return MarketService
