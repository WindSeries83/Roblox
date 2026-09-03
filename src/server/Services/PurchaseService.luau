--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Offers = require(ReplicatedStorage.Shared.Offers)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local PurchaseLedger = require(ReplicatedStorage.Shared.PurchaseLedger)
local Sanctuary = require(ReplicatedStorage.Shared.Sanctuary)
local Species = require(ReplicatedStorage.Shared.Data.Species)
local Vip = require(ReplicatedStorage.Shared.Vip)
local SafeStore = require(script.Parent.SafeStore)
local Log = require(script.Parent.Log)

local PurchaseService = {}

local saveService
local essenceService
local dataSync
local luckService
local boostService
local analyticsService

local ReceiptsStore = SafeStore.Get("RiftBeastsReceipts_v1", nil)

local function LogPurchase(source: string, data: { [string]: any })
	Log:Economy("Purchase", source, data)
end

function PurchaseService.GrantProduct(player: Player, product: any, productId: number, receiptKey: string?): boolean
	local profile = saveService:GetProfile(player)
	if receiptKey and profile and profile.Data.EconomyLedger and profile.Data.EconomyLedger[receiptKey] then
		return true
	end
	if product.Kind == "LuckPotion" then
		return luckService:GrantPotion(player, product.PotionKind, receiptKey)
	elseif product.Kind == "ServerBoost" then
		return boostService:Activate(player, receiptKey)
	elseif product.Kind == "Vip" then
		if not profile then
			return false
		end
		profile.Data.VipExpiresAt = Vip.Extend(profile.Data.VipExpiresAt, os.time(), product.Duration)
		profile.Data.Entitlements.VIP = nil
		if receiptKey then
			profile.Data.EconomyLedger = profile.Data.EconomyLedger or {}
			profile.Data.EconomyLedger[receiptKey] = true
		end
		return true
	elseif product.Kind == "FirstOffer" then
		if not profile then
			return false
		end
		if profile.Data.Offers.FirstPurchaseClaimed then
			return true
		end
		if not PurchaseService.GrantPass(player, "StarterBundle", receiptKey) then
			return false
		end
		profile.Data.Offers.FirstPurchaseClaimed = true
		if receiptKey then
			profile.Data.EconomyLedger = profile.Data.EconomyLedger or {}
			profile.Data.EconomyLedger[receiptKey] = true
		end
		return true
	end
	if not receiptKey then
		return essenceService:Add(player, product.Amount, `DevProduct_{productId}`) > 0
	end
	return essenceService:AddOnce(player, product.Amount, `DevProduct_{productId}`, receiptKey) > 0
end

function PurchaseService.ResolveProduct(productId: number)
	local offer = PurchaseService.ResolveOffer(productId)
	if not offer or offer.Kind ~= "DeveloperProduct" then
		return nil
	end
	local def = Config.DEV_PRODUCTS[offer.ConfigKey]
	if def and def.Id == productId then
		return def
	end
	return nil
end

function PurchaseService.ResolveOffer(sku: number)
	if type(sku) ~= "number" or sku <= 0 then
		return nil
	end
	for _, offer in Offers.All do
		if offer.Sku == sku and Offers.IsAvailable(offer) then
			return offer
		end
	end
	return nil
end

function PurchaseService.ReceiptKey(playerId: number, purchaseId: string): string
	return `{playerId}_{purchaseId}`
end

function PurchaseService.PassEffect(passKey: string)
	if passKey == "StarterBundle" then
		return { Flag = "StarterBundle", Essence = 2000, Creature = { Rarity = "Rare", Mutation = "Shadow" } }
	end
	if
		passKey == "MoreSlots"
		or passKey == "PassiveBoost"
		or passKey == "AutoHatch"
		or passKey == "SeasonPremium"
		or passKey == "VIP"
	then
		return { Flag = passKey, Essence = 0 }
	end
	return nil
end

