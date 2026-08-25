local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Sanctuary = require(ReplicatedStorage.Shared.Sanctuary)
local UiKit = require(script.Parent.UiKit)

-- Barre d'œufs en bas à gauche : clique = place l'œuf à la couveuse (Net.PlaceEgg),
-- sans passer par le menu. Se reconstruit à chaque Net.Sync (Clear garde le layout).
local EggHotbar = {}

local SHELL_COLORS = {
	CommonEgg = Color3.fromRGB(235, 230, 215),
	UncommonEgg = Color3.fromRGB(140, 200, 170),
	RareEgg = Color3.fromRGB(90, 150, 230),
	EpicEgg = Color3.fromRGB(160, 90, 220),
	LegendaryEgg = Color3.fromRGB(230, 190, 80),
}

local MAX_SHOWN = 8

function EggHotbar.Start()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local ui = playerGui:WaitForChild("RiftBeastsUi", 60)
	if not ui then
		return
	end

	local bar = UiKit.Create("Frame", {
		Name = "EggHotbar",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 12, 1, -12),
		Size = UDim2.fromOffset(0, 46),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Parent = ui,
	})
	UiKit.Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = bar,
	})

	Net.Sync.OnClientEvent:Connect(function(state)
		UiKit.Clear(bar)
		local eggs = Sanctuary.SortEggs(state and state.Eggs or {})
		UiKit.Create("TextLabel", {
			Name = "HotbarHint",
			BackgroundTransparency = 1,
			TextColor3 = UiKit.TINTS.WHITE,
			TextTransparency = 0.35,
			Font = Enum.Font.Gotham,
			TextSize = 11,
			Size = UDim2.fromOffset(0, 20),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = if #eggs > 0 then `Œufs ({#eggs}) →` else "Aucun œuf — achète-en dans le menu Œufs",
			LayoutOrder = 0,
			Parent = bar,
		})
		for i, egg in eggs do
			if i > MAX_SHOWN then
				break
			end
			local slot = UiKit.Create("TextButton", {
				Name = `Hotbar_{egg.Id}`,
				BackgroundColor3 = SHELL_COLORS[egg.Tier] or SHELL_COLORS.CommonEgg,
				Size = UDim2.fromOffset(44, 44),
				Text = "",
				LayoutOrder = i,
				Parent = bar,
			})
			UiKit.Corner(slot)
			slot.Activated:Connect(function()
				Net.PlaceEgg:FireServer(egg.Id)
			end)
		end
	end)
end

task.spawn(function()
	EggHotbar.Start()
end)

return EggHotbar
