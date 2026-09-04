--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)
local SafeStore = require(script.Parent.SafeStore)

local BoostService = {}

local log
local saveService
local Store = SafeStore.Get("RiftBeastsBoost_v1", 0)

local boostUntil = 0
local boostBonus = 0

-- Activer prolonge la duree d'un boost deja en cours (cumul temporel,
-- bonus plafonne par construction : un seul montant serveur).
function BoostService:Activate(player: Player, receiptKey: string?): boolean
	local profile = if player and saveService then saveService:GetProfile(player) else nil
	if receiptKey and profile then
		profile.Data.EconomyLedger = profile.Data.EconomyLedger or {}
		if profile.Data.EconomyLedger[receiptKey] then
			return true
		end
	end
	local now = os.time()
	local nextUntil = now
	local changed = false
	local ok, stored = pcall(function()
		return Store:UpdateAsync("Active", function(old)
			local data = if type(old) == "table"
				then table.clone(old)
				else { Until = if type(old) == "number" then old else 0 }
			data.Receipts = if type(data.Receipts) == "table" then table.clone(data.Receipts) else {}
			data.ReceiptOrder = if type(data.ReceiptOrder) == "table" then table.clone(data.ReceiptOrder) else {}
			if receiptKey and data.Receipts[receiptKey] then
				return data
			end
			local base = if type(data.Until) == "number" and data.Until > now then data.Until else now
			data.Until = base + Config.SERVER_BOOST.Duration
			if receiptKey then
				data.Receipts[receiptKey] = true
				table.insert(data.ReceiptOrder, receiptKey)
				while #data.ReceiptOrder > Config.PURCHASE_RECEIPT_MAX do
					local oldest = table.remove(data.ReceiptOrder, 1)
					if oldest then
						data.Receipts[oldest] = nil
					end
				end
			end
			changed = true
			return data
		end)
	end)
	if not ok or type(stored) ~= "table" or type(stored.Until) ~= "number" then
		return false
	end
	nextUntil = stored.Until
	boostUntil = nextUntil
	boostBonus = Config.SERVER_BOOST.Bonus
	if receiptKey and profile then
		profile.Data.EconomyLedger[receiptKey] = true
	end

	workspace:SetAttribute("BoostActiveUntil", boostUntil)
	workspace:SetAttribute("BoostEssenceBonus", boostBonus)
	Net.BoostState:FireAllClients({ Bonus = boostBonus, Until = boostUntil })

	if changed then
		log:Economy("Boost", "Activated", {
			Player = player and player.Name or "?",
			Bonus = boostBonus,
			Until = boostUntil,
		})
	end
	return true
end

function BoostService:CurrentBonus(): number
	return if boostUntil > os.time() then boostBonus else 0
end

function BoostService:Until(): number
	return if boostUntil > os.time() then boostUntil else 0
end

function BoostService:Init(container)
	log = container:Get("Log")
	saveService = container:Get("SaveService")
end

function BoostService:Start()
	local ok, stored = pcall(function()
		return Store:GetAsync("Active")
	end)
	if ok and type(stored) == "table" and type(stored.Until) == "number" then
		boostUntil = stored.Until
		boostBonus = Config.SERVER_BOOST.Bonus
	elseif ok and type(stored) == "number" then
		boostUntil = stored
		boostBonus = Config.SERVER_BOOST.Bonus
	end
end

return BoostService
