local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Rarities = require(ReplicatedStorage.Shared.Data.Rarities)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "TickerFeedGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 5
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "Feed"
frame.AnchorPoint = Vector2.new(1, 0)
frame.Position = UDim2.new(1, -8, 0, 8)
frame.Size = UDim2.fromOffset(240, 130)
frame.BackgroundTransparency = 1
frame.Parent = gui

local statsLabel = Instance.new("TextLabel")
statsLabel.Name = "GlobalStats"
statsLabel.Size = UDim2.new(1, 0, 0, 16)
statsLabel.BackgroundTransparency = 0.4
statsLabel.BackgroundColor3 = Color3.fromRGB(15, 12, 24)
statsLabel.TextColor3 = Color3.fromRGB(255, 215, 94)
statsLabel.Font = Enum.Font.GothamBold
statsLabel.TextSize = 11
statsLabel.Text = ""
statsLabel.Parent = frame

local list = Instance.new("Frame")
list.Name = "Items"
list.Position = UDim2.fromOffset(0, 20)
list.Size = UDim2.new(1, 0, 1, -20)
list.BackgroundTransparency = 1
list.Parent = frame

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 2)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
layout.Parent = list

local function Hex(color: Color3): string
	return string.format(
		"#%02X%02X%02X",
		math.floor(color.R * 255 + 0.5),
		math.floor(color.G * 255 + 0.5),
		math.floor(color.B * 255 + 0.5)
	)
end

local function AddItem(payload)
	local color = (Rarities[payload.Rarity] or {}).Color or Color3.new(1, 1, 1)
	local mutationText = payload.MutationName and (" (" .. payload.MutationName .. ")") or ""
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 14)
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.TextXAlignment = Enum.TextXAlignment.Right
	label.BackgroundTransparency = 1
	label.RichText = true
	label.Font = Enum.Font.Gotham
	label.TextSize = 10
	label.TextWrapped = true
	label.TextColor3 = Color3.fromRGB(220, 220, 230)
	label.Text = string.format(
		'<font color="#9DB2D0">%s</font> a obtenu <font color="%s">%s%s</font>',
		payload.PlayerName or "?",
		Hex(color),
		payload.SpeciesName or "?",
		mutationText
	)
	label.LayoutOrder = -math.floor(os.clock() * 1000)
	label.Parent = list

	task.delay(6, function()
		if label.Parent then
			label:Destroy()
		end
	end)

	local labels = {}
	for _, child in list:GetChildren() do
		if child:IsA("TextLabel") then
			table.insert(labels, child)
		end
	end
	if #labels > 6 then
		table.sort(labels, function(a, b)
			return a.LayoutOrder > b.LayoutOrder
		end)
		for i = 7, #labels do
			labels[i]:Destroy()
		end
	end
end

Net.GlobalDrop.OnClientEvent:Connect(AddItem)
Net.RareDrop.OnClientEvent:Connect(function(payload)
	if payload and payload.Rarity then
		AddItem(payload)
	end
end)

local function RefreshStats(state)
	if state and state.WeekHatches then
		statsLabel.Text = string.format("%d oeufs eclos cette semaine", state.WeekHatches)
	end
end

Net.GlobalStats.OnClientEvent:Connect(RefreshStats)
Net.GlobalStats:FireServer()
