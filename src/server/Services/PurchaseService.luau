local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Sanctuary = require(ReplicatedStorage.Shared.Sanctuary)
local Species = require(ReplicatedStorage.Shared.Data.Species)
local Log = require(script.Parent.Log)

local PurchaseService = {}

local saveService
local essenceService
local dataSync

local ReceiptsStore
local receiptsOk = pcall(function()
	ReceiptsStore = DataStoreService:GetDataStore("RiftBeastsReceipts_v1")
end)
if not receiptsOk then
	ReceiptsStore = {
		GetAsync = function()
			return nil
		end,
		SetAsync = function() end,
	}
end

local function LogPurchase(source: string, data: { [string]: any })
	Log:Economy("Purchase", source, data)
end

function PurchaseService.ResolveProduct(productId: number)
	if productId == 0 then
		return nil
	end
	for _, def in Config.DEV_PRODUCTS do
		if def.Id == productId then
			return def
		end
	end
	return nil
end

function PurchaseService.ReceiptKey(playerId: number, purchaseId: string): string
	return `{playerId}_{purchaseId}`
end

-- Pure : effet d'un pass sur le profil (testable sans container).
function PurchaseService.PassEffect(passKey: string)
	if passKey == "StarterBundle" then
		return { Flag = "StarterBundle", Essence = 2000, Creature = { Rarity = "Rare", Mutation = "Shadow" } }
	end
	if passKey == "MoreSlots" or passKey == "PassiveBoost" or passKey == "AutoHatch" or passKey == "SeasonPremium" then
		return { Flag = passKey, Essence = 0 }
	end
	return nil
end

function PurchaseService.GrantPass(player: Player, passKey: string): boolean
	local pass = Config.GAMEPASSES[passKey]
	local effect = PurchaseService.PassEffect(passKey)
	if not pass or not effect then
		return false
	end
	local profile = saveService:GetProfile(player)
	if not profile then
		return false
	end
	-- Pas de re-grant : les effets consommables (essence, créature) ne sont
	-- accordés qu'au premier grant ; le flag est reposé dans tous les cas.
	local firstGrant = not profile.Data.Entitlements[effect.Flag]
	profile.Data.Entitlements[effect.Flag] = true
	if firstGrant then
		if effect.Essence > 0 then
			essenceService:Add(player, effect.Essence, "StarterBundle")
		end
		if effect.Creature then
			local bonusSlots = if profile.Data.Entitlements.MoreSlots then 2 else 0
			local maxCreatures = Sanctuary.MaxCreatures(profile.Data.SanctuaryLevel, bonusSlots)
			if #profile.Data.Creatures < maxCreatures then
				local pool = {}
				for speciesId, def in Species do
					if def.Rarity == effect.Creature.Rarity then
						table.insert(pool, speciesId)
					end
				end
				local speciesId = pool[Random.new():NextInteger(1, #pool)]
				local creature = Gameplay.CreateCreature(effect.Creature.Rarity, speciesId, effect.Creature.Mutation)
				table.insert(profile.Data.Creatures, creature)
				LogPurchase("StarterCreature", {
					Player = player.Name,
					Species = speciesId,
					Rarity = creature.Rarity,
					Mutation = tostring(creature.Mutation),
					CreatureId = creature.Id,
				})
			else
				LogPurchase("StarterCreatureSkipped", {
					Player = player.Name,
					Reason = "CapReached",
					Creatures = #profile.Data.Creatures,
					MaxCreatures = maxCreatures,
				})
			end
		end
	end
	profile.Data.LastPlayed = os.time()
	LogPurchase("Gamepass", { Player = player.Name, Pass = passKey })
	dataSync:Send(player)
	return true
end

function PurchaseService:Init(container)
	saveService = container:Get("SaveService")
	essenceService = container:Get("EssenceService")
	dataSync = container:Get("DataSync")
end

function PurchaseService:Start()
	-- Re-grant owned gamepasses on join (idempotent : flags déjà posés)
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
		local playerId = receiptInfo.PlayerId
		local productId = receiptInfo.ProductId
		local receiptKey = PurchaseService.ReceiptKey(playerId, receiptInfo.PurchaseId)

		-- Idempotence : déjà accordé ?
		local granted = false
		local okGet = pcall(function()
			granted = ReceiptsStore:GetAsync(receiptKey)
		end)
		if okGet and granted then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		if not okGet then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local product = PurchaseService.ResolveProduct(productId)
		if not product then
			LogPurchase("ReceiptUnknown", { PlayerId = playerId, ProductId = productId })
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local player = Players:GetPlayerByUserId(playerId)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		-- Grant-then-ack (SE-3) : persistance du receipt AVANT PurchaseGranted
		local okGrant = pcall(function()
			essenceService:Add(player, product.Amount, `DevProduct_{productId}`)
		end)
		if not okGrant then
			LogPurchase("ReceiptGrantFailed", { PlayerId = playerId, ProductId = productId })
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local okSet = pcall(function()
			ReceiptsStore:SetAsync(receiptKey, true)
		end)
		if not okSet then
			LogPurchase("ReceiptHistorySaveFailed", { PlayerId = playerId, ProductId = productId })
		end

		LogPurchase("Receipt", {
			PlayerId = playerId,
			ProductId = productId,
			Amount = product.Amount,
			PurchaseId = receiptInfo.PurchaseId,
		})
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

return PurchaseService