function PurchaseService.GrantPass(player: Player, passKey: string, receiptKey: string?): boolean
	if passKey == "VIP" then
		return false
	end
	local pass = Config.GAMEPASSES[passKey]
	local effect = PurchaseService.PassEffect(passKey)
	if not pass or not effect then
		return false
	end
	local profile = saveService:GetProfile(player)
	if not profile then
		return false
	end
	local firstGrant = not profile.Data.Entitlements[effect.Flag]
	if firstGrant then
		if effect.Essence > 0 then
			local ledgerKey = if receiptKey then `{receiptKey}:starter` else nil
			local granted = if receiptKey
				then essenceService:AddOnce(player, effect.Essence, "StarterBundle", ledgerKey :: string)
				else essenceService:Add(player, effect.Essence, "StarterBundle")
			if granted <= 0 then
				if ledgerKey then
					profile.Data.EconomyLedger[ledgerKey] = nil
				end
				return false
			end
		end
		profile.Data.Entitlements[effect.Flag] = true
		if effect.Creature then
			local bonusSlots = if profile.Data.Entitlements.MoreSlots then Config.GAMEPASSES.MoreSlots.BonusSlots else 0
			local maxCreatures = Sanctuary.MaxCreatures(profile.Data.SanctuaryLevel, bonusSlots)
			if #profile.Data.Creatures < maxCreatures then
				local pool = {}
				for speciesId, def in Species do
					if def.Rarity == effect.Creature.Rarity then
						table.insert(pool, speciesId)
					end
				end
				local speciesId = pool[Random.new():NextInteger(1, #pool)]
				table.insert(
					profile.Data.Creatures,
					Gameplay.CreateCreature(effect.Creature.Rarity, speciesId, effect.Creature.Mutation)
				)
			end
		end
	end
	profile.Data.LastPlayed = os.time()
	dataSync:Send(player)
	if firstGrant then
		analyticsService:Event("purchase", { Pass = passKey })
		analyticsService:Funnel(profile, "FirstPurchaseAt")
	end
	return true
end

function PurchaseService:Init(container)
	saveService = container:Get("SaveService")
	essenceService = container:Get("EssenceService")
	dataSync = container:Get("DataSync")
	luckService = container:Get("LuckService")
	boostService = container:Get("BoostService")
	analyticsService = container:Get("AnalyticsService")
end

function PurchaseService:Start()
	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			for passKey, def in Config.GAMEPASSES do
				if def.Id ~= 0 then
					local ok, owns = pcall(function()
						return MarketplaceService:UserOwnsGamePassAsync(player.UserId, def.Id)
					end)
					if ok and owns then
						PurchaseService.GrantPass(player, passKey)
					end
				end
			end
		end)
	end)

	MarketplaceService.ProcessReceipt = function(receiptInfo)
		if not Config.PURCHASES_ENABLED then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local receiptKey = PurchaseService.ReceiptKey(receiptInfo.PlayerId, receiptInfo.PurchaseId)
		local knownOk, known = pcall(function()
			return ReceiptsStore:GetAsync(receiptKey)
		end)
		if knownOk and known == "done" then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		local product = PurchaseService.ResolveProduct(receiptInfo.ProductId)
		if not product then
			LogPurchase("ReceiptUnknown", { PlayerId = receiptInfo.PlayerId, ProductId = receiptInfo.ProductId })
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		local profile = if player then saveService:GetProfile(player) else nil
		if not player or not profile then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		profile.Data.PurchaseReceipts = profile.Data.PurchaseReceipts or {}
		profile.Data.PurchaseReceiptOrder = profile.Data.PurchaseReceiptOrder or {}
		if profile.Data.PurchaseReceipts[receiptKey] then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		local snapshot = PurchaseLedger.Snapshot(profile.Data)
		local applied = PurchaseLedger.Apply(
			profile.Data.PurchaseReceipts,
			profile.Data.PurchaseReceiptOrder,
			receiptKey,
			Config.PURCHASE_RECEIPT_MAX,
			function()
				local okGrant, granted = pcall(function()
					return PurchaseService.GrantProduct(player, product, receiptInfo.ProductId, receiptKey)
				end)
				return okGrant and granted, function()
					PurchaseLedger.Restore(profile.Data, snapshot)
				end
			end,
			function()
				return saveService:SaveProfile(player, function(data)
					return data.PurchaseReceipts and data.PurchaseReceipts[receiptKey] == true
				end)
			end
		)
		if not applied then
			LogPurchase("ReceiptGrantFailed", { PlayerId = receiptInfo.PlayerId, ProductId = receiptInfo.ProductId })
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		dataSync:Send(player)
		pcall(function()
			ReceiptsStore:SetAsync(receiptKey, "done")
		end)
		LogPurchase("Receipt", {
			PlayerId = receiptInfo.PlayerId,
			ProductId = receiptInfo.ProductId,
			Kind = product.Kind or "Essence",
			PurchaseId = receiptInfo.PurchaseId,
		})
		analyticsService:Event("purchase", { ProductId = receiptInfo.ProductId, Kind = product.Kind or "Essence" })
		analyticsService:Funnel(profile, "FirstPurchaseAt")
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

return PurchaseService
