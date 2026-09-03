local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Luck = require(ReplicatedStorage.Shared.Luck)

local LuckService = {}

local log
local saveService
local dataSync

function LuckService:Init(container)
	log = container:Get("Log")
	saveService = container:Get("SaveService")
	dataSync = container:Get("DataSync")
end

-- Une seule potion active : racheter la meme prolonge, une autre remplace.
function LuckService:GrantPotion(player: Player, potionKind: string, receiptKey: string?): boolean
	local profile = saveService:GetProfile(player)
	if not profile then
		return false
	end
	if receiptKey then
		profile.Data.EconomyLedger = profile.Data.EconomyLedger or {}
		if profile.Data.EconomyLedger[receiptKey] then
			return true
		end
	end
	local cfg = if potionKind == "Big" then Config.LUCK_POTION_BIG else Config.LUCK_POTION_SMALL
	if not cfg then
		return false
	end

	local now = os.time()
	local current = profile.Data.LuckPotion
	local untilTs
	if current and current.PotionKind == potionKind and Luck.Active(current.Until, now) then
		untilTs = current.Until + cfg.Duration
	else
		untilTs = Luck.Expiry(now, cfg.Duration)
	end
	profile.Data.LuckPotion = { PotionKind = potionKind, Bonus = cfg.Bonus, Until = untilTs }
	if receiptKey then
		profile.Data.EconomyLedger[receiptKey] = true
	end

	log:Economy("Luck", "PotionGranted", { Player = player.Name, Kind = potionKind, Until = untilTs })
	dataSync:Send(player)
	return true
end

function LuckService:PotionBonus(player: Player): number
	local profile = saveService:GetProfile(player)
	if not profile then
		return 0
	end
	local potion = profile.Data.LuckPotion
	if not potion or not Luck.Active(potion.Until, os.time()) then
		return 0
	end
	return potion.Bonus
end

function LuckService:PotionState(player: Player)
	local profile = saveService:GetProfile(player)
	if not profile then
		return nil
	end
	local potion = profile.Data.LuckPotion
	if not potion or not Luck.Active(potion.Until, os.time()) then
		return nil
	end
	return { PotionKind = potion.PotionKind, Bonus = potion.Bonus, Until = potion.Until }
end

return LuckService
