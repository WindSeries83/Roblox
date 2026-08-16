local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiKit = require(script.Parent.Parent.UiKit)
local Net = require(ReplicatedStorage.Shared.Net)
local Config = require(ReplicatedStorage.Shared.Config)
local Species = require(ReplicatedStorage.Shared.Data.Species)
local Stages = require(ReplicatedStorage.Shared.Data.Stages)

local BreedingPanel = {}

local leftList
local rightList
local treeList

local selection = { left = nil, right = nil }

local function CreatureLabel(creature): string
	local species = Species[creature.SpeciesId]
	local name = species and species.Name or creature.SpeciesId
	local stage = Stages[creature.Stage]
	return `[{string.upper(creature.Rarity)}] {name} — G{creature.Generation} — {stage.Name}`
end

local function FindById(creatures, id)
	for _, creature in creatures do
		if creature.Id == id then
			return creature
		end
	end
	return nil
end

local function Ancestors(creatures, creature, depth, seen)
	if not creature or depth <= 0 or seen[creature.Id] then
		return {}
	end
	seen[creature.Id] = true
	local rows = { CreatureLabel(creature) }
	local father = creature.Parents and FindById(creatures, creature.Parents.Father) or nil
	local mother = creature.Parents and FindById(creatures, creature.Parents.Mother) or nil
	for _, row in Ancestors(creatures, father, depth - 1, seen) do
		table.insert(rows, `  {row}`)
	end
	for _, row in Ancestors(creatures, mother, depth - 1, seen) do
		table.insert(rows, `  {row}`)
	end
	return rows
end

local function RenderTree(creatures, creatureId)
	UiKit.Clear(treeList)
	local creature = FindById(creatures, creatureId)
	if not creature then
		return
	end
	for _, row in Ancestors(creatures, creature, 4, {}) do
		local cell = UiKit.Cell(treeList)
		UiKit.Create("TextLabel", {
			BackgroundTransparency = 1,
			TextColor3 = UiKit.TINTS.WHITE,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = row,
			Parent = cell,
		})
	end
end

local function RenderSelectors(state)
	UiKit.Clear(leftList)
	UiKit.Clear(rightList)
	for _, creature in state.Creatures do
		local row = UiKit.Cell(leftList)
		local button = UiKit.Create("TextButton", {
			BackgroundTransparency = 1,
			TextColor3 = UiKit.TINTS.WHITE,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = CreatureLabel(creature),
			Parent = row,
		})
		button.Activated:Connect(function()
			selection.left = creature.Id
			RenderTree(state.Creatures, creature.Id)
		end)
	end
	for _, creature in state.Creatures do
		local row = UiKit.Cell(rightList)
		local button = UiKit.Create("TextButton", {
			BackgroundTransparency = 1,
			TextColor3 = UiKit.TINTS.WHITE,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = CreatureLabel(creature),
			Parent = row,
		})
		button.Activated:Connect(function()
			selection.right = creature.Id
			RenderTree(state.Creatures, creature.Id)
		end)
	end
end

function BreedingPanel.Create(parent)
	local frame = UiKit.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = parent,
	})
	UiKit.Padding(frame, 10)

	UiKit.Title(frame, `Élevage — coût {Config.BREED_COST} Essence, cooldown {Config.BREED_COOLDOWN}s`)

	UiKit.Create("TextLabel", {
		BackgroundTransparency = 1,
		TextColor3 = UiKit.TINTS.WHITE,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0, 0.07),
		Size = UDim2.fromScale(0.3, 0.05),
		Text = "Parent A",
		Parent = frame,
	})
	UiKit.Create("TextLabel", {
		BackgroundTransparency = 1,
		TextColor3 = UiKit.TINTS.WHITE,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.35, 0.07),
		Size = UDim2.fromScale(0.3, 0.05),
		Text = "Parent B",
		Parent = frame,
	})
	UiKit.Create("TextLabel", {
		BackgroundTransparency = 1,
		TextColor3 = UiKit.TINTS.WHITE,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.7, 0.07),
		Size = UDim2.fromScale(0.3, 0.05),
		Text = "Arbre généalogique",
		Parent = frame,
	})

	leftList = UiKit.Scroller(frame, UDim2.fromScale(0, 0.12), UDim2.fromScale(0.3, 0.72))
	rightList = UiKit.Scroller(frame, UDim2.fromScale(0.35, 0.12), UDim2.fromScale(0.3, 0.72))
	treeList = UiKit.Scroller(frame, UDim2.fromScale(0.7, 0.12), UDim2.fromScale(0.3, 0.72))

	local breedButton = UiKit.Button(frame, "Croiser", UDim2.fromScale(0.3, 0.08), UDim2.fromScale(0.35, 0.86))
	breedButton.Activated:Connect(function()
		if selection.left and selection.right then
			Net.BreedCreatures:FireServer(selection.left, selection.right)
		end
	end)

	return frame
end

function BreedingPanel.Refresh(state)
	RenderSelectors(state)
end

return BreedingPanel
