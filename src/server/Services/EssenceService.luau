local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)

local EssenceService = {}

local log
local saveService

function EssenceService.ComputeRate(creatures: { any }): number
	return Gameplay.ComputeRate(creatures)
end

function EssenceService.GetRate(player: Player): number
	local profile = saveService:GetProfile(player)
	if not profile then
		return 0
	end
	local sanctuaryMult = 1 + Config.SANCTUARY_LEVEL_BONUS * (profile.Data.SanctuaryLevel - 1)
	return EssenceService.ComputeRate(profile.Data.Creatures) * sanctuaryMult
end

function EssenceService:Add(player: Player, amount: number, source: string)
	local profile = saveService:GetProfile(player)
	if not profile then
		return 0
	end
	local gained = math.floor(amount)
	if gained <= 0 then
		return 0
	end
	profile.Data.Essence += gained
	profile.Data.Stats.TotalEssenceEarned += gained
	profile.Data.LastPlayed = os.time()
	log:Economy("Essence", "Add", {
		Player = player.Name,
		Amount = gained,
		Source = source,
		Total = profile.Data.Essence,
	})
	return gained
end

function EssenceService:Spend(player: Player, amount: number, source: string): boolean
	local profile = saveService:GetProfile(player)
	if not profile then
		return false
	end
	if profile.Data.Essence < amount then
		return false
	end
	profile.Data.Essence -= amount
	profile.Data.LastPlayed = os.time()
	log:Economy("Essence", "Spend", {
		Player = player.Name,
		Amount = amount,
		Source = source,
		Total = profile.Data.Essence,
	})
	return true
end

function EssenceService:GetEssence(player: Player): number
	local profile = saveService:GetProfile(player)
	return profile and profile.Data.Essence or 0
end

function EssenceService:Init(container)
	log = container:Get("Log")
	saveService = container:Get("SaveService")
end

function EssenceService:Start()
	local net = require(ReplicatedStorage.Shared.Net)
	local accumulator = 0
	local lastLog = 0

	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator < 1 then
			return
		end
		accumulator = 0

		for player, profile in pairs(saveService.Profiles) do
			local rate = EssenceService.GetRate(player)
			if rate > 0 then
				profile.Data.Essence += rate
				profile.Data.Stats.TotalEssenceEarned += rate
				profile.Data.LastPlayed = os.time()
			end
			net.Sync:FireClient(player, {
				Essence = math.floor(profile.Data.Essence),
				Creatures = profile.Data.Creatures,
				Eggs = profile.Data.Eggs,
				Rate = rate,
				SanctuaryLevel = profile.Data.SanctuaryLevel,
			})
		end

		if os.clock() - lastLog > 60 then
			lastLog = os.clock()
			for player in pairs(saveService.Profiles) do
				log:Economy("Essence", "PassiveMinute", {
					Player = player.Name,
					Rate = EssenceService.GetRate(player),
				})
			end
		end
	end)
end

return EssenceService
