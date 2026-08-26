local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Net = require(ReplicatedStorage.Shared.Net)
local Sanctuary = require(ReplicatedStorage.Shared.Sanctuary)
local SafeStore = require(script.Parent.SafeStore)

local MarketService = {}

local log
local saveService
local essenceService
local dataSync
local skillService
local analyticsService

local ListingsKey = "Listings"

local Store = SafeStore.Get("RiftBeastsMarket_v1", nil)

local listings: { [string]: any } = {}
local pendingCredits: { [number]: number } = {}
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

function MarketService.CanClaim(listing: any, buyerUserId: number): (boolean, string?)
	if not listing then
		return false, "Listing introuvable"
	end
	if listing.SellerUserId == buyerUserId then
		return false, "Tu ne peux pas acheter ta propre créature"
	end
	if listing.SoldAt then
		return false, "Déjà vendu"
	end
	if listing.WithdrawAt then
		return false, "Retrait en cours"
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

--[[ Persistance par-listing (DataStore source de vérité) ]]

local function notifyOtherServers()
	-- propagation live aux autres serveurs (guard Studio : PublishAsync bloque non publié)
	if not RunService:IsStudio() then
		pcall(function()
			MessagingService:PublishAsync(Config.MARKET_TOPIC, { UpdatedAt = os.time() })
		end)
	end
end

-- UpdateAsync : read-modify-write atomique cross-serveur (GetAsync+SetAsync écraserait les ajouts concurrents).
local function UpdateIndex(id: string, add: boolean)
	pcall(function()
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
	notifyOtherServers()
end

local function PersistListing(listing: any)
	pcall(function()
		Store:SetAsync(`Listing_{listing.Id}`, listing)
	end)
	UpdateIndex(listing.Id, true)
end

local function RemoveListing(id: string)
	pcall(function()
		-- SetAsync(key, nil) ne supprime pas sur le DataStore réel (tombstone requis).
		Store:RemoveAsync(`Listing_{id}`)
	end)
	UpdateIndex(id, false)
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
		if type(data) == "table" and type(data.Id) == "string" and not data.SettledAt then
			listings[data.Id] = data
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
	local sellerProfile = if seller then saveService:GetProfile(seller) else nil
	local eff = if sellerProfile then skillService:EffectsOf(sellerProfile) else {}
	local payout = MarketService.Payout(listing.Price, math.max(0, Config.MARKET_FEE - (eff.MarketFeeReduction or 0)))
	analyticsService:Event("market_sale", { Price = listing.Price })
	if seller then
		essenceService:Add(seller, payout, `MarketSale_{listing.Id}`)
		if sellerProfile then
			sellerProfile.Data.Stats.MarketSales += 1
			table.insert(sellerProfile.Data.MarketHistory, {
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
	PersistListing(listing)

	for i, owned in profile.Data.Creatures do
		if owned.Id == creatureId then
			table.remove(profile.Data.Creatures, i)
			break
		end
	end
	-- La créature vendue ne peut plus rester compagnon (donnée morte sinon).
	if profile.Data.CompanionId == creatureId then
		profile.Data.CompanionId = nil
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

	-- 1) Claim atomique cross-serveur : un seul acheteur peut marquer SoldAt.
	local claimed
	local okClaim = pcall(function()
		claimed = Store:UpdateAsync(`Listing_{listingId}`, function(old)
			local claimable, _reason = MarketService.CanClaim(old, player.UserId)
			if not claimable then
				return nil -- abandonne l'écriture
			end
			local updated = table.clone(old)
			updated.SoldAt = os.time()
			updated.SoldBy = player.UserId
			return updated
		end)
	end)
	if not okClaim or type(claimed) ~= "table" or claimed.SoldBy ~= player.UserId then
		log:Economy("Market", "BuyRejected", { Player = player.Name, Reason = "Listing déjà pris" })
		LoadListings(true)
		BroadcastListings()
		return
	end

	-- 2) Créature d'abord, débit ensuite, règlement enfin (ordre le moins perdeur).
	table.insert(profile.Data.Creatures, claimed.Creature)
	if not essenceService:Spend(player, claimed.Price, `MarketBuy_{claimed.Id}`) then
		table.remove(profile.Data.Creatures)
		pcall(function()
			Store:UpdateAsync(`Listing_{claimed.Id}`, function(old)
				old.SoldAt = nil
				old.SoldBy = nil
				return old
			end)
		end)
		return
	end
	profile.Data.LastPlayed = os.time()
	dataSync:Send(player)

	-- 3) Règlement vendeur puis suppression du listing.
	pcall(function()
		Store:UpdateAsync(`Listing_{claimed.Id}`, function(old)
			old.SettledAt = os.time()
			return old
		end)
	end)
	listings[claimed.Id] = nil
	CreditSeller(claimed)
	RemoveListing(claimed.Id)

	log:Economy("Market", "Buy", {
		Player = player.Name,
		Listing = claimed.Id,
		Seller = claimed.SellerName,
		Species = claimed.Creature.SpeciesId,
		Price = claimed.Price,
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
	if listing.SoldAt then
		return -- déjà claimé (cache périmé), le retrait écraserait SoldAt dans le store
	end

	if not listing.WithdrawAt then
		listing.WithdrawAt = os.time() + Config.MARKET_WITHDRAW_DELAY
		PersistListing(listing)
		BroadcastListings()
		return
	end
	if os.time() < listing.WithdrawAt then
		return
	end

	listings[listing.Id] = nil
	RemoveListing(listing.Id)
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
	skillService = container:Get("SkillService")
	analyticsService = container:Get("AnalyticsService")
end

function MarketService:Start()
	-- Migration v1 -> par-listing : l'ancien snapshot unique devient des clés individuelles.
	local legacy
	pcall(function()
		legacy = Store:GetAsync(ListingsKey)
	end)
	if type(legacy) == "table" then
		for _, listing in legacy do
			if type(listing.Id) == "string" and not listing.SoldAt then
				PersistListing(listing)
			end
		end
		pcall(function()
			Store:RemoveAsync(ListingsKey)
		end)
	end

	LoadListings()

	-- sync live : les autres serveurs notifient chaque mutation
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

	-- ponytail: refresh périodique depuis le store (source de vérité) + balayage crash post-claim.
	task.spawn(function()
		while true do
			task.wait(60)
			-- ponytail: crash entre claim et règlement -> on règle le vendeur
			-- (fenêtre minuscule, favorable acheteur ; à durcir seulement si exploité).
			for _, listing in listings do
				if listing.SoldAt and not listing.SettledAt and os.time() - listing.SoldAt > 120 then
					listing.SettledAt = os.time()
					PersistListing(listing)
					CreditSeller(listing)
					listings[listing.Id] = nil
					RemoveListing(listing.Id)
				end
			end
			LoadListings(true)
			BroadcastListings()
		end
	end)

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
