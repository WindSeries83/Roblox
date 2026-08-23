local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiKit = require(script.Parent.Parent.UiKit)
local Net = require(ReplicatedStorage.Shared.Net)
local Config = require(ReplicatedStorage.Shared.Config)

local ShopPanel = {}

local player = Players.LocalPlayer

local potionLabel
local boostLabel
local eclipseLabel
local offerBanner
local buyButtons: { [string]: TextButton } = {}
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

local function MakeProductRow(parent, def, key)
	local button = UiKit.Create("TextButton", {
		Name = `Shop_{key}`,
		BackgroundColor3 = UiKit.TINTS.DARK,
		TextColor3 = UiKit.TINTS.WHITE,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextWrapped = true,
		Size = UDim2.new(0.32, -6, 1, 0),
		Text = `{def.Name}\n(produit à configurer)`,
		Parent = parent,
	})
	UiKit.Corner(button)
	buyButtons[key] = button
	button.Activated:Connect(function()
		Prompt(def.Id)
	end)
end

function ShopPanel.Create(parent)
	local frame = UiKit.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = parent,
	})
	UiKit.Padding(frame, 10)

	UiKit.Title(frame, "Boutique")

	potionLabel = UiKit.Create("TextLabel", {
		Name = "PotionState",
		RichText = false,
		BackgroundTransparency = 1,
		TextColor3 = UiKit.TINTS.WHITE,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0, 0.07),
		Size = UDim2.fromScale(1, 0.04),
		Text = "Aucune potion active",
		Parent = frame,
	})

	boostLabel = UiKit.Create("TextLabel", {
		Name = "BoostState",
		RichText = false,
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(255, 215, 94),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0, 0.115),
		Size = UDim2.fromScale(1, 0.04),
		Text = "Pas de boost serveur",
		Parent = frame,
	})

	eclipseLabel = UiKit.Create("TextLabel", {
		Name = "EclipseState",
		RichText = false,
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(178, 132, 255),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0, 0.16),
		Size = UDim2.fromScale(1, 0.04),
		Text = "",
		Visible = false,
		Parent = frame,
	})

	local chanceRow = UiKit.Create("Frame", {
		Name = "ChanceRow",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0, 0.21),
		Size = UDim2.fromScale(1, 0.14),
		Parent = frame,
	})
	UiKit.Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		Parent = chanceRow,

	})

	for key, def in Config.DEV_PRODUCTS do
		if def.Kind == "LuckPotion" or def.Kind == "ServerBoost" then
			MakeProductRow(chanceRow, def, key)
		end
	end

	local essenceTitle = UiKit.Create("TextLabel", {
		BackgroundTransparency = 1,
		TextColor3 = UiKit.TINTS.WHITE,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0, 0.36),
		Size = UDim2.fromScale(1, 0.04),
		Text = "Essence (confort)",
		Parent = frame,
	})

	local essenceRow = UiKit.Create("Frame", {
		Name = "EssenceRow",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0, 0.42),
		Size = UDim2.fromScale(1, 0.14),
		Parent = frame,
	})
	UiKit.Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		Parent = essenceRow,
	})

	for key, def in Config.DEV_PRODUCTS do
		if def.Amount then
			MakeProductRow(essenceRow, def, key)
		end
	end

	-- Bannière informative 1er achat : affichée tant que non claimée, pas de popup auto.
	offerBanner = UiKit.Create("Frame", {
		Name = "FirstOfferBanner",
		BackgroundColor3 = UiKit.TINTS.ACCENT,
		BackgroundTransparency = 0.7,
		Size = UDim2.fromScale(1, 0.08),
		Position = UDim2.fromScale(0, 0.58),
		Visible = false,
		Parent = frame,
	})
	UiKit.Corner(offerBanner)
	UiKit.Padding(offerBanner, 4)
	UiKit.Create("TextLabel", {
		Name = "OfferText",
		BackgroundTransparency = 1,
		TextColor3 = UiKit.TINTS.WHITE,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.fromScale(0.72, 1),
		Text = "Offre 1re fois : pack de départ −50 %",
		Parent = offerBanner,
	})
	local offerButton = UiKit.Create("TextButton", {
		Name = "OfferBuy",
		BackgroundColor3 = UiKit.TINTS.ACCENT,
		TextColor3 = UiKit.TINTS.WHITE,
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
end

Net.BoostState.OnClientEvent:Connect(function(state)
	boostUntil = state.Until or 0
end)

Net.EclipseState.OnClientEvent:Connect(function(state)
	eclipseActive = state.Active == true
	eclipseUntil = state.Until or 0
	eclipseBonus = state.Bonus or 0
end)

return ShopPanel
