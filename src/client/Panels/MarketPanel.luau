local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiKit = require(script.Parent.Parent.UiKit)
local Audio = require(script.Parent.Parent.Audio)
local Net = require(ReplicatedStorage.Shared.Net)
local Config = require(ReplicatedStorage.Shared.Config)
local Species = require(ReplicatedStorage.Shared.Data.Species)
local CreatureHud = require(script.Parent.Parent.CreatureHud)
local HoverCard = require(script.Parent.Parent.HoverCard)

local MarketPanel = {}

local TINTS = UiKit.TINTS

local myUserId = Players.LocalPlayer.UserId

local subBar
local sellHeader
local buyPage
local sellPage
local minePage
local priceBox
local sellStatus
local marketListings = {}

local function SpeciesName(creature): string
	local species = Species[creature.SpeciesId]
	return species and species.Name or creature.SpeciesId
end

local function CreatureLine(creature): string
	local mutation = creature.Mutation ~= false and ` {creature.Mutation}` or ""
	return `[{string.upper(creature.Rarity)}] {SpeciesName(creature)} — Niv. {creature.Level}{mutation}`
end

local function HookHover(cell: Instance, creature, price: number)
	cell.MouseEnter:Connect(function()
		HoverCard.Show(cell, {
			SpeciesId = creature.SpeciesId,
			Rarity = creature.Rarity,
			Mutation = creature.Mutation,
			Level = creature.Level,
			Power = creature.Power,
			SuggestedPrice = price,
		})
	end)
	cell.MouseLeave:Connect(function()
		HoverCard.Hide()
	end)
end

local function ShowPage(page: Instance)
	for _, tab in subBar:GetChildren() do
		if tab:IsA("TextButton") then
			tab.BackgroundColor3 = TINTS.DARK
		end
	end
	local button = subBar:FindFirstChild(`Tab_{page.Name}`)
	if button then
		button.BackgroundColor3 = TINTS.PANEL
	end
	buyPage.Visible = page == buyPage
	sellPage.Visible = page == sellPage
	minePage.Visible = page == minePage
	sellHeader.Visible = page == sellPage
end

local function SellRow(creature)
	local cell = UiKit.Cell(sellPage)
	HookHover(cell, creature, CreatureHud.SuggestedPrice(creature.Rarity))
	UiKit.Create("TextLabel", {
		BackgroundTransparency = 1,
		TextColor3 = TINTS.WHITE,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.fromScale(0.62, 1),
		Text = CreatureLine(creature),
		TextWrapped = true,
		Parent = cell,
	})
	local button = UiKit.Button(cell, "Vendre", UDim2.new(0.3, 0, 0, 28), UDim2.new(0.68, 0, 0.5, -14))
	button.Activated:Connect(function()
		local price = tonumber(priceBox.Text)
		if not price or price < Config.MARKET_MIN_PRICE or price > Config.MARKET_MAX_PRICE then
			sellStatus.Text = `Prix invalide ({Config.MARKET_MIN_PRICE}-{Config.MARKET_MAX_PRICE})`
			sellStatus.TextColor3 = TINTS.RED
			return
		end
		Audio.Play("CoinReward")
		Net.MarketList:FireServer(creature.Id, price)
		sellStatus.Text = "Mise en vente…"
		sellStatus.TextColor3 = TINTS.GREEN
	end)
end

local function BuyRow(listing, essence)
	local cell = UiKit.Cell(buyPage)
	local creature = listing.Creature
	HookHover(cell, creature, listing.Price)
	UiKit.Create("TextLabel", {
		BackgroundTransparency = 1,
		TextColor3 = TINTS.WHITE,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.fromScale(0.58, 1),
		Text = `{listing.SellerName} — {CreatureLine(creature)}`,
		TextWrapped = true,
		Parent = cell,
	})
	local canAfford = essence >= listing.Price
	local button =
		UiKit.Button(cell, `{listing.Price} Essence`, UDim2.new(0.36, 0, 0, 28), UDim2.new(0.62, 0, 0.5, -14))
	if canAfford then
		button.Text = `Acheter ({listing.Price})`
		button.Activated:Connect(function()
			Audio.Play("CoinReward")
			Net.MarketBuy:FireServer(listing.Id)
		end)
	else
		button.BackgroundColor3 = TINTS.DARK
		button.TextColor3 = Color3.fromRGB(150, 150, 160)
	end
end

local function MineRow(listing)
	local cell = UiKit.Cell(minePage)
	local creature = listing.Creature
	HookHover(cell, creature, listing.Price)
	UiKit.Create("TextLabel", {
		BackgroundTransparency = 1,
		TextColor3 = TINTS.WHITE,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.fromScale(0.58, 1),
		Text = CreatureLine(creature),
		TextWrapped = true,
		Parent = cell,
	})
	local remaining = listing.WithdrawAt and (listing.WithdrawAt - os.time()) or 0
	local label = if remaining > 0
		then `Retrait dans {remaining}s`
		else if listing.WithdrawAt then "Confirmer le retrait" else "Retirer"
	local button = UiKit.Button(cell, label, UDim2.new(0.36, 0, 0, 28), UDim2.new(0.62, 0, 0.5, -14))
	if remaining > 0 then
		button.BackgroundColor3 = TINTS.DARK
		button.TextColor3 = Color3.fromRGB(150, 150, 160)
	else
		button.Activated:Connect(function()
			Audio.Play("UiClick")
			Net.MarketRemove:FireServer(listing.Id)
		end)
	end
