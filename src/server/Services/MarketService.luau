local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Net = require(ReplicatedStorage.Shared.Net)
local Sanctuary = require(ReplicatedStorage.Shared.Sanctuary)

local MarketService = {}

local log
local saveService
local essenceService
local dataSync

local ListingsKey = "Listings"

local Store
local storeOk = pcall(function()
	Store = DataStoreService:GetDataStore("RiftBeastsMarket_v1")
end)
if not storeOk then
	Store = {
		GetAsync = function()
			return nil
		end,
		SetAsync = function() end,
	}
end

local listings: { [string]: any } = {}
local pendingCredits: { [number]: number } = {}
local cooldowns: { [Player]: { [string]: number } } = {}

local function ListedCount(player: Player): number
	local count = 0
	for _, listing in listings do
		if listing.SellerUserId == player.UserId then
			count += 1
		end
	end
	return count
end

--[[ Pure logic (unit-testable) ]]

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
		return false, "Tu ne peux pas acheter ta propre créature"
	end
	if listing.WithdrawAt then
		return false, "Retrait en cours"
	end
	if essence < listing.Price then
		return false, "Essence insuffisante"
	end
	if #buyerCreatures >= Sanctuary.MaxCreatures(sanctuaryLevel, bonusSlots) then
		return false, "Sanctuaire plein"
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
		return false, "Créature introuvable"
	end
	if listedCount >= Config.MARKET_MAX_LISTINGS then
		return false, "Nombre de ventes maximum atteint"
	end
	if not Gameplay.FindCreature(playerCreatures, creature.Id) then
		return false, "Créature introuvable"
	end
	return true
end

--[[ Persistence (best-effort, cache mémoire source de vérité de session) ]]

local function PersistListings()
	local snapshot = {}
	for _, listing in listings do
		table.insert(snapshot, listing)
	end
	pcall(function()
		Store:SetAsync(ListingsKey, snapshot)
	end)
end

local function LoadListings()
	local ok, data = pcall(function()
		return Store:GetAsync(ListingsKey)
	end)
	if ok and type(data) == "table" then
		for _, listing in data do
			if type(listing.Id) == "string" then
				listings[listing.Id] = listing
			end
		end
	end
end

local function PersistPending(userId: number)
	pcall(function()
		Store:SetAsync(`Pending_{userId}`, pendingCredits[userId] or 0)
	end)
end

local function LoadPending(userId: number)
	local ok, amount = pcall(function()
		return Store:GetAsync(`Pending_{userId}`)
	end)
	if ok and type(amount) == "number" and amount > 0 then
		pendingCredits[userId] = amount
	end
end

--[[ Sync ]]

local function ListingsPayload(): { any }
	local list = {}
	for _, listing in listings do
		table.insert(list, listing)
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

local function CreditSeller(listing: any)
	local seller = Players:GetPlayerByUserId(listing.SellerUserId)
	local payout = MarketService.Payout(listing.Price)
	if seller then
		essenceService:Add(seller, payout, `MarketSale_{listing.Id}`)
		local profile = saveService:GetProfile(seller)
		if profile then
			profile.Data.Stats.MarketSales += 1
			table.insert(profile.Data.MarketHistory, {
				CreatureId = listing.Creature.Id,
				SpeciesId = listing.Creature.SpeciesId,
				Price = listing.Price,
				Payout = payout,
				SoldAt = os.time(),
			})
		end
		dataSync:Send(seller)
	else
		pendingCredits[listing.SellerUserId] = (pendingCredits[listing.SellerUserId] or 0) + payout
		PersistPending(listing.SellerUserId)
	end
end

--[[ Remotes ]]

