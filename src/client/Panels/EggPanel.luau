local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiKit = require(script.Parent.Parent.UiKit)
local Net = require(ReplicatedStorage.Shared.Net)
local Config = require(ReplicatedStorage.Shared.Config)
local Equipment = require(ReplicatedStorage.Shared.Data.Equipment)
local Sanctuary = require(ReplicatedStorage.Shared.Sanctuary)

local EggPanel = {}

local eggList
local shopRow
local itemShopRow
local pityLabel
local buyButtons: { [string]: TextButton } = {}
local lockedTiers: { [string]: number? } = {}

local function RefreshPity(hatchesSinceRare: number)
	local remaining = Config.PITY_THRESHOLD - hatchesSinceRare
	if remaining <= 5 then
		pityLabel.Text = `<font color="#FFD75E">Rare garanti dans {remaining} éclosion(s) !</font>`
	else
		pityLabel.Text = `Garantie Rare : {hatchesSinceRare}/{Config.PITY_THRESHOLD} éclosions`
	end
end

local function RefreshBuyButtons()
	for tier, button in buyButtons do
		local required = lockedTiers[tier]
		if required then
			button.Text = `{UiKit.EGG_TIER_NAMES[tier]} 🔒\nRang de sanctuaire {required} requis`
			button.TextColor3 = Color3.fromRGB(140, 140, 150)
		else
			button.Text = `{UiKit.EGG_TIER_NAMES[tier]}\n{Config.EGG_PRICES[tier]} Essence`
			button.TextColor3 = UiKit.TINTS.WHITE
		end
	end
end

function EggPanel.Create(parent)
	local frame = UiKit.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = parent,
	})
	UiKit.Padding(frame, 10)

	UiKit.Title(frame, "Œufs")

	shopRow = UiKit.Create("Frame", {
		Name = "ShopRow",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0, 0.06),
		Size = UDim2.fromScale(1, 0.08),
		Parent = frame,
	})
	UiKit.Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		Parent = shopRow,
	})

	itemShopRow = UiKit.Create("Frame", {
		Name = "ItemShopRow",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0, 0.2),
		Size = UDim2.fromScale(1, 0.08),
		Parent = frame,
	})
	UiKit.Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		Parent = itemShopRow,
	})

	local ratesRow = UiKit.Create("Frame", {
		Name = "RatesRow",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0, 0.145),
		Size = UDim2.fromScale(1, 0.05),
		Parent = frame,
	})
	UiKit.Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		Parent = ratesRow,
	})
	for _, tier in { "CommonEgg", "UncommonEgg", "RareEgg" } do
		UiKit.Create("TextLabel", {
			Name = `Rates{tier}`,
			RichText = true,
			BackgroundTransparency = 1,
			TextColor3 = UiKit.TINTS.WHITE,
			TextSize = 10,
			TextWrapped = true,
			Size = UDim2.fromScale(1 / 3, 1),
			Text = UiKit.DropRatesText(Config.EGG_RARITY_WEIGHTS[tier]),
			Parent = ratesRow,
		})
	end

	pityLabel = UiKit.Create("TextLabel", {
		Name = "PityLabel",
		RichText = true,
		BackgroundTransparency = 1,
		TextColor3 = UiKit.TINTS.WHITE,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0, 0.205),
		Size = UDim2.fromScale(1, 0.04),
		Text = "",
		Parent = frame,
	})

	eggList = UiKit.Scroller(frame, UDim2.fromScale(0, 0.3), UDim2.fromScale(1, 0.7))
	eggList.Name = "EggList"

	local tierOrder = { "CommonEgg", "UncommonEgg", "RareEgg" }
	local tierNames = { CommonEgg = "BuyCommon", UncommonEgg = "BuyUncommon", RareEgg = "BuyRare" }
	for _, tier in tierOrder do
		local price = Config.EGG_PRICES[tier]
		local button = UiKit.Create("TextButton", {
			Name = tierNames[tier],
			BackgroundColor3 = UiKit.TINTS.DARK,
			TextColor3 = UiKit.TINTS.WHITE,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			Size = UDim2.fromScale(1 / 3, 1),
			Text = `{UiKit.EGG_TIER_NAMES[tier]}\n{price} Essence`,
			TextWrapped = true,
			Parent = shopRow,
		})
		UiKit.Corner(button)
		buyButtons[tier] = button
		button.Activated:Connect(function()
			if lockedTiers[tier] then
				return
			end
			Net.BuyEgg:FireServer(tier)
		end)
	end

	for _, itemType in { "Heart", "Collar" } do
		for tier, def in Equipment[itemType].Tiers do
			local button = UiKit.Create("TextButton", {
				Name = `Buy{itemType}{tier}`,
				BackgroundColor3 = UiKit.TINTS.DARK,
				TextColor3 = UiKit.TINTS.WHITE,
				Font = Enum.Font.GothamBold,
				TextSize = 11,
				Size = UDim2.fromScale(1 / 6, 1),
				Text = `{def.Name}\n{def.Price} Essence`,
				TextWrapped = true,
				Parent = itemShopRow,
			})
			UiKit.Corner(button)
			button.Activated:Connect(function()
				Net.BuyItem:FireServer(itemType, tier)
			end)
		end
	end

	return frame
end

function EggPanel.Refresh(state)
	UiKit.Clear(eggList)
	lockedTiers = Sanctuary.EggGate(state.SanctuaryLevel or 1)
	RefreshBuyButtons()
	local stats = state.Stats or {}
	RefreshPity(stats.HatchesSinceRare or 0)
	for i, egg in state.Eggs do
		local row = UiKit.Cell(eggList)
		row.Name = `EggRow{i}`
		UiKit.Create("TextLabel", {
			BackgroundTransparency = 1,
			TextColor3 = UiKit.TINTS.WHITE,
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.fromOffset(0, 22),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = UiKit.EGG_TIER_NAMES[egg.Tier] or egg.Tier,
			Parent = row,
		})
		local button = UiKit.Button(row, "Éclore", UDim2.new(0.55, 0, 0, 36), UDim2.fromScale(0.45, 0.5))
		button.Name = `HatchButton{i}`
		button.AnchorPoint = Vector2.new(0, 0.5)
		button.Activated:Connect(function()
			Net.HatchEgg:FireServer(egg.Id)
		end)
	end
end

Net.HatchResult.OnClientEvent:Connect(function(payload)
	if payload and payload.PityProgress ~= nil then
		RefreshPity(payload.PityProgress)
	end
end)

return EggPanel