end

function MarketPanel.Create(parent: Instance): Frame
	local panel = UiKit.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = parent,
	})
	UiKit.Padding(panel, 10)

	subBar = UiKit.Create("Frame", {
		Name = "SubBar",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 30),
		Parent = panel,
	})
	local tabs = { { "Acheter", "Tab_Acheter" }, { "Vendre", "Tab_Vendre" }, { "Mes ventes", "Tab_MesVentes" } }
	for i, tabDef in tabs do
		local name, tabName = tabDef[1], tabDef[2]
		local button = UiKit.Create("TextButton", {
			Name = tabName,
			BackgroundColor3 = TINTS.DARK,
			TextColor3 = TINTS.WHITE,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			Size = UDim2.new(0.33, -4, 1, 0),
			Position = UDim2.new(0.33 * (i - 1), 2, 0, 0),
			Text = name,
			Parent = subBar,
		})
		UiKit.Corner(button)
	end
	subBar.Tab_Acheter.Activated:Connect(function()
		ShowPage(buyPage)
	end)
	subBar.Tab_Vendre.Activated:Connect(function()
		ShowPage(sellPage)
	end)
	subBar.Tab_MesVentes.Activated:Connect(function()
		ShowPage(minePage)
	end)

	sellHeader = UiKit.Create("Frame", {
		Name = "SellHeader",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 36),
		Position = UDim2.fromOffset(0, 34),
		Parent = panel,
	})
	priceBox = UiKit.Create("TextBox", {
		Name = "PriceBox",
		BackgroundColor3 = TINTS.DARK,
		TextColor3 = TINTS.WHITE,
		PlaceholderColor3 = Color3.fromRGB(150, 150, 160),
		Font = Enum.Font.Gotham,
		TextSize = 14,
		Text = "",
		PlaceholderText = `Prix (min {Config.MARKET_MIN_PRICE})`,
		Size = UDim2.new(0.6, 0, 0, 30),
		Parent = sellHeader,
	})
	UiKit.Corner(priceBox)
	sellStatus = UiKit.Create("TextLabel", {
		BackgroundTransparency = 1,
		TextColor3 = TINTS.WHITE,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		Size = UDim2.new(0.38, 0, 0, 30),
		Text = "",
		Parent = sellHeader,
	})

	buyPage = UiKit.Scroller(panel, UDim2.fromOffset(0, 74), UDim2.new(1, 0, 1, -80))
	buyPage.Name = "BuyPage"
	sellPage = UiKit.Scroller(panel, UDim2.fromOffset(0, 74), UDim2.new(1, 0, 1, -80))
	sellPage.Name = "SellPage"
	minePage = UiKit.Scroller(panel, UDim2.fromOffset(0, 74), UDim2.new(1, 0, 1, -80))
	minePage.Name = "MinePage"
	sellHeader.Visible = false
	minePage.Visible = false
	ShowPage(buyPage)

	Net.MarketSync.OnClientEvent:Connect(function(payload)
		marketListings = payload and payload.Listings or {}
		if MarketPanel.Refresh then
			MarketPanel.Refresh(MarketPanel.lastState)
		end
	end)

	task.spawn(function()
		task.wait(1)
		Net.MarketListings:FireServer()
	end)

	return panel
end

function MarketPanel.Refresh(state)
	state = state or {}
	MarketPanel.lastState = state
	UiKit.Clear(sellPage)
	UiKit.Clear(buyPage)
	UiKit.Clear(minePage)

	UiKit.Title(sellPage, "Choisis une créature à vendre")
	local myListings = 0
	for _, listing in marketListings do
		if listing.SellerUserId == myUserId then
			myListings += 1
		end
	end
	if myListings >= Config.MARKET_MAX_LISTINGS then
		UiKit.Create("TextLabel", {
			BackgroundTransparency = 1,
			TextColor3 = TINTS.RED,
			TextSize = 13,
			TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 18),
			Text = `Nombre de ventes maximum atteint ({Config.MARKET_MAX_LISTINGS})`,
			Parent = sellPage,
		})
	end

	local listedCreatureIds = {}
	for _, listing in marketListings do
		listedCreatureIds[listing.Creature.Id] = true
	end
	for _, creature in state.Creatures or {} do
		if not listedCreatureIds[creature.Id] then
			SellRow(creature)
		end
	end

	local essence = state.Essence or 0
	for _, listing in marketListings do
		if listing.SellerUserId ~= myUserId then
			BuyRow(listing, essence)
		end
	end

	UiKit.Title(minePage, "Tes ventes en cours")
	for _, listing in marketListings do
		if listing.SellerUserId == myUserId then
			MineRow(listing)
		end
	end
	if myListings == 0 then
		UiKit.Create("TextLabel", {
			BackgroundTransparency = 1,
			TextColor3 = TINTS.WHITE,
			TextSize = 13,
			TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 18),
			Text = "Aucune créature en vente.",
			Parent = minePage,
		})
	end
end

return MarketPanel
