local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiKit = require(script.Parent.Parent.UiKit)
local Net = require(ReplicatedStorage.Shared.Net)
local Config = require(ReplicatedStorage.Shared.Config)
local Equipment = require(ReplicatedStorage.Shared.Data.Equipment)

local EggPanel = {}

local TIER_NAMES = {
	CommonEgg = "Œuf commun",
	UncommonEgg = "Œuf peu commun",
	RareEgg = "Œuf rare",
}

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
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0, 0.15),
		Size = UDim2.fromScale(1, 0.08),
		Parent = frame,
	})
	UiKit.Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		Parent = itemShopRow,
	})

	eggList = UiKit.Scroller(frame, UDim2.fromScale(0, 0.25), UDim2.fromScale(1, 0.75))

	local tierOrder = { "CommonEgg", "UncommonEgg", "RareEgg" }
	for _, tier in tierOrder do
		local price = Config.EGG_PRICES[tier]
		local button = UiKit.Create("TextButton", {
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
	for _, egg in state.Eggs do
		local row = UiKit.Cell(eggList)
		UiKit.Create("TextLabel", {
			BackgroundTransparency = 1,
			TextColor3 = UiKit.TINTS.WHITE,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.fromScale(1, 0.4),
			Text = TIER_NAMES[egg.Tier] or egg.Tier,
			Parent = row,
		})
		local button = UiKit.Button(row, "Éclore", UDim2.fromScale(0.45, 0.4), UDim2.fromScale(0.55, 0))
		button.Activated:Connect(function()
			Net.HatchEgg:FireServer(egg.Id)
		end)
	end
end

return EggPanel
