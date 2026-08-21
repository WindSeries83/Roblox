local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiKit = require(script.Parent.Parent.UiKit)
local Net = require(ReplicatedStorage.Shared.Net)
local Config = require(ReplicatedStorage.Shared.Config)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Rarities = require(ReplicatedStorage.Shared.Data.Rarities)
local Equipment = require(ReplicatedStorage.Shared.Data.Equipment)

local EggPanel = {}

local TIER_NAMES = {
	CommonEgg = "Œuf commun",
	UncommonEgg = "Œuf peu commun",
	RareEgg = "Œuf rare",
}

local function Hex(color: Color3): string
	return string.format(
		"#%02X%02X%02X",
		math.floor(color.R * 255 + 0.5),
		math.floor(color.G * 255 + 0.5),
		math.floor(color.B * 255 + 0.5)
	)
end

local function EggRatesText(weights: { [string]: number }): string
	local parts = {}
	for _, rate in Gameplay.DropRates(weights) do
		local rarity = Rarities[rate.Id]
		local name = rarity and rarity.Name or rate.Id
		local color = rarity and rarity.Color or UiKit.TINTS.WHITE
		table.insert(parts, `<font color="{Hex(color)}">{name} {string.format("%g", rate.Percent)} %</font>`)
	end
	return table.concat(parts, " · ")
end

local eggList
local shopRow
local itemShopRow

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
			Text = EggRatesText(Config.EGG_RARITY_WEIGHTS[tier]),
			Parent = ratesRow,
		})
	end

	eggList = UiKit.Scroller(frame, UDim2.fromScale(0, 0.3), UDim2.fromScale(1, 0.7))
	eggList.Name = "EggList"
	for _, child in eggList:GetChildren() do
		if child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

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
			Text = `{TIER_NAMES[tier]}\n{price} Essence`,
			TextWrapped = true,
			Parent = shopRow,
		})
		UiKit.Corner(button)
		button.Activated:Connect(function()
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
	local rowWidth = eggList.AbsoluteSize.X - 4
	for i, egg in state.Eggs do
		local row = UiKit.Cell(eggList)
		row.Name = `EggRow{i}`
		row.Size = UDim2.fromOffset(rowWidth, 52)
		row.Position = UDim2.fromOffset(0, (i - 1) * 58)
		UiKit.Create("TextLabel", {
			BackgroundTransparency = 1,
			TextColor3 = UiKit.TINTS.WHITE,
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromScale(0, 0.5),
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.fromOffset(0, 22),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = TIER_NAMES[egg.Tier] or egg.Tier,
			Parent = row,
		})
		local button = UiKit.Button(row, "Éclore", UDim2.new(0.55, 0, 0, 36), UDim2.fromScale(0.45, 0.5))
		button.Name = `HatchButton{i}`
		button.AnchorPoint = Vector2.new(0, 0.5)
		button.Activated:Connect(function()
			Net.HatchEgg:FireServer(egg.Id)
		end)
		eggList.CanvasSize = UDim2.fromOffset(0, #state.Eggs * 58)
	end
end

return EggPanel
