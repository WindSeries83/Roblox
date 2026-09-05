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
local PaidRandomPolicy = require(ReplicatedStorage.Shared.PaidRandomPolicy)

local PurchaseService = {}

local saveService
local essenceService
local dataSync
local luckService
local boostService
local analyticsService
local policyService
local vipService
local recognitionService

local ReceiptsStore = SafeStore.Get("RiftBeastsReceipts_v1", nil)

local function LogPurchase(source: string, data: { [string]: any })
	Log:Economy("Purchase", source, data)
end

local function MarkPaidPurchase(profile: any, key: string)
	profile.Data.PaidPurchases = profile.Data.PaidPurchases or {}
	profile.Data.PaidPurchases[key] = true
end

function PurchaseService.GrantProduct(player: Player, product: any, productId: number, receiptKey: string?): boolean
	local profile = saveService:GetProfile(player)
	if receiptKey and profile and profile.Data.EconomyLedger and profile.Data.EconomyLedger[receiptKey] then
		return true
	end
	if product.Kind == "LuckPotion" then
		local granted = luckService:GrantPotion(player, product.PotionKind, receiptKey)
		if granted and profile then
			MarkPaidPurchase(profile, `Product_{productId}`)
		end
		return granted
	elseif product.Kind == "ServerBoost" then
		local granted = boostService:Activate(player, receiptKey)
		if granted and profile then
			MarkPaidPurchase(profile, `Product_{productId}`)
		end
		return granted
	elseif product.Kind == "Vip" then
		if not profile then
			return false
		end
		profile.Data.VipExpiresAt = Vip.Extend(profile.Data.VipExpiresAt, os.time(), product.Duration)
		profile.Data.Entitlements.VIP = nil
		MarkPaidPurchase(profile, `Product_{productId}`)
		vipService:Refresh(player)
		if receiptKey then
			profile.Data.EconomyLedger = profile.Data.EconomyLedger or {}
			profile.Data.EconomyLedger[receiptKey] = true
		end
		return true
	elseif product.Kind == "Support" then
		if not profile or not receiptKey or type(product.Tier) ~= "string" then
			return false
		end
		local granted = recognitionService:RecordSupport(player, product.Tier, receiptKey)
		if granted then
			MarkPaidPurchase(profile, `Product_{productId}`)
		end
		return granted
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
		local granted = essenceService:Add(player, product.Amount, `DevProduct_{productId}`) > 0
		if granted and profile then
			MarkPaidPurchase(profile, `Product_{productId}`)
		end
		return granted
	end
	local granted = essenceService:AddOnce(player, product.Amount, `DevProduct_{productId}`, receiptKey) > 0
	if granted and profile then
		MarkPaidPurchase(profile, `Product_{productId}`)
	end
	return granted
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
		if Offers.Sku(offer) == sku and Offers.IsAvailable(offer) then
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
	if
		PaidRandomPolicy.RequiresEligibility({
			Kind = if passKey == "VIP" then "Vip" else passKey,
			Creature = effect.Creature,
		}) and not policyService:CanUsePaidRandomItems(player)
	then
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
	MarkPaidPurchase(profile, `Pass_{passKey}`)
	profile.Data.LastPlayed = os.time()
	dataSync:Send(player)
	if firstGrant then
		analyticsService:Event("purchase", { Pass = passKey }, player)
		analyticsService:Funnel(profile, "FirstPurchaseAt", player)
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
	policyService = container:Get("PolicyService")
	vipService = container:Get("VipService")
	recognitionService = container:Get("RecognitionService")
end

function PurchaseService:Start()
	local function restorePasses(player: Player)
		task.spawn(function()
			for passKey, def in Config.GAMEPASSES do
				if def.Id ~= 0 and player:IsDescendantOf(Players) then
					local ok, owns = pcall(function()
						return MarketplaceService:UserOwnsGamePassAsync(player.UserId, def.Id)
					end)
					if ok and owns then
						PurchaseService.GrantPass(player, passKey)
					end
				end
			end
		end)
	end
	saveService.ProfileLoaded.Event:Connect(restorePasses)
	policyService.PolicyLoaded.Event:Connect(function(player: Player)
		if saveService:GetProfile(player) then
			restorePasses(player)
		end
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
		local profile = if player then saveService:WaitForProfile(player, 10) else nil
		if not player or not profile then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		if PaidRandomPolicy.RequiresEligibility(product) and not policyService:CanUsePaidRandomItems(player) then
			LogPurchase(
				"ReceiptPolicyRestricted",
				{ PlayerId = receiptInfo.PlayerId, ProductId = receiptInfo.ProductId }
			)
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
		analyticsService:Event(
			"purchase",
			{ ProductId = receiptInfo.ProductId, Kind = product.Kind or "Essence" },
			player
		)
		analyticsService:Funnel(profile, "FirstPurchaseAt", player)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

return PurchaseService
