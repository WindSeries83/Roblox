local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Index = require(ReplicatedStorage.Shared.Index)
local Rebirth = require(ReplicatedStorage.Shared.Rebirth)
local Pack = require(ReplicatedStorage.Shared.Pack)

local EssenceService = {}

local log
local saveService
local dataSync
local questService
local skillService
local packService
local container

function EssenceService.GetRate(player: Player): number
	local profile = saveService:GetProfile(player)
	if not profile then
		return 0
	end
	local sanctuaryMult = 1 + Config.SANCTUARY_LEVEL_BONUS * (profile.Data.SanctuaryLevel - 1)
	local indexMult = Index.ComputeMult(profile.Data.Index)
	local starMult = Rebirth.StarEssenceMult(profile.Data.Stars)
	local passMult = if profile.Data.Entitlements.PassiveBoost then 1.5 else 1
	local skillMult = 1 + skillService:EffectsOf(profile).EssenceRate
	local packMult = Pack.Mult(packService and packService:Count(player) or 0)
	return Gameplay.ComputeRate(profile.Data.Creatures)
		* sanctuaryMult
		* indexMult
		* starMult
		* passMult
		* skillMult
		* packMult
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
	questService:OnEssenceGained(player, gained, source)
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

function EssenceService:Init(cont)
	log = cont:Get("Log")
	saveService = cont:Get("SaveService")
	dataSync = cont:Get("DataSync")
	skillService = cont:Get("SkillService")
	-- QuestService s'initialise après celui-ci (dépendance circulaire) :
	-- la référence est résolue au Start, quand toutes les Init sont passées.
	container = cont
end

function EssenceService:Start()
	questService = container:Get("QuestService")
	packService = container:Get("PackService")

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
				questService:OnEssenceGained(player, rate, "Passive")
			end
			dataSync:Send(player)
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
