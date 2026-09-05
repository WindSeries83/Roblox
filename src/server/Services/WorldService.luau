--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Worlds = require(ReplicatedStorage.Shared.Worlds)
local CreatureTemplates = require(ReplicatedStorage.Shared.CreatureTemplates)

local WorldService = {}

local REGION_COLORS = {
	Color3.fromRGB(72, 58, 105),
	Color3.fromRGB(125, 57, 36),
	Color3.fromRGB(72, 112, 139),
	Color3.fromRGB(43, 31, 76),
}

local function Part(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = Enum.Material.Slate
	part.Anchored = true
	part.Parent = parent
	return part
end

local function Label(parent: BasePart, text: string)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(220, 36)
	gui.StudsOffset = Vector3.new(0, 5, 0)
	gui.AlwaysOnTop = true
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Parent = gui
end

local function Decor(
	parent: Instance,
	name: string,
	size: Vector3,
	position: Vector3,
	color: Color3,
	material: any,
	shape: any?
): Part
	local part = Part(parent, name, size, position, color)
	part.Material = material
	if shape then
		part.Shape = shape
	end
	part.CanCollide = false
	part.CastShadow = false
	return part
end

local function BuildRegionDecor(model: Model, worldId: string, center: Vector3)
	if worldId == "TwilightGrove" then
		local pond = Decor(
			model,
			"GrovePond",
			Vector3.new(44, 0.3, 24),
			center + Vector3.new(25, 2.1, 55),
			Color3.fromRGB(55, 130, 170),
			Enum.Material.Glass
		)
		pond.Transparency = 0.35
		for index, x in { -72, -24, 50 } do
			local trunk = Decor(
				model,
				`GroveTree{index}`,
				Vector3.new(2.2, 11, 2.2),
				center + Vector3.new(x, 7, 62),
				Color3.fromRGB(75, 48, 42),
				Enum.Material.Wood,
				Enum.PartType.Cylinder
			)
			Decor(
				model,
				`GroveCanopy{index}`,
				Vector3.new(12, 8, 12),
				trunk.Position + Vector3.new(0, 7, 0),
				Color3.fromRGB(45, 115, 86),
				Enum.Material.Grass,
				Enum.PartType.Ball
			)
		end
	elseif worldId == "AshForge" then
		local lava = Decor(
			model,
			"ForgeLava",
			Vector3.new(120, 0.25, 12),
			center + Vector3.new(0, 2.1, 58),
			Color3.fromRGB(255, 78, 25),
			Enum.Material.Neon
		)
		lava.Transparency = 0.15
		for index, x in { -72, -42, 42, 72 } do
			Decor(
				model,
				`ForgePillar{index}`,
				Vector3.new(5, 16 + (index % 3) * 2, 5),
				center + Vector3.new(x, 10, -58),
				Color3.fromRGB(54, 42, 48),
				Enum.Material.Basalt,
				Enum.PartType.Cylinder
			)
		end
	elseif worldId == "GalePeaks" then
		for index, x in { -74, -48, 48, 74 } do
			local crystal = Decor(
				model,
				`PeakCrystal{index}`,
				Vector3.new(6, 18 + (index % 4) * 2, 6),
				center + Vector3.new(x, 11, 55),
				Color3.fromRGB(95, 190, 220),
				Enum.Material.Neon,
				Enum.PartType.Wedge
			)
			crystal.CFrame *= CFrame.Angles(0, math.rad(index), math.rad(-8))
		end
		local cloud = Decor(
			model,
			"PeakCloud",
			Vector3.new(90, 2, 18),
			center + Vector3.new(0, 28, -50),
			Color3.fromRGB(185, 225, 240),
			Enum.Material.ForceField
		)
		cloud.Transparency = 0.45
	elseif worldId == "NyxAbyss" then
		local void = Decor(
			model,
			"AbyssPool",
			Vector3.new(120, 0.2, 18),
			center + Vector3.new(0, 2.1, 58),
			Color3.fromRGB(38, 10, 70),
			Enum.Material.Neon
		)
		void.Transparency = 0.2
		for index, x in { -72, -42, 42, 72 } do
			local obelisk = Decor(
				model,
				`AbyssObelisk{index}`,
				Vector3.new(4, 18, 4),
				center + Vector3.new(x, 11, -55),
				Color3.fromRGB(24, 18, 42),
				Enum.Material.Slate
			)
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(178, 80, 255)
			light.Brightness = 1
			light.Range = 12
			light.Parent = obelisk
		end
	end
end

local function BuildRegions()
	if Workspace:FindFirstChild("Worlds") then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "Worlds"
	folder.Parent = Workspace
	for index, world in Worlds.All do
		local model = Instance.new("Model")
		model.Name = world.RegionName
		model:SetAttribute("BossSpecies", world.Boss.SpeciesId)
		model.Parent = folder
		local center = Vector3.new((index - 1) * 240, 0, 360)
		local ground = Part(model, "Ground", Vector3.new(190, 4, 190), center, REGION_COLORS[index])
		Label(ground, world.Name)
		BuildRegionDecor(model, world.Id, center)
		for stage = 1, Worlds.BOSS_STAGE do
			local anchor = Part(
				model,
				if stage == Worlds.BOSS_STAGE then "BossArena" else `Stage{stage}`,
				Vector3.new(18, 1, 18),
				center + Vector3.new(-70 + (stage - 1) * 28, 3, 0),
				if stage == Worlds.BOSS_STAGE then Color3.fromRGB(230, 80, 95) else Color3.fromRGB(110, 200, 180)
			)
			anchor:SetAttribute("Stage", stage)
			if stage == Worlds.BOSS_STAGE then
				Label(anchor, world.Boss.SpeciesId)
				local template = CreatureTemplates.Get(world.Boss.SpeciesId)
				if template then
					local boss = template:Clone()
					boss.Name = "BossAlpha"
					boss.Parent = model
					if boss:IsA("Model") then
						boss:PivotTo(anchor.CFrame + Vector3.new(0, 3, 0))
					elseif boss:IsA("BasePart") then
						boss.CFrame = anchor.CFrame + Vector3.new(0, 3, 0)
					end
				end
			end
		end
	end
end

local function BuildSharedSanctuaries()
	if Workspace:FindFirstChild("SharedSanctuaries") then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "SharedSanctuaries"
	folder.Parent = Workspace
	for index = 1, 3 do
		local pad = Part(
			folder,
			`Sanctuary{index}`,
			Vector3.new(42, 2, 42),
			Vector3.new((index - 2) * 55, 2, 145),
			Color3.fromRGB(65 + index * 20, 105, 90 + index * 20)
		)
		Label(pad, `Sanctuaire partagé {index}`)
	end
end

local function BuildPlot(player: Player)
	local folder = Workspace:FindFirstChild("PlayerPlots")
	if not folder or folder:FindFirstChild(tostring(player.UserId)) then
		return
	end
	local slot = #folder:GetChildren()
	local plot = Part(
		folder,
		tostring(player.UserId),
		Vector3.new(70, 2, 70),
		Vector3.new(-180 + (slot % 4) * 90, 1, -120 - math.floor(slot / 4) * 90),
		Color3.fromRGB(62, 82, 70)
	)
	plot:SetAttribute("OwnerUserId", player.UserId)
	plot:SetAttribute("ReadOnlyVisitors", true)
	Label(plot, `Plot de {player.DisplayName}`)
end

function WorldService:GetPlot(ownerUserId: number): BasePart?
	if type(ownerUserId) ~= "number" or ownerUserId ~= math.floor(ownerUserId) or ownerUserId <= 0 then
		return nil
	end
	local plots = Workspace:FindFirstChild("PlayerPlots")
	local plot = plots and plots:FindFirstChild(tostring(ownerUserId))
	return if plot and plot:IsA("BasePart") and plot:GetAttribute("OwnerUserId") == ownerUserId then plot else nil
end

function WorldService:Start()
	BuildRegions()
	BuildSharedSanctuaries()
	local plots = Workspace:FindFirstChild("PlayerPlots") or Instance.new("Folder")
	plots.Name = "PlayerPlots"
	plots.Parent = Workspace
	for _, player in Players:GetPlayers() do
		BuildPlot(player)
	end
	Players.PlayerAdded:Connect(BuildPlot)
	Players.PlayerRemoving:Connect(function(player)
		local plot = plots:FindFirstChild(tostring(player.UserId))
		if plot then
			plot:Destroy()
		end
	end)
end

return WorldService
