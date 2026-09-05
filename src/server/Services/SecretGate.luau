--!strict
-- Le procede et les indices restent dans ServerScriptService. Le client ne recoit
-- qu'un indice apres un boss et l'etat de progression necessaire au rituel.

local SecretGate = {}

function SecretGate.Triggered(eggTier: string, eclipseActive: boolean, relicTier: string?, omen: boolean?): boolean
	if eclipseActive ~= true or relicTier ~= "T3" then
		return false
	end
	if eggTier == "RareEgg" then
		return true
	end
	return omen == true and (eggTier == "EpicEgg" or eggTier == "LegendaryEgg")
end

local HINTS = {
	TwilightGrove = "Le premier gardien murmure : quand les quatre failles se taisent, le sanctuaire se souvient.",
	AshForge = "La braise indique un autel qui attend les quatre marques, loin des portails de combat.",
	GalePeaks = "Le vent porte les marques jusqu'au coeur du sanctuaire; aucune monnaie n'ouvrira ce passage.",
	NyxAbyss = "La derniere marque revele le rituel du sanctuaire : approche-toi de l'autel quand les quatre sont reunies.",
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config
local Net
local Worlds
local SecretProgress
local PurchaseLedger
local saveService
local essenceService
local dataSync
local analyticsService
local log
local cooldowns: { [Player]: number } = {}

local function Notify(player: Player, result: { [string]: any })
	Net.ActionResult:FireClient(player, result)
end

function SecretGate:DiscoverBoss(player: Player, worldId: string): boolean
	local profile = saveService:GetProfile(player)
	local world = Worlds.Get(worldId)
	if not profile or not world then
		return false
	end
	local progress = profile.Data.WorldProgress and profile.Data.WorldProgress[worldId]
	if not progress or progress.BossDefeated ~= true then
		return false
	end
	profile.Data.SecretDiscoveries = profile.Data.SecretDiscoveries or {}
	if profile.Data.SecretDiscoveries[worldId] == true then
		return false
	end

	profile.Data.SecretDiscoveries[worldId] = true
	profile.Data.LastPlayed = os.time()
	local saved = saveService:SaveProfile(player, function(data)
		return data.SecretDiscoveries and data.SecretDiscoveries[worldId] == true
	end)
	if not saved then
		profile.Data.SecretDiscoveries[worldId] = nil
		return false
	end

	local found = SecretProgress.Count(profile.Data.SecretDiscoveries)
	Notify(player, {
		Action = "SecretHint",
		Success = true,
		WorldId = worldId,
		Hint = HINTS[worldId],
		Found = found,
		Total = 4,
	})
	dataSync:Send(player)
	analyticsService:Event("secret_discovered", { World = worldId, Found = found }, player)
	log:Economy("Secret", "Discovery", { Player = player.Name, World = worldId, Found = found })
	return true
end

function SecretGate:Claim(player: Player): boolean
	local now = os.clock()
	if now - (cooldowns[player] or 0) < 1 then
		return false
	end
	cooldowns[player] = now

	local profile = saveService:GetProfile(player)
	if not profile then
		Notify(player, { Action = "SecretRitual", Success = false, Reason = "Profil indisponible" })
		return false
	end
	profile.Data.SecretDiscoveries = profile.Data.SecretDiscoveries or {}
	if profile.Data.SecretRewardClaimed == true then
		Notify(player, { Action = "SecretRitual", Success = true, AlreadyClaimed = true })
		return true
	end
	if not SecretProgress.All(profile.Data.SecretDiscoveries) then
		Notify(player, {
			Action = "SecretRitual",
			Success = false,
			Reason = `Autel silencieux : {SecretProgress.Count(profile.Data.SecretDiscoveries)}/4 marques reunies`,
		})
		return false
	end

	local snapshot = PurchaseLedger.Snapshot(profile.Data)
	profile.Data.SecretRewardClaimed = true
	profile.Data.Titles = if type(profile.Data.Titles) == "table" then profile.Data.Titles else {}
	if not table.find(profile.Data.Titles, Config.SECRET_TITLE) then
		table.insert(profile.Data.Titles, Config.SECRET_TITLE)
	end
	local reward = essenceService:Add(player, Config.SECRET_RITUAL_REWARD, "SecretRitual")
	local saved = reward > 0
		and saveService:SaveProfile(player, function(data)
			return data.SecretRewardClaimed == true
		end)
	if not saved then
		PurchaseLedger.Restore(profile.Data, snapshot)
		Notify(player, { Action = "SecretRitual", Success = false, Reason = "Sauvegarde indisponible, reessaie" })
		return false
	end

	dataSync:Send(player)
	Notify(player, {
		Action = "SecretRitual",
		Success = true,
		Reward = reward,
		Title = Config.SECRET_TITLE,
	})
	Net.GlobalDrop:FireAllClients({
		PlayerName = player.Name,
		Rarity = "Secret",
		SpeciesName = "le Secret du sanctuaire",
	})
	analyticsService:Event("secret_claimed", { Reward = reward }, player)
	log:Economy("Secret", "Claim", { Player = player.Name, Reward = reward })
	return true
end

local function BuildAltar()
	if Workspace:FindFirstChild("SecretRitual") then
		return
	end
	local model = Instance.new("Model")
	model.Name = "SecretRitual"
	local altar = Instance.new("Part")
	altar.Name = "Altar"
	altar.Size = Vector3.new(8, 2, 8)
	altar.Material = Enum.Material.Neon
	altar.Color = Color3.fromRGB(230, 100, 210)
	altar.Anchored = true
	altar.CFrame = CFrame.new(Config.SECRET_RITUAL_POSITION)
	altar.Parent = model
	local light = Instance.new("PointLight")
	light.Color = altar.Color
	light.Brightness = 1.5
	light.Range = 16
	light.Parent = altar
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RitualPrompt"
	prompt.ActionText = "Accomplir le rituel"
	prompt.ObjectText = "Autel secret"
	prompt.HoldDuration = 0.75
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = altar
	prompt.Triggered:Connect(function(player: Player)
		SecretGate:Claim(player)
	end)
	model.PrimaryPart = altar
	model.Parent = Workspace
end

function SecretGate:Init(container)
	Config = require(ReplicatedStorage.Shared.Config)
	Net = require(ReplicatedStorage.Shared.Net)
	Worlds = require(ReplicatedStorage.Shared.Worlds)
	SecretProgress = require(ReplicatedStorage.Shared.SecretProgress)
	PurchaseLedger = require(ReplicatedStorage.Shared.PurchaseLedger)
	saveService = container:Get("SaveService")
	essenceService = container:Get("EssenceService")
	dataSync = container:Get("DataSync")
	analyticsService = container:Get("AnalyticsService")
	log = container:Get("Log")
end

function SecretGate:Start()
	BuildAltar()
	Net.SecretRitual.OnServerEvent:Connect(function(player: Player)
		self:Claim(player)
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		cooldowns[player] = nil
	end)
end

return SecretGate
