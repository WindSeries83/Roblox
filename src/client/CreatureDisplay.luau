local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Net = require(ReplicatedStorage.Shared.Net)
local Rarities = require(ReplicatedStorage.Shared.Data.Rarities)
local Mutations = require(ReplicatedStorage.Shared.Data.Mutations)

local CreatureDisplay = {}

local spawned: { [string]: Model } = {}
local sanctuary: Folder? = nil

local function DisplayColor(creature): Color3
	if creature.Mutation ~= false and Mutations[creature.Mutation] then
		return Mutations[creature.Mutation].Color
	end
	return Rarities[creature.Rarity].Color
end

local function PrepareClone(model: Model)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end
	if not model.PrimaryPart then
		local first = model:FindFirstChildOfClass("BasePart")
		if first then
			model.PrimaryPart = first
		end
	end
end

local function GridPosition(index: number): CFrame
	local row = math.floor((index - 1) / 8)
	local column = (index - 1) % 8
	return CFrame.new(-36 + column * 3, 3, -18 + row * 3) * CFrame.Angles(0, math.rad(180), 0)
end

function CreatureDisplay.Refresh(state)
	local templates = Workspace:FindFirstChild("Creatures")
	if not templates then
		return
	end

	if not sanctuary or not sanctuary.Parent then
		sanctuary = Instance.new("Folder")
		sanctuary.Name = "SanctuaryDisplay"
		sanctuary.Parent = Workspace
	end

	local alive = {}
	for _, creature in state.Creatures do
		alive[creature.Id] = true
	end
	for id, model in spawned do
		if not alive[id] then
			model:Destroy()
			spawned[id] = nil
		end
	end

	local index = 0
	for _, creature in state.Creatures do
		index += 1
		local model = spawned[creature.Id]
		if not model or not model.Parent then
			local template = templates:FindFirstChild(creature.SpeciesId)
			if not template then
				continue
			end
			model = template:Clone()
			model.Name = `Display_{creature.SpeciesId}`
			PrepareClone(model)
			model.Parent = sanctuary
			spawned[creature.Id] = model
		end

		local scale = 1 + (creature.Stage - 1) * 0.25
		if model.PrimaryPart then
			model:PivotTo(GridPosition(index))
			pcall(function()
				model:ScaleTo(scale)
			end)
		end
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.Color = DisplayColor(creature)
			end
		end
	end
end

Net.Sync.OnClientEvent:Connect(function(state)
	CreatureDisplay.Refresh(state)
end)

return CreatureDisplay
