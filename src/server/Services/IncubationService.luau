local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Incubation = require(ReplicatedStorage.Shared.Incubation)
local Net = require(ReplicatedStorage.Shared.Net)

local IncubationService = {}

local log
local saveService
local hatchService
local container

-- Couleur de coquille par tier, sobre : ivoire / vert d'eau / bleu / violet / doré.
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

local placed: { [Player]: { [string]: Model } } = {}
local slotIndex: { [Player]: number } = {}

local function PlacedCount(player: Player): number
	local count = 0
	for _ in placed[player] or {} do
		count += 1
	end
	return count
end

local function ClearPlayer(player: Player)
	local eggs = placed[player]
	if not eggs then
		return
	end
	for _, model in eggs do
		model:Destroy()
	end
	placed[player] = nil
	slotIndex[player] = nil
end

local function Release(player: Player, eggId: string)
	local eggs = placed[player]
	if not eggs or not eggs[eggId] then
		return
	end
	eggs[eggId]:Destroy()
	eggs[eggId] = nil
	if next(eggs) == nil then
		placed[player] = nil
		slotIndex[player] = nil
	end
end

-- Origine des slots : couveuse du monde, sinon nid du spawn, sinon le joueur.
local function CouveuseOrigin(player: Player): Vector3
	local model = Workspace:FindFirstChild("Couveuse")
	local part = model and (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true))
	if part then
		return part.Position
	end
	local nest = Workspace:FindFirstChild("Nest")
	local nestPart = nest and (nest.PrimaryPart or nest:FindFirstChildWhichIsA("BasePart", true))
	if nestPart then
		return nestPart.Position
	end
	local character = player.Character
	return if character then character:GetPivot().Position else Vector3.zero
end

local function BuildEggModel(tier: string): Model
	local model = Instance.new("Model")
	model.Name = "IncubatingEgg"

	local shell = Instance.new("Part")
	shell.Name = "Shell"
	shell.Shape = Enum.PartType.Ball
	shell.Size = Vector3.new(1.4, 1.8, 1.4)
	shell.Material = Enum.Material.SmoothPlastic
	shell.Color = SHELL_COLORS[tier] or SHELL_COLORS.CommonEgg
	shell.Anchored = true
	shell.CanCollide = false
	shell.Parent = model

	local glow = Instance.new("PointLight")
	glow.Color = shell.Color
	glow.Brightness = 0.6
	glow.Range = 6
	glow.Shadows = false
	glow.Parent = shell

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Éclore"
	prompt.ObjectText = TIER_NAMES_FR[tier] or tier
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = shell

	model.PrimaryPart = shell
	return model
end

function IncubationService:Init(cont)
	container = cont
	log = cont:Get("Log")
	saveService = cont:Get("SaveService")
	-- HatchService pas encore enregistré pendant la passe Init : résolution différée au Start.
end

function IncubationService:Place(player: Player, eggId: string, tier: string)
	slotIndex[player] = ((slotIndex[player] or 0) % Incubation.MAX_PLACED) + 1

	local model = BuildEggModel(tier)
	local cf = Incubation.SlotCFrame(CouveuseOrigin(player), slotIndex[player])
	model:PivotTo(cf + Vector3.new(0, 1.2, 0))
	model.Parent = Workspace

	placed[player] = placed[player] or {}
	placed[player][eggId] = model

	log:Economy("Egg", "Placed", { Player = player.Name, Tier = tier, EggId = eggId })

	model.Shell:FindFirstChildOfClass("ProximityPrompt").Triggered:Connect(function(triggered: Player)
		-- Seul le propriétaire peut éclore son œuf, et seulement s'il est toujours dans l'inventaire.
		if triggered ~= player then
			return
		end
		local profile = saveService:GetProfile(player)
		if not profile then
			return
		end
		local owned = false
		for _, entry in profile.Data.Eggs do
			if entry.Id == eggId then
				owned = true
				break
			end
		end
		if not owned then
			return
		end
		if hatchService:HatchEggById(player, eggId, true) then
			Release(player, eggId)
		end
	end)
end

-- Éclosion auto (AutoHatch) : visuel bref à la couveuse puis hatch monde immédiat.
function IncubationService:AutoPlaceAndHatch(player: Player, eggId: string, tier: string)
	local model = BuildEggModel(tier)
	local slot = ((slotIndex[player] or 0) % Incubation.MAX_PLACED) + 1
	slotIndex[player] = slot
	local cf = Incubation.SlotCFrame(CouveuseOrigin(player), slot)
	model:PivotTo(cf + Vector3.new(0, 1.2, 0))
	model.Parent = Workspace
	task.delay(1, function()
		model:Destroy()
	end)
	hatchService:HatchEggById(player, eggId, true)
end

function IncubationService:Start()
	-- Convention repo : dépendances enregistrées après nous se résolvent au Start.
	hatchService = container:Get("HatchService")

	Net.PlaceEgg.OnServerEvent:Connect(function(player: Player, eggId: unknown)
		if typeof(eggId) ~= "string" then
			return
		end
		local profile = saveService:GetProfile(player)
		if not profile then
			return
		end
		local egg = nil
		for _, candidate in profile.Data.Eggs do
			if candidate.Id == eggId then
				egg = candidate
				break
			end
		end
		if not egg then
			return
		end
		if placed[player] and placed[player][eggId] then
			return
		end
		if PlacedCount(player) >= Incubation.MAX_PLACED then
			log:Economy("Egg", "PlaceReject", { Player = player.Name, Reason = "SlotsFull", EggId = eggId })
			return
		end
		self:Place(player, egg.Id, egg.Tier)
	end)

	Players.PlayerRemoving:Connect(ClearPlayer)
end

return IncubationService
