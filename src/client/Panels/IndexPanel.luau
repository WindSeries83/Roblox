local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiKit = require(script.Parent.Parent.UiKit)
local Index = require(ReplicatedStorage.Shared.Index)
local Rarities = require(ReplicatedStorage.Shared.Data.Rarities)
local CreaturePortrait = require(script.Parent.Parent.CreaturePortrait)

local IndexPanel = {}

-- Doré du préfixe « ✓ » des familles complétées.
local GOLD = Color3.fromRGB(255, 215, 94)

local summaryLabel
local pages -- { { Name, Page } } — « Tout » en premier, puis une page par famille
local tabButtons -- { [family] = TextButton }
local catalog

-- Page de grille pokédex : scroller + UIGridLayout de cards 150×170.
local function MakeGridPage(parent: Instance, name: string, position: UDim2, size: UDim2): ScrollingFrame
	local page = UiKit.Scroller(parent, position, size)
	page.Name = `{name}Page`
	for _, child in page:GetChildren() do
		if child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
	UiKit.Create("UIGridLayout", {
		CellSize = UDim2.fromOffset(150, 170),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = page,
	})
	return page
end

-- Card d'une espèce du catalogue : owned (badge compteur), discovered (bandeau
-- « Découverte ») ou unknown (portrait silhouette, nom et rang masqués).
local function RenderCatalogCard(page: Instance, order: number, entry, cardState: string, count: number?)
	local card = UiKit.Card(page, UDim2.fromOffset(150, 170))
	card.Name = `IndexCard{entry.SpeciesId}`
	card.LayoutOrder = order

	local known = cardState ~= "unknown"
	local portrait = CreaturePortrait.Create(card, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 100))
	CreaturePortrait.Show(portrait, entry.SpeciesId, entry.Rarity, false, not known)

	UiKit.Create("TextLabel", {
		Name = "SpeciesName",
		BackgroundTransparency = 1,
		TextColor3 = UiKit.TINTS.WHITE,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromOffset(0, 102),
		Size = UDim2.new(1, 0, 0, 16),
		Text = if known then entry.Name else "???",
		Parent = card,
	})
	UiKit.Create("TextLabel", {
		Name = "RarityLine",
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(180, 180, 195),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromOffset(0, 118),
		Size = UDim2.new(1, 0, 0, 12),
		Text = if known then `{entry.Family} · {Rarities[entry.Rarity].Name}` else "—",
		Parent = card,
	})

	if cardState == "owned" and count and count > 0 then
		UiKit.Create("TextLabel", {
			Name = "CountBadge",
			BackgroundColor3 = UiKit.TINTS.GREEN,
			TextColor3 = UiKit.TINTS.DARK,
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			Size = UDim2.fromOffset(38, 16),
			Position = UDim2.new(1, -2, 0, 2),
			AnchorPoint = Vector2.new(1, 0),
			Text = `x{count}`,
			Parent = card,
		})
	elseif cardState == "discovered" then
		UiKit.Create("TextLabel", {
			Name = "DiscoveryBanner",
			BackgroundColor3 = UiKit.TINTS.PANEL,
			TextColor3 = UiKit.TINTS.WHITE,
			TextSize = 11,
			Size = UDim2.new(1, 0, 0, 14),
			Position = UDim2.new(0, 0, 1, -14),
			Text = "Découverte",
			Parent = card,
		})
	end
end

function IndexPanel.Create(parent)
	local frame = UiKit.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = parent,
	})
	UiKit.Padding(frame, 10)

	UiKit.Title(frame, "Index")

	summaryLabel = UiKit.Create("TextLabel", {
		Name = "SummaryLabel",
		BackgroundTransparency = 1,
		TextColor3 = UiKit.TINTS.ACCENT,
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0, 0.06),
		Size = UDim2.new(1, 0, 0, 20),
		Text = "",
		Parent = frame,
	})

	catalog = Index.Catalog()

	-- Familles uniques dans l'ordre du catalogue ; une page par famille + « Tout ».
	pages = {}
	tabButtons = {}
	local families = {}
	local seenFamilies = {}
	for _, entry in catalog do
		if not seenFamilies[entry.Family] then
			seenFamilies[entry.Family] = true
			table.insert(families, entry.Family)
		end
	end

	local tabBarSlot = UiKit.Create("Frame", {
		Name = "TabBarSlot",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0, 0.13),
		Size = UDim2.new(1, 0, 0, 28),
		Parent = frame,
	})
	pages[1] =
		{ Name = "Tout", Page = MakeGridPage(frame, "Tout", UDim2.new(0, 0, 0.13, 32), UDim2.new(1, 0, 0.87, -36)) }
	for i, family in families do
		pages[i + 1] =
			{ Name = family, Page = MakeGridPage(frame, family, UDim2.new(0, 0, 0.13, 32), UDim2.new(1, 0, 0.87, -36)) }
	end
	UiKit.SubTabs(tabBarSlot, 28, pages)

	-- Références des boutons pour le préfixe ✓ doré au refresh.
	for i, child in tabBarSlot:GetChildren() do
		if child:IsA("TextButton") then
			child.RichText = true
			tabButtons[pages[i].Name] = child
		end
	end
	return frame
end

function IndexPanel.Refresh(state)
	-- Header : découvertes / total + bonus rendement.
	local total = #catalog
	local decouvertes = 0
	for _, entry in catalog do
		if Index.EntryState(state.Index, entry.SpeciesId, state.Creatures) ~= "unknown" then
			decouvertes += 1
		end
	end
	local mult = Index.ComputeMult(state.Index)
	summaryLabel.Text = `{decouvertes}/{total} découvertes — Bonus +{math.floor((mult - 1) * 100)} %`

	-- Préfixe ✓ doré sur les onglets des familles complétées.
	local completions = Index.FamilyCompletions(state.Index)
	for name, button in tabButtons do
		button.Text = if completions[name] then `<font color="{UiKit.Hex(GOLD)}">✓</font> {name}` else name
	end

	-- Compteurs possédées par espèce (badge xN).
	local counts = {}
	for _, creature in state.Creatures do
		counts[creature.SpeciesId] = (counts[creature.SpeciesId] or 0) + 1
	end

	-- Chaque espèce rendue sur sa page famille ET sur la page Tout.
	for _, page in pages do
		UiKit.Clear(page.Page)
	end
	for order, entry in catalog do
		local cardState = Index.EntryState(state.Index, entry.SpeciesId, state.Creatures)
		RenderCatalogCard(pages[1].Page, order, entry, cardState, counts[entry.SpeciesId])
		for _, page in pages do
			if page.Name == entry.Family then
				RenderCatalogCard(page.Page, order, entry, cardState, counts[entry.SpeciesId])
			end
		end
	end
end

return IndexPanel
