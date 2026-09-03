local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Incubation = require(ReplicatedStorage.Shared.Incubation)
local Net = require(ReplicatedStorage.Shared.Net)
local Sanctuary = require(ReplicatedStorage.Shared.Sanctuary)

local IncubationService = {}

local log
local saveService
local hatchService
local dataSync
local container

local SHELL_COLORS = {
	CommonEgg = Color3.fromRGB(235, 230, 215),
	UncommonEgg = Color3.fromRGB(140, 200, 170),
	RareEgg = Color3.fromRGB(90, 150, 230),
	EpicEgg = Color3.fromRGB(160, 90, 220),
	LegendaryEgg = Color3.fromRGB(230, 190, 80),
}

local TIER_NAMES_FR = {
	CommonEgg = "Œuf commun",
	UncommonEgg = "Œuf peu commun",
	RareEgg = "Œuf rare",
	EpicEgg = "Œuf épique",
	LegendaryEgg = "Œuf légendaire",
}

local models: { [Player]: Model } = {}
local claiming: { [Player]: boolean } = {}

local function Record(profile, incubatorId: string?): (number?, any?)
	for index, record in profile.Data.Incubators or {} do
		if incubatorId == nil or record.IncubatorId == incubatorId then
			return index, record
		end
	end
	return nil, nil
end

local function ActiveRecord(profile): any?
	local _, record = Record(profile)
	return record
end

local function FindEgg(profile, eggId: string): (number?, any?)
	for index, egg in profile.Data.Eggs do
		if egg.Id == eggId then
			return index, egg
		end
	end
	return nil, nil
end

local function DestroyModel(player: Player)
	local model = models[player]
	if model then
		model:Destroy()
		models[player] = nil
	end
end

local function GroundedOrigin(player: Player): Vector3
	local couveuse = Workspace:FindFirstChild("Couveuse")
	local part = couveuse and (couveuse.PrimaryPart or couveuse:FindFirstChildWhichIsA("BasePart", true))
	if part then
		return part.Position
	end
	local character = player.Character
	return if character then character:GetPivot().Position else Vector3.zero
end

local function BuildEggModel(record): Model
	local model = Instance.new("Model")
	model.Name = "IncubatingEgg"
	model:SetAttribute("IncubatorId", record.IncubatorId)
	model:SetAttribute("EggId", record.EggId)
	model:SetAttribute("ReadyAt", record.ReadyAt)

	local shell = Instance.new("Part")
	shell.Name = "Shell"
	shell.Shape = Enum.PartType.Ball
	shell.Size = Vector3.new(1.4, 1.8, 1.4)
	shell.Material = Enum.Material.SmoothPlastic
	shell.Color = SHELL_COLORS[record.EggTier] or SHELL_COLORS.CommonEgg
	shell.Anchored = true
	shell.CanCollide = false
	shell.Parent = model

	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = TIER_NAMES_FR[record.EggTier] or record.EggTier or "Œuf"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = shell

	model.PrimaryPart = shell
	return model
end

local function Render(player: Player, record)
	DestroyModel(player)
	local model = BuildEggModel(record)
	model:PivotTo(Incubation.SlotCFrame(GroundedOrigin(player), 1) + Vector3.new(0, 1.2, 0))
	model.Parent = Workspace
	models[player] = model
	local prompt = model.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		local ready = Incubation.State(record, os.time()) == "Ready"
		prompt.ActionText = if ready then "Récupérer" else "En incubation"
		prompt.Enabled = ready
		prompt.Triggered:Connect(function(triggered: Player)
			if triggered == player then
				IncubationService:Claim(player, record.IncubatorId)
			end
		end)
		if not ready then
			task.spawn(function()
				while model.Parent and os.time() < record.ReadyAt do
					task.wait(1)
				end
				if model.Parent and models[player] == model then
					prompt.ActionText = "Récupérer"
					prompt.Enabled = true
				end
			end)
		end
	end
end

local function MoveCouveuseToSpawn()
	local couveuse = Workspace:FindFirstChild("Couveuse")
	local spawnLoc = Workspace:FindFirstChildOfClass("SpawnLocation")
	if not couveuse or not spawnLoc then
		return
	end
	local target = spawnLoc.Position + Vector3.new(7, 0, 4)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { couveuse }
	local hit = Workspace:Raycast(target + Vector3.new(0, 20, 0), Vector3.new(0, -40, 0), params)
	if not hit then
		return
	end
	local pivot = couveuse:GetPivot()
	couveuse:PivotTo(CFrame.new(target.X, hit.Position.Y + 0.6, target.Z) * (pivot - pivot.Position))
	log:Economy("Egg", "CouveuseRelocated", {
		Position = string.format("%.1f, %.1f, %.1f", target.X, hit.Position.Y + 0.6, target.Z),
	})
end

function IncubationService:Init(cont)
	container = cont
	log = cont:Get("Log")
	saveService = cont:Get("SaveService")
end

function IncubationService:Restore(player: Player)
	local profile = saveService:GetProfile(player)
	if not profile then
		return
	end
	local record = ActiveRecord(profile)
	if record and Incubation.IsRecord(record) then
		record.EggTier = record.EggTier or "CommonEgg"
		Render(player, record)
	end
end

