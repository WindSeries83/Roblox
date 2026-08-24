local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiKit = require(script.Parent.Parent.UiKit)
local Net = require(ReplicatedStorage.Shared.Net)
local Config = require(ReplicatedStorage.Shared.Config)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Stages = require(ReplicatedStorage.Shared.Data.Stages)
local Equipment = require(ReplicatedStorage.Shared.Data.Equipment)
local Rarities = require(ReplicatedStorage.Shared.Data.Rarities)
local Evolution = require(ReplicatedStorage.Shared.Evolution)
local Sanctuary = require(ReplicatedStorage.Shared.Sanctuary)
local CreatureHud = require(script.Parent.Parent.CreatureHud)
local HoverCard = require(script.Parent.Parent.HoverCard)
local CreaturePortrait = require(script.Parent.Parent.CreaturePortrait)

local SanctuaryPanel = {}

local creatureList
local detail
local upgradeLabel
local upgradeButton

-- Initiale courte du rang, affichée sur la bande de rareté des cards.
local RANK_LETTER = {
	Common = "C",
	Uncommon = "M",
	Rare = "U",
	Epic = "R",
	Legendary = "E",
	Mythic = "L",
	UltraRare = "M",
	Secret = "S",
}

local function ItemName(item)
	local def = Equipment[item.Type]
	local tier = def and def.Tiers[item.Tier]
	return tier and tier.Name or `{item.Type} T{item.Tier}`
end

local function CreatureLabel(creature): string
	local name = Gameplay.SpeciesName(creature.SpeciesId)
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
		Name = "Header",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 44),
		Parent = frame,
	})
	upgradeLabel = UiKit.Create("TextLabel", {
		Name = "UpgradeLabel",
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
	upgradeButton.Name = "UpgradeButton"
	upgradeButton.Activated:Connect(function()
		Net.UpgradeSanctuary:FireServer()
	end)

	creatureList = UiKit.Scroller(frame, UDim2.fromScale(0, 0.14), UDim2.fromScale(0.5, 0.86))
	creatureList.Name = "CreatureList"
	-- Grille de cards à la place de la liste verticale du Scroller.
	for _, child in creatureList:GetChildren() do
		if child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
	UiKit.Create("UIGridLayout", {
		CellSize = UDim2.fromOffset(150, 170),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = creatureList,
	})

	detail = UiKit.Create("Frame", {
		Name = "Detail",
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
	local bonusSlots = if state.Entitlements and state.Entitlements.MoreSlots
		then Config.GAMEPASSES.MoreSlots.BonusSlots
		else 0
	local maxCreatures = Sanctuary.MaxCreatures(state.SanctuaryLevel, bonusSlots)
	local cost = Sanctuary.UpgradeCost(state.SanctuaryLevel)
	upgradeLabel.Text =
		`Sanctuaire niveau {state.SanctuaryLevel} — {#state.Creatures}/{maxCreatures} créatures\nAméliorer : +{Sanctuary.SLOTS_PER_LEVEL} places (coût {cost} Essence)`
	if state.Essence < cost then
		upgradeButton.BackgroundColor3 = UiKit.TINTS.DARK
	else
		upgradeButton.BackgroundColor3 = UiKit.TINTS.ACCENT
	end

	UiKit.Clear(creatureList)
	-- Tri meute : rang de rareté décroissant puis puissance décroissante.
	local creatures = {}
	for _, creature in state.Creatures do
		table.insert(creatures, creature)
	end
	table.sort(creatures, function(a, b)
		local ra, rb = Gameplay.RarityRank(a.Rarity), Gameplay.RarityRank(b.Rarity)
		if ra ~= rb then
			return ra > rb
		end
		return a.Power > b.Power
	end)

	local selected = detail and detail:GetAttribute("SelectedId") or nil
	for i, creature in creatures do
		local card = UiKit.Card(creatureList, UDim2.fromOffset(150, 170))
		card.Name = `CreatureCard{i}`
		card.LayoutOrder = i

		-- Bande rareté 12px en haut avec l'initiale du rang (texte contrasté).
		local rarityDef = Rarities[creature.Rarity]
		local bandColor = rarityDef and rarityDef.Color or UiKit.TINTS.WHITE
		local luminance = bandColor.R * 0.299 + bandColor.G * 0.587 + bandColor.B * 0.114
		local band = UiKit.Create("Frame", {
			Name = "RarityBand",
			BackgroundColor3 = bandColor,
			Size = UDim2.new(1, 0, 0, 12),
			Parent = card,
		})
		UiKit.Corner(band)
		UiKit.Create("TextLabel", {
			Name = "RankLetter",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Font = Enum.Font.GothamBold,
			TextSize = 10,
			TextColor3 = if luminance > 0.5 then UiKit.TINTS.DARK else UiKit.TINTS.WHITE,
			Text = RANK_LETTER[creature.Rarity] or "?",
			Parent = band,
		})

		local portrait = CreaturePortrait.Create(card, UDim2.new(0, 0, 0, 14), UDim2.new(1, 0, 0, 100))
		CreaturePortrait.Show(portrait, creature.SpeciesId, creature.Rarity, creature.Mutation)

		UiKit.Create("TextLabel", {
			Name = "SpeciesName",
			BackgroundTransparency = 1,
			TextColor3 = UiKit.TINTS.WHITE,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Position = UDim2.new(0, 0, 0, 115),
			Size = UDim2.new(1, 0, 0, 14),
			Text = Gameplay.SpeciesName(creature.SpeciesId),
			Parent = card,
		})

		UiKit.Create("TextLabel", {
			Name = "LevelLine",
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(180, 180, 195),
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Position = UDim2.new(0, 0, 0, 129),
			Size = UDim2.new(0.65, 0, 0, 13),
			Text = `Niv {creature.Level} · {Stages[creature.Stage].Name}`,
			Parent = card,
		})
		UiKit.Create("TextLabel", {
			Name = "PowerLine",
			BackgroundTransparency = 1,
			TextColor3 = UiKit.TINTS.ACCENT,
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Right,
			Position = UDim2.new(0.65, 0, 0, 129),
			Size = UDim2.new(0.35, 0, 0, 13),
			Text = `⚔ {math.floor(creature.Power)}`,
			Parent = card,
		})

		-- Mini-barre XP 6px en bas de card.
		local xpBg = UiKit.Create("Frame", {
			Name = "XpBar",
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.5,
			Position = UDim2.new(0, 0, 0, 145),
			Size = UDim2.new(1, 0, 0, 6),
			Parent = card,
		})
		UiKit.Corner(xpBg)
		local xpFill = UiKit.Create("Frame", {
			Name = "XpFill",
			BackgroundColor3 = UiKit.TINTS.ACCENT,
			Size = UDim2.fromScale(math.clamp(creature.XP / Evolution.XPToNext(creature.Level), 0, 1), 1),
			Parent = xpBg,
		})
		UiKit.Corner(xpFill)

		local hit = UiKit.Create("TextButton", {
			Name = "Hit",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 5,
			Text = "",
			Parent = card,
		})
		hit.Activated:Connect(function()
			detail:SetAttribute("SelectedId", creature.Id)
			RenderDetail(creature, state.Items)
		end)
		HoverCard.Hook(hit, {
			SpeciesId = creature.SpeciesId,
			Rarity = creature.Rarity,
			Mutation = creature.Mutation,
			Level = creature.Level,
			Power = creature.Power,
			SuggestedPrice = CreatureHud.SuggestedPrice(creature.Rarity),
		})
		if creature.Id == selected then
			RenderDetail(creature, state.Items)
		end
	end
end

return SanctuaryPanel
