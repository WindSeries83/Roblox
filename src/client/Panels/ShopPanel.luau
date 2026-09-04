--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiKit = require(script.Parent.Parent.UiKit)
local Net = require(ReplicatedStorage.Shared.Net)
local Config = require(ReplicatedStorage.Shared.Config)

-- Boutique dédiée (bible §4.B) : onglet unique, sections claires, valeur affichée.
local ShopPanel = {}

local TINTS = UiKit.TINTS

local player = Players.LocalPlayer

local potionLabel
local boostLabel
local eclipseLabel
local offerBanner
local passRows: { [string]: TextButton } = {}
local paidRandomButtons: { TextButton } = {}
local paidRandomLabels: { [TextButton]: string } = {}
local paidRandomAllowed = false
local luckPotion
local boostUntil = 0
local eclipseActive = false
local eclipseUntil = 0
local eclipseBonus = 0

local function Prompt(productId)
	if productId and productId ~= 0 then
		MarketplaceService:PromptProductPurchase(player, productId)
	end
end

local function RemainingText(untilTs: number): string?
	local left = untilTs - os.time()
	if left <= 0 then
		return nil
	end
	return string.format("%d:%02d", math.floor(left / 60), left % 60)
end

local function RefreshTimers()
	local left = luckPotion and RemainingText(luckPotion.Until) or nil
	if left then
		potionLabel.Text = `Potion active (+{math.floor(luckPotion.Bonus * 100 + 0.5)} %) — {left} restant`
	else
		potionLabel.Text = "Aucune potion active"
	end

	local serverLeft = RemainingText(boostUntil)
	if serverLeft then
		boostLabel.Text = string.format(
			"Boost serveur actif (+%d %%) — %s restant",
			math.floor(Config.SERVER_BOOST.Bonus * 100 + 0.5),
			serverLeft
		)
	else
		boostLabel.Text = "Pas de boost serveur — achetez-en un, tout le serveur en profite !"
	end

	local eclipseLeft = if eclipseActive then RemainingText(eclipseUntil) else nil
	eclipseLabel.Visible = eclipseLeft ~= nil
	if eclipseLeft then
		eclipseLabel.Text = string.format("Éclipse ! Mutations ×%d — %s restant", 1 + eclipseBonus, eclipseLeft)
	end
end

local function SectionTitle(parent, text: string, layoutOrder: number)
	local title = UiKit.Title(parent, text, 15)
	title.LayoutOrder = layoutOrder
	return title
end

local function ProductRow(parent, def, key, layoutOrder: number)
	local isPaidRandom = def.Kind == "LuckPotion" or def.Kind == "ServerBoost"
	local button = UiKit.Create("TextButton", {
		Name = `Shop_{key}`,
		BackgroundColor3 = TINTS.DARK,
		TextColor3 = TINTS.WHITE,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextWrapped = true,
		Size = UDim2.new(0.32, -6, 0, 52),
		LayoutOrder = layoutOrder,
		Text = if isPaidRandom and not paidRandomAllowed
			then "Indisponible pour ce joueur"
			else def.Name .. if (def.Id or 0) == 0 then "\n(produit à configurer)" else "",
		AutoButtonColor = not isPaidRandom or paidRandomAllowed,
		Parent = parent,
	})
	UiKit.Corner(button)
	button.Activated:Connect(function()
		if isPaidRandom and not paidRandomAllowed then
			return
		end
		Prompt(def.Id)
	end)
	if isPaidRandom then
		table.insert(paidRandomButtons, button)
		paidRandomLabels[button] = button.Text
	end
	return button
end

local function PassRow(parent, key: string, def, layoutOrder: number)
	local row = UiKit.Cell(parent)
	row.LayoutOrder = layoutOrder
	local label = UiKit.Create("TextLabel", {
		Name = `PassLabel_{key}`,
		BackgroundTransparency = 1,
		TextColor3 = TINTS.WHITE,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Size = UDim2.fromScale(0.62, 1),
		Text = def.Name,
		Parent = row,
	})
	local button = UiKit.Button(row, "Acheter", UDim2.new(0.3, 0, 0, 30), UDim2.new(0.68, 0, 0.5, -15))
	button.Name = `PassBuy_{key}`
	button.BackgroundColor3 = TINTS.DARK
	passRows[key] = button
	button.Activated:Connect(function()
		if (def.Id or 0) ~= 0 then
			MarketplaceService:PromptGamePassPurchase(player, def.Id)
		end
	end)
	return label
end