function IncubationService:Place(player: Player, eggId: string, instant: boolean?): (boolean, string?)
	local profile = saveService:GetProfile(player)
	if not profile then
		return false, "Sauvegarde indisponible"
	end
	profile.Data.Incubators = profile.Data.Incubators or {}
	local active = ActiveRecord(profile)
	if not Incubation.CanStart(active, eggId) then
		return false, if active and active.EggId == eggId then "Oeuf deja place" else "Couveuse occupee"
	end
	local eggIndex, egg = FindEgg(profile, eggId)
	if not eggIndex then
		return false, "Oeuf introuvable"
	end
	local bonusSlots = if profile.Data.Entitlements.MoreSlots then 2 else 0
	local maxCreatures = Sanctuary.MaxCreatures(profile.Data.SanctuaryLevel, bonusSlots)
	if #profile.Data.Creatures >= maxCreatures then
		return false, "Sanctuaire plein"
	end
	local pityBefore = profile.Data.Stats.HatchesSinceRare or 0
	local lastPlayedBefore = profile.Data.LastPlayed
	local reserveCallOk, reserved, reason = pcall(function()
		return hatchService:Reserve(player, egg)
	end)
	if not reserveCallOk then
		profile.Data.Stats.HatchesSinceRare = pityBefore
		return false, tostring(reserved)
	end
	if not reserved then
		return false, reason
	end
	local startedAt = os.time()
	profile.Data.LastPlayed = startedAt
	local record = {
		IncubatorId = HttpService:GenerateGUID(false),
		EggId = egg.Id,
		EggTier = egg.Tier,
		RotatingEggId = egg.RotatingEggId,
		StartedAt = startedAt,
		ReadyAt = if instant
			then startedAt
			else startedAt + Incubation.Duration(
				egg.Tier,
				reserved.Rarity,
				reserved.Power,
				(profile.Data.Stats.TotalHatched or 0) == 0
			),
		QueueIndex = 1,
		ReservedHatch = reserved,
	}
	local ok, renderError = pcall(function()
		Render(player, record)
	end)
	if not ok then
		profile.Data.Stats.HatchesSinceRare = pityBefore
		profile.Data.LastPlayed = lastPlayedBefore
		return false, tostring(renderError)
	end
	table.remove(profile.Data.Eggs, eggIndex)
	table.insert(profile.Data.Incubators, record)
	log:Economy("Egg", "IncubationStarted", { Player = player.Name, EggId = egg.Id, IncubatorId = record.IncubatorId })
	dataSync:Send(player)
	return true
end

function IncubationService:Claim(player: Player, incubatorId: string?): (boolean, string?)
	if claiming[player] then
		return false, "Réclamation en cours"
	end
	claiming[player] = true
	local profile = saveService:GetProfile(player)
	local record
	if profile then
		local _, found = Record(profile, incubatorId)
		record = found
	end
	if not record then
		claiming[player] = nil
		return false, "Aucune incubation"
	end
	local bonusSlots = if profile.Data.Entitlements.MoreSlots then 2 else 0
	local maxCreatures = Sanctuary.MaxCreatures(profile.Data.SanctuaryLevel, bonusSlots)
	local ready, reason = Incubation.CanClaim(record, os.time(), #profile.Data.Creatures, maxCreatures)
	if not ready then
		claiming[player] = nil
		return false, reason
	end
	local callOk, ok, claimReason = pcall(function()
		return hatchService:ClaimReserved(player, record, true)
	end)
	if not callOk then
		claiming[player] = nil
		return false, tostring(ok)
	end
	if not ok then
		claiming[player] = nil
		return false, claimReason
	end
	local index = Record(profile, record.IncubatorId)
	if index then
		table.remove(profile.Data.Incubators, index)
	end
	local claimedModel = models[player]
	if claimedModel then
		claimedModel:SetAttribute("Claimed", true)
		task.delay(4, function()
			if models[player] == claimedModel then
				DestroyModel(player)
			end
		end)
	end
	claiming[player] = nil
	log:Economy("Egg", "IncubationClaimed", { Player = player.Name, EggId = record.EggId })
	dataSync:Send(player)
	return true
end

function IncubationService:ClearPlayer(player: Player)
	DestroyModel(player)
	claiming[player] = nil
end

function IncubationService:AutoPlaceAndHatch(player: Player, eggId: string, _tier: string)
	local placed = self:Place(player, eggId, true)
	if not placed then
		return false
	end
	local profile = saveService:GetProfile(player)
	local record
	if profile then
		local _, found = Record(profile)
		record = found
	end
	if not record then
		return false
	end
	return self:Claim(player, record.IncubatorId)
end

function IncubationService:Start()
	hatchService = container:Get("HatchService")
	dataSync = container:Get("DataSync")
	MoveCouveuseToSpawn()

	local function start(player: Player, eggId: unknown)
		if typeof(eggId) ~= "string" then
			return
		end
		local ok, reason = self:Place(player, eggId)
		Net.ActionResult:FireClient(player, { Action = "StartIncubation", Success = ok, Reason = reason })
	end
	Net.StartIncubation.OnServerEvent:Connect(start)
	-- Compatibilité pour les clients synchronisés pendant une mise à jour.
	Net.PlaceEgg.OnServerEvent:Connect(start)
	Net.ClaimIncubation.OnServerEvent:Connect(function(player: Player, incubatorId: unknown)
		local id = if typeof(incubatorId) == "string" then incubatorId else nil
		local ok, reason = self:Claim(player, id)
		Net.ActionResult:FireClient(player, { Action = "ClaimIncubation", Success = ok, Reason = reason })
	end)

	Players.PlayerAdded:Connect(function(player: Player)
		task.spawn(function()
			for _ = 1, 15 do
				if saveService:GetProfile(player) then
					self:Restore(player)
					return
				end
				task.wait(1)
			end
		end)
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		self:ClearPlayer(player)
	end)
	for _, player in Players:GetPlayers() do
		self:Restore(player)
	end
end

return IncubationService
