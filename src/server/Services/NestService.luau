local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local NestService = {}

local log
local hatchService
local saveService

local used: { [Player]: boolean } = nil

-- Nid du spawn : socle de pierre + paille + oeuf + prompt « Éclore ».
-- Le premier oeuf (Source="Nest") s'éclore ici, dans le monde — pas dans un menu.
local function BuildNest(): BasePart
	local model = Instance.new("Model")
	model.Name = "Nest"

	local base = Instance.new("Part")
	base.Name = "NestBase"
	base.Shape = Enum.PartType.Cylinder
	base.Size = Vector3.new(0.6, 4.5, 4.5)
	base.Rotation = Vector3.new(0, 0, 90)
	base.Material = Enum.Material.Slate
	base.Color = Color3.fromRGB(70, 68, 80)
	base.Anchored = true
	base.CanCollide = false
	base.Parent = model

	local straw = Instance.new("Part")
	straw.Name = "Straw"
	straw.Shape = Enum.PartType.Cylinder
	straw.Size = Vector3.new(0.3, 3.6, 3.6)
	straw.Rotation = Vector3.new(0, 0, 90)
	straw.Material = Enum.Material.Grass
	straw.Color = Color3.fromRGB(140, 115, 60)
	straw.Anchored = true
	straw.CanCollide = false
	straw.Parent = model

	local egg = Instance.new("Part")
	egg.Name = "NestEgg"
	egg.Shape = Enum.PartType.Ball
	egg.Size = Vector3.new(1.5, 1.9, 1.5)
	egg.Material = Enum.Material.SmoothPlastic
	egg.Color = Color3.fromRGB(235, 230, 215)
	egg.Anchored = true
	egg.CanCollide = false
	egg.Parent = model

	local glow = Instance.new("PointLight")
	glow.Name = "EggGlow"
	glow.Color = Color3.fromRGB(255, 220, 150)
	glow.Brightness = 0.8
	glow.Range = 7
	glow.Shadows = false
	glow.Parent = egg

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "HatchPrompt"
	prompt.ActionText = "Éclore"
	prompt.ObjectText = "Œuf du refuge"
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = egg

	local spawnLoc = Workspace:FindFirstChildOfClass("SpawnLocation")
	local origin = if spawnLoc then spawnLoc.Position + Vector3.new(7, 2.2, 4) else Vector3.new(7, 11, 4)
	base.Position = origin
	straw.Position = origin + Vector3.new(0, 0.35, 0)
	egg.Position = origin + Vector3.new(0, 1.15, 0)

	model.PrimaryPart = egg
	model.Parent = Workspace
	return egg
end

function NestService:Init(cont)
	log = cont:Get("Log")
	hatchService = cont:Get("HatchService")
	saveService = cont:Get("SaveService")
	used = {}
end

function NestService:Start()
	local nestEgg = BuildNest()
	local prompt = nestEgg:FindFirstChildOfClass("ProximityPrompt")

	prompt.Triggered:Connect(function(player: Player)
		if used[player] then
			return
		end
		local profile = saveService:GetProfile(player)
		if not profile then
			return
		end

		for _, egg in profile.Data.Eggs do
			if egg.Source == "Nest" then
				if hatchService:HatchEggById(player, egg.Id, true) then
					used[player] = true
					log:Economy("Nest", "WorldHatch", { Player = player.Name, EggId = egg.Id })
					nestEgg.Transparency = 1
					local glow = nestEgg:FindFirstChild("EggGlow")
					if glow then
						glow.Enabled = false
					end
					prompt.Enabled = false
				end
				break
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		used[player] = nil
	end)
end

return NestService
