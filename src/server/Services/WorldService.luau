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
		Part(model, "Ground", Vector3.new(190, 4, 190), center, REGION_COLORS[index])
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
