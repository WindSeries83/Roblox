local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiKit = require(script.Parent.Parent.UiKit)
local Net = require(ReplicatedStorage.Shared.Net)
local Species = require(ReplicatedStorage.Shared.Data.Species)
local Stages = require(ReplicatedStorage.Shared.Data.Stages)
local Equipment = require(ReplicatedStorage.Shared.Data.Equipment)
local Evolution = require(ReplicatedStorage.Shared.Evolution)
local Sanctuary = require(ReplicatedStorage.Shared.Sanctuary)

local SanctuaryPanel = {}

local creatureList
local detail
local upgradeLabel
local upgradeButton

local function ItemName(item)
	local def = Equipment[item.Type]
	local tier = def and def.Tiers[item.Tier]
	return tier and tier.Name or `{item.Type} T{item.Tier}`
end

local function CreatureLabel(creature): string
	local species = Species[creature.SpeciesId]
	local name = species and species.Name or creature.SpeciesId
	local stage = Stages[creature.Stage]
	return `[{string.upper(creature.Rarity)}] {name} — {stage.Name} — Niv. {creature.Level} — {creature.Power}`
end

local function RenderDetail(creature, items)
	UiKit.Clear(detail)

	if not creature then
		UiKit.Title(detail, "Sélectionne une créature")
		return
	end

	UiKit.Title(detail, CreatureLabel(creature))
	if creature.Mutation ~= false then
		UiKit.Title(detail, `Mutation : {creature.Mutation} — Génération {creature.Generation}`, 14)
	end

	local xpLabel, xpFill = UiKit.Bar(detail, UiKit.TINTS.ACCENT)
	UiKit.SetBar(xpFill, xpLabel, creature.XP, Evolution.XPToNext(creature.Level))

	local canEvolve, reason = Evolution.CanEvolve(creature, 1e18)
	local evolveText = if canEvolve
		then `Évoluer (stade {creature.Stage + 1}, {Evolution.EvolveCost(creature)} Essence)`
		else `Évolution : {reason}`
	local evolveButton = UiKit.Button(detail, evolveText, UDim2.fromScale(1, 0.08))
	if canEvolve then
		evolveButton.Activated:Connect(function()
			Net.EvolveCreature:FireServer(creature.Id)
		end)
	else
		evolveButton.BackgroundColor3 = UiKit.TINTS.DARK
		evolveButton.TextColor3 = Color3.fromRGB(150, 150, 160)
	end

	UiKit.Title(detail, `Équipement ({#creature.Equipment}/{Evolution.SlotsForStage(creature.Stage)})`, 14)
	for _, item in creature.Equipment do
		local row = UiKit.Cell(detail)
		local label = UiKit.Create("TextLabel", {
			BackgroundTransparency = 1,
			TextColor3 = UiKit.TINTS.WHITE,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = ItemName(item),
			Parent = row,
		})
		label.Size = UDim2.new(0.6, 0, 0, 24)
		local button = UiKit.Button(row, "Déséquiper", UDim2.new(0.4, 0, 0, 24), UDim2.fromScale(0.6, 0))
		button.BackgroundColor3 = UiKit.TINTS.DARK
		button.Activated:Connect(function()
			Net.UnequipItem:FireServer(creature.Id, item.Id)
		end)
	end

	UiKit.Title(detail, "Inventaire", 14)
	for _, item in items do
		local row = UiKit.Cell(detail)
		UiKit.Create("TextLabel", {
			BackgroundTransparency = 1,
			TextColor3 = UiKit.TINTS.WHITE,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(0.6, 0, 0, 24),
			Text = ItemName(item),
			Parent = row,
		})
		local button = UiKit.Button(row, "Équiper", UDim2.new(0.4, 0, 0, 24), UDim2.fromScale(0.6, 0))
		button.BackgroundColor3 = UiKit.TINTS.DARK
		button.Activated:Connect(function()
			Net.EquipItem:FireServer(creature.Id, item.Id)
		end)
	end
end

function SanctuaryPanel.Create(parent)
	local frame = UiKit.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = parent,
	})
	UiKit.Padding(frame, 10)

	UiKit.Title(frame, "Créatures")

	local header = UiKit.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 44),
		Parent = frame,
	})
	upgradeLabel = UiKit.Create("TextLabel", {
		BackgroundTransparency = 1,
		TextColor3 = UiKit.TINTS.WHITE,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(0.6, 0, 0, 44),
		Text = "",
		TextWrapped = true,
		Parent = header,
	})
	upgradeButton = UiKit.Button(header, "Améliorer", UDim2.new(0.35, 0, 0, 32), UDim2.new(0.65, 0, 0.5, -16))
	upgradeButton.Activated:Connect(function()
		Net.UpgradeSanctuary:FireServer()
	end)

	creatureList = UiKit.Scroller(frame, UDim2.fromScale(0, 0.14), UDim2.fromScale(0.5, 0.86))

	detail = UiKit.Create("Frame", {
		BackgroundColor3 = UiKit.TINTS.PANEL,
		Position = UDim2.fromScale(0.52, 0.14),
		Size = UDim2.fromScale(0.48, 0.86),
		Parent = frame,
	})
	UiKit.Corner(detail)
	UiKit.Padding(detail, 10)
	UiKit.Create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = detail,
	})

	return frame
end

function SanctuaryPanel.Refresh(state)
	local maxCreatures = Sanctuary.MaxCreatures(state.SanctuaryLevel)
	local cost = Sanctuary.UpgradeCost(state.SanctuaryLevel)
	upgradeLabel.Text =
		`Sanctuaire niveau {state.SanctuaryLevel} — {#state.Creatures}/{maxCreatures} créatures\nAméliorer : +{Sanctuary.SLOTS_PER_LEVEL} places (coût {cost} Essence)`
	if state.Essence < cost then
		upgradeButton.BackgroundColor3 = UiKit.TINTS.DARK
	else
		upgradeButton.BackgroundColor3 = UiKit.TINTS.ACCENT
	end

	UiKit.Clear(creatureList)
	local selected = detail and detail:GetAttribute("SelectedId") or nil
	for _, creature in state.Creatures do
		local row = UiKit.Cell(creatureList)
		local button = UiKit.Create("TextButton", {
			BackgroundTransparency = 1,
			TextColor3 = UiKit.TINTS.WHITE,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextWrapped = true,
			Text = CreatureLabel(creature),
			Parent = row,
		})
		button.Activated:Connect(function()
			detail:SetAttribute("SelectedId", creature.Id)
			RenderDetail(creature, state.Items)
		end)
		if creature.Id == selected then
			RenderDetail(creature, state.Items)
		end
	end
end

return SanctuaryPanel