function ShopPanel.Create(parent)
	local frame = UiKit.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = parent,
	})

	UiKit.Title(frame, "Boutique")

	local scroller = UiKit.Scroller(frame, UDim2.fromOffset(0, 28), UDim2.fromScale(1, 1))
	scroller.Name = "ShopScroller"

	-- Section Chance
	SectionTitle(scroller, "Chance", 1)
	potionLabel = UiKit.Create("TextLabel", {
		Name = "PotionState",
		BackgroundTransparency = 1,
		TextColor3 = TINTS.WHITE,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 14),
		LayoutOrder = 2,
		Text = "Aucune potion active",
		Parent = scroller,
	})
	boostLabel = UiKit.Create("TextLabel", {
		Name = "BoostState",
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(255, 215, 94),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 14),
		LayoutOrder = 3,
		Text = "Pas de boost serveur",
		Parent = scroller,
	})
	eclipseLabel = UiKit.Create("TextLabel", {
		Name = "EclipseState",
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(178, 132, 255),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 14),
		LayoutOrder = 4,
		Text = "",
		Visible = false,
		Parent = scroller,
	})
	local chanceRow = UiKit.Create("Frame", {
		Name = "ChanceRow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 52),
		LayoutOrder = 5,
		Parent = scroller,
	})
	UiKit.Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = chanceRow,
	})
	do
		local i = 0
		for key, def in Config.DEV_PRODUCTS do
			if def.Kind == "LuckPotion" or def.Kind == "ServerBoost" then
				i += 1
				ProductRow(chanceRow, def, key, i)
			end
		end
	end

	-- Section Offres
	SectionTitle(scroller, "Offres", 6)
	offerBanner = UiKit.Create("Frame", {
		Name = "FirstOfferBanner",
		BackgroundColor3 = TINTS.ACCENT,
		BackgroundTransparency = 0.7,
		Size = UDim2.new(1, 0, 0, 40),
		LayoutOrder = 7,
		Visible = false,
		Parent = scroller,
	})
	UiKit.Corner(offerBanner)
	UiKit.Padding(offerBanner, 4)
	UiKit.Create("TextLabel", {
		Name = "OfferText",
		BackgroundTransparency = 1,
		TextColor3 = TINTS.WHITE,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.fromScale(0.72, 1),
		Text = "Offre 1re fois : pack de départ −50 %",
		Parent = offerBanner,
	})
	local offerButton = UiKit.Create("TextButton", {
		Name = "OfferBuy",
		BackgroundColor3 = TINTS.ACCENT,
		TextColor3 = TINTS.WHITE,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		Size = UDim2.fromScale(0.26, 1),
		Position = UDim2.fromScale(0.73, 0),
		Text = "Profiter de l'offre",
		Parent = offerBanner,
	})
	UiKit.Corner(offerButton)
	offerButton.Activated:Connect(function()
		local def = Config.DEV_PRODUCTS.FirstPurchaseOffer
		if def then
			Prompt(def.Id)
		end
	end)
	UiKit.Create("TextLabel", {
		Name = "OffersHint",
		BackgroundTransparency = 1,
		TextColor3 = TINTS.WHITE,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 14),
		LayoutOrder = 8,
		Text = "Cadeaux de retour J2/J7 : automatiques à ta prochaine connexion après une absence.",
		Parent = scroller,
	})

	-- Section Essence
	SectionTitle(scroller, "Essence (confort)", 9)
	local essenceRow = UiKit.Create("Frame", {
		Name = "EssenceRow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 52),
		LayoutOrder = 10,
		Parent = scroller,
	})
	UiKit.Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = essenceRow,
	})
	do
		local i = 0
		for key, def in Config.DEV_PRODUCTS do
			if def.Amount then
				i += 1
				ProductRow(essenceRow, def, key, i)
			end
		end
	end

	-- Section Pass & confort
	SectionTitle(scroller, "Pass & confort", 11)
	do
		local i = 0
		for key, def in Config.GAMEPASSES do
			i += 1
			PassRow(scroller, key, def, 11 + i)
		end
	end
	UiKit.Create("TextLabel", {
		Name = "VipSkuNote",
		BackgroundTransparency = 1,
		TextColor3 = TINTS.ACCENT,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 14),
		LayoutOrder = 30,
		Text = "Avec le Pass VIP : −10 % sur les SKUs soldés de la boutique.",
		Parent = scroller,
	})

	task.spawn(function()
		while frame.Parent do
			RefreshTimers()
			task.wait(1)
		end
	end)

	return frame
end

function ShopPanel.Refresh(state)
	luckPotion = state.LuckPotion
	offerBanner.Visible = state.Offers ~= nil
		and state.Offers.FirstPurchaseEligible == true
		and state.Offers.FirstPurchaseClaimed == false
	local entitlements = state.Entitlements
	for key, button in passRows do
		local owned = entitlements ~= nil and entitlements[key] == true
		button.Text = if owned then "Possédé ✓" else "Acheter"
		button.Active = not owned
	end
end

Net.BoostState.OnClientEvent:Connect(function(state)
	boostUntil = state.Until or 0
end)

Net.EclipseState.OnClientEvent:Connect(function(state)
	eclipseActive = state.Active == true
	eclipseUntil = state.Until or 0
	eclipseBonus = state.Bonus or 0
end)

Net.PolicyState.OnClientEvent:Connect(function(policy)
	paidRandomAllowed = policy and policy.ArePaidRandomItemsRestricted ~= true
	for _, button in paidRandomButtons do
		button.AutoButtonColor = paidRandomAllowed
		button.Text = if paidRandomAllowed then paidRandomLabels[button] else "Indisponible pour ce joueur"
	end
end)

return ShopPanel