local function OnMarketList(player: Player, creatureId: any, price: any)
	if not Gameplay.CheckCooldown(cooldowns, player, "List", Config.MARKET_COOLDOWN) then
		return
	end
	if typeof(creatureId) ~= "string" then
		return
	end
	local profile = saveService:GetProfile(player)
	if not profile then
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
			log:Economy("Market", "ListRejected", { Player = player.Name, Reason = "Déjà en vente" })
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
	}
	listings[listing.Id] = listing
	PersistListings()

	for i, owned in profile.Data.Creatures do
		if owned.Id == creatureId then
			table.remove(profile.Data.Creatures, i)
			break
		end
	end
	profile.Data.LastPlayed = os.time()
	dataSync:Send(player)

	log:Economy("Market", "List", {
		Player = player.Name,
		Listing = listing.Id,
		Creature = creature.Id,
		Species = creature.SpeciesId,
		Price = price,
	})
	BroadcastListings()
end

local function OnMarketBuy(player: Player, listingId: any)
	if not Gameplay.CheckCooldown(cooldowns, player, "Buy", Config.MARKET_COOLDOWN) then
		return
	end
	if typeof(listingId) ~= "string" then
		return
	end
	local profile = saveService:GetProfile(player)
	if not profile then
		return
	end
	local listing = listings[listingId]
	local bonusSlots = if profile.Data.Entitlements.MoreSlots then 2 else 0
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

	if not essenceService:Spend(player, listing.Price, `MarketBuy_{listing.Id}`) then
		return
	end
	listings[listing.Id] = nil
	PersistListings()

	table.insert(profile.Data.Creatures, listing.Creature)
	profile.Data.LastPlayed = os.time()
	dataSync:Send(player)
	CreditSeller(listing)

	log:Economy("Market", "Buy", {
		Player = player.Name,
		Listing = listing.Id,
		Seller = listing.SellerName,
		Species = listing.Creature.SpeciesId,
		Price = listing.Price,
	})
	BroadcastListings()
end

local function OnMarketRemove(player: Player, listingId: any)
	if not Gameplay.CheckCooldown(cooldowns, player, "Remove", Config.MARKET_COOLDOWN) then
		return
	end
	if typeof(listingId) ~= "string" then
		return
	end
	local profile = saveService:GetProfile(player)
	if not profile then
		return
	end
	local listing = listings[listingId]
	if not listing or listing.SellerUserId ~= player.UserId then
		return
	end

	if not listing.WithdrawAt then
		listing.WithdrawAt = os.time() + Config.MARKET_WITHDRAW_DELAY
		PersistListings()
		BroadcastListings()
		return
	end
	if os.time() < listing.WithdrawAt then
		return
	end

	listings[listing.Id] = nil
	PersistListings()
	table.insert(profile.Data.Creatures, listing.Creature)
	profile.Data.LastPlayed = os.time()
	dataSync:Send(player)

	log:Economy("Market", "Withdraw", {
		Player = player.Name,
		Listing = listing.Id,
		Creature = listing.Creature.Id,
	})
	BroadcastListings()
end

local function OnMarketListings(player: Player)
	if not Gameplay.CheckCooldown(cooldowns, player, "Query", Config.MARKET_QUERY_COOLDOWN) then
		return
	end
	Net.MarketSync:FireClient(player, { Listings = ListingsPayload() })
end

--[[ Lifecycle ]]

function MarketService:Init(container)
	log = container:Get("Log")
	saveService = container:Get("SaveService")
	essenceService = container:Get("EssenceService")
	dataSync = container:Get("DataSync")
end

function MarketService:Start()
	LoadListings()

	for _, player in Players:GetPlayers() do
		LoadPending(player.UserId)
	end
	Players.PlayerAdded:Connect(function(player)
		task.defer(function()
			local userId = player.UserId
			LoadPending(userId)
			local amount = pendingCredits[userId] or 0
			if amount > 0 then
				pendingCredits[userId] = nil
				PersistPending(userId)
				essenceService:Add(player, amount, "MarketPending")
				dataSync:Send(player)
				log:Economy("Market", "PendingCredit", { Player = player.Name, Amount = amount })
			end
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		cooldowns[player] = nil
	end)

	Net.MarketList.OnServerEvent:Connect(OnMarketList)
	Net.MarketBuy.OnServerEvent:Connect(OnMarketBuy)
	Net.MarketRemove.OnServerEvent:Connect(OnMarketRemove)
	Net.MarketListings.OnServerEvent:Connect(OnMarketListings)
end

return MarketService
