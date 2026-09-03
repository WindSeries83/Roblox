--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiKit = require(script.Parent.Parent.UiKit)
local Net = require(ReplicatedStorage.Shared.Net)
local Config = require(ReplicatedStorage.Shared.Config)
local Offers = require(ReplicatedStorage.Shared.Offers)

local ShopPanel = {}
local TINTS = UiKit.TINTS
local player = Players.LocalPlayer

local potionLabel: TextLabel
local boostLabel: TextLabel
local vipLabel: TextLabel
local eclipseLabel: TextLabel
local offerList: Frame
local offerRows: { [string]: Frame } = {}
local luckPotion
local boostUntil = 0
local eclipseActive = false
local eclipseUntil = 0
local eclipseBonus = 0
local vipExpiresAt = 0

local function Prompt(offer)
	if not Config.PURCHASES_ENABLED or not Offers.IsAvailable(offer) then
		return
	end
	if offer.Kind == "GamePass" then
		MarketplaceService:PromptGamePassPurchase(player, offer.Sku)
	else
		MarketplaceService:PromptProductPurchase(player, offer.Sku)
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
		boostLabel.Text = "Pas de boost serveur"
	end

	local eclipseLeft = if eclipseActive then RemainingText(eclipseUntil) else nil
	eclipseLabel.Visible = eclipseLeft ~= nil
	if eclipseLeft then
		eclipseLabel.Text = string.format("Éclipse ! Mutations ×%d — %s restant", 1 + eclipseBonus, eclipseLeft)
	end
	local vipLeft = RemainingText(vipExpiresAt)
	if vipLeft then
		vipLabel.Text = `VIP actif — {vipLeft} restant`
		vipLabel.TextColor3 = TINTS.ACCENT
	else
		vipLabel.Text = "VIP inactif — aucun contenu de base n'est verrouillé"
		vipLabel.TextColor3 = TINTS.WHITE
	end
end

local function OfferDurationText(duration: number): string
	if duration <= 0 then
		return ""
	end
	local days = math.floor(duration / 86400)
	if days > 0 and duration % 86400 == 0 then
		return `Durée : {days} jour(s)`
	end
	return `Durée : {math.floor(duration / 60)} min`
end

local function OfferRow(parent: Instance, key: string, offer, layoutOrder: number): Frame
	local row = UiKit.Cell(parent)
	row.LayoutOrder = layoutOrder
	local duration = OfferDurationText(offer.Duration)
	UiKit.Create("TextLabel", {
		Name = `OfferLabel_{key}`,
		BackgroundTransparency = 1,
		TextColor3 = TINTS.WHITE,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Size = UDim2.fromScale(0.64, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = `{offer.ValueText}\n{offer.PriceText}` .. if duration ~= "" then `\n{duration}` else "",
		Parent = row,
	})
	local button = UiKit.Button(row, "Acheter", UDim2.new(0.28, 0, 0, 44), UDim2.new(0.7, 0, 0.5, -22))
	button.Name = `OfferBuy_{key}`
	button.BackgroundColor3 = TINTS.DARK
	button.Activated:Connect(function()
		Prompt(offer)
	end)
	return row
end

local function RenderOffers(catalog)
	for _, row in offerRows do
		row:Destroy()
	end
	table.clear(offerRows)
	local keys = {}
	for key, offer in catalog or {} do
		if Offers.IsAvailable(offer) then
			table.insert(keys, key)
		end
	end
	table.sort(keys)
	for order, key in keys do
		offerRows[key] = OfferRow(offerList, key, catalog[key], order)
	end
	offerList.Visible = #keys > 0
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
	vipLabel = UiKit.Create("TextLabel", {
		Name = "VipState",
		BackgroundTransparency = 1,
		TextColor3 = TINTS.WHITE,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 18),
		LayoutOrder = 0,
		Text = "VIP inactif",
		Parent = scroller,
	})

	local stateTitle = UiKit.SectionTitle(scroller, "État des bonus")
	stateTitle.LayoutOrder = 1
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

	local offerTitle = UiKit.SectionTitle(scroller, "Offres disponibles")
	offerTitle.LayoutOrder = 5
	offerList = UiKit.Create("Frame", {
		Name = "OfferList",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 6,
		Visible = false,
		Parent = scroller,
	}) :: Frame
	UiKit.Create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = offerList,
	})
	UiKit.Create("TextLabel", {
		Name = "OffersHint",
		BackgroundTransparency = 1,
		TextColor3 = TINTS.WHITE,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 7,
		Text = "Les offres apparaissent uniquement après leur validation et lorsque leur condition est remplie. Aucun contenu de base n'est verrouillé.",
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
	boostUntil = state.ServerBoostUntil or boostUntil
	vipExpiresAt = state.VipExpiresAt or 0
	RenderOffers(state.Offers and state.Offers.Catalog)
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
