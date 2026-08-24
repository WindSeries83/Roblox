local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiKit = require(script.Parent.Parent.UiKit)
local Net = require(ReplicatedStorage.Shared.Net)
local Config = require(ReplicatedStorage.Shared.Config)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Mutations = require(ReplicatedStorage.Shared.Data.Mutations)
local Stages = require(ReplicatedStorage.Shared.Data.Stages)

local BreedingPanel = {}

local leftList
local rightList
local treeList

local selection = { left = nil, right = nil }

local function Pct(value: number): string
	return `{math.floor(value * 100 + 0.5)} %`
end

local function InheritanceText(): string
	return `Héritage : même mutation des deux parents {Pct(Config.BREED_INHERIT_SAME)} · mutations différentes {Pct(
		Config.BREED_INHERIT_ONE
	)} chacune · un seul parent muté {Pct(Config.BREED_INHERIT_SINGLE)}`
end

local function MutationRatesText(weights: { [string]: number }): string
	return UiKit.DropRatesText(weights, function(rate)
		local mutation = Mutations[rate.Id]
		if rate.Id == "None" or not mutation then
			return `Aucune {string.format("%g", rate.Percent)} %`
		end
		return `<font color="{UiKit.Hex(mutation.Color)}">{mutation.Name} ×{mutation.Multiplier} {string.format(
			"%g",
			rate.Percent
		)} %</font>`
	end)
end

local function CreatureLabel(creature): string
	local name = Gameplay.SpeciesName(creature.SpeciesId)
	local stage = Stages[creature.Stage]
	return `[{string.upper(creature.Rarity)}] {name} — G{creature.Generation} — {stage.Name}`
end

local function Ancestors(creatures, creature, depth, seen)
	if not creature or depth <= 0 or seen[creature.Id] then
		return {}
	end
	seen[creature.Id] = true
	local rows = { CreatureLabel(creature) }
	local father = creature.Parents and Gameplay.FindCreature(creatures, creature.Parents.Father) or nil
	local mother = creature.Parents and Gameplay.FindCreature(creatures, creature.Parents.Mother) or nil
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
	local creature = Gameplay.FindCreature(creatures, creatureId)
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
	for _, side in { { list = leftList, key = "left" }, { list = rightList, key = "right" } } do
		UiKit.Clear(side.list)
		for _, creature in state.Creatures do
			local row = UiKit.Cell(side.list)
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
				selection[side.key] = creature.Id
				RenderTree(state.Creatures, creature.Id)
			end)
		end
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

	leftList = UiKit.Scroller(frame, UDim2.fromScale(0, 0.12), UDim2.fromScale(0.3, 0.66))
	leftList.Name = "LeftList"
	rightList = UiKit.Scroller(frame, UDim2.fromScale(0.35, 0.12), UDim2.fromScale(0.3, 0.66))
	rightList.Name = "RightList"
	treeList = UiKit.Scroller(frame, UDim2.fromScale(0.7, 0.12), UDim2.fromScale(0.3, 0.66))
	treeList.Name = "TreeList"

	UiKit.Create("TextLabel", {
		Name = "ChancesInherit",
		RichText = true,
		BackgroundTransparency = 1,
		TextColor3 = UiKit.TINTS.WHITE,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Position = UDim2.fromScale(0, 0.79),
		Size = UDim2.fromScale(1, 0.03),
		Text = InheritanceText(),
		Parent = frame,
	})
	UiKit.Create("TextLabel", {
		Name = "ChancesMutation",
		RichText = true,
		BackgroundTransparency = 1,
		TextColor3 = UiKit.TINTS.WHITE,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Position = UDim2.fromScale(0, 0.825),
		Size = UDim2.fromScale(1, 0.03),
		Text = `Chances : {MutationRatesText(Config.BREED_MUTATION_WEIGHTS)}`,
		Parent = frame,
	})

	local breedButton = UiKit.Button(frame, "Croiser", UDim2.fromScale(0.3, 0.08), UDim2.fromScale(0.35, 0.86))
	breedButton.Name = "BreedButton"
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
