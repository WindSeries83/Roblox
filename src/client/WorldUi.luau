--!strict
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)

local gui = Instance.new("ScreenGui")
gui.Name = "WorldUi"
gui.ResetOnSpawn = false
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.BackgroundColor3 = Color3.fromRGB(20, 24, 38)
panel.BackgroundTransparency = 0.15
panel.Size = UDim2.fromOffset(230, 108)
panel.Position = UDim2.new(0.5, -115, 0, 12)
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

local function button(name: string, y: number): TextButton
	local out = Instance.new("TextButton")
	out.Name = name
	out.Size = UDim2.new(1, -12, 0, 28)
	out.Position = UDim2.fromOffset(6, y)
	out.BackgroundColor3 = Color3.fromRGB(55, 67, 100)
	out.TextColor3 = Color3.new(1, 1, 1)
	out.Font = Enum.Font.GothamBold
	out.TextSize = 13
	out.Parent = panel
	Instance.new("UICorner", out).CornerRadius = UDim.new(0, 7)
	return out
end

local worldButton = button("World", 6)
local rushButton = button("Rush", 40)
local titleButton = button("Title", 74)
local state: any = nil
local originalColors: { [BasePart]: Color3 } = setmetatable({}, { __mode = "k" }) :: any
local baseAmbient = Lighting.Ambient
local baseOutdoor = Lighting.OutdoorAmbient
local themedWorld = ""

local function applyTheme(worldId: string)
	if themedWorld == worldId then
		return
	end
	themedWorld = worldId
	local decor = Workspace:FindFirstChild("Decor")
	if decor then
		for _, item in decor:GetDescendants() do
			if item:IsA("BasePart") then
				originalColors[item] = originalColors[item] or item.Color
				item.Color = if worldId == "World2" then originalColors[item]:Lerp(Color3.fromRGB(80, 175, 220), 0.35) else originalColors[item]
			end
		end
	end
	Lighting.Ambient = if worldId == "World2" then Color3.fromRGB(55, 90, 125) else baseAmbient
	Lighting.OutdoorAmbient = if worldId == "World2" then Color3.fromRGB(70, 110, 145) else baseOutdoor
end

local function render(newState: any)
	state = newState
	local worldId = state.CurrentWorld or "World1"
	local world = Config.WORLDS[worldId]
	worldButton.Text = `{world.Name}  › changer`
	rushButton.Visible = world.Rush ~= nil
	rushButton.Text = if state.RushRewards and state.RushRewards[worldId] then "Rush terminé ✓" else "Armer le Rush"
	titleButton.Text = if state.EquippedTitle ~= "" then `Titre : {state.EquippedTitle}` else "Titre : aucun"
	applyTheme(worldId)
end

worldButton.Activated:Connect(function()
	if not state then
		return
	end
	local target = if state.CurrentWorld == "World2" then "World1" else "World2"
	if state.WorldUnlocks and state.WorldUnlocks[target] then
		Net.WorldSelect:FireServer(target)
	end
end)

rushButton.Activated:Connect(function()
	Net.RushRequest:FireServer()
end)

titleButton.Activated:Connect(function()
	if not state then
		return
	end
	local titles = state.Titles or {}
	local index = table.find(titles, state.EquippedTitle) or 0
	Net.EquipTitle:FireServer(titles[index + 1] or "")
end)

Net.Sync.OnClientEvent:Connect(render)
Net.RushSync.OnClientEvent:Connect(function(result)
	rushButton.Text = if result.Active then `Rush armé : faille < {result.TargetSeconds}s` elseif result.Success then "Rush réussi ✓" else "Rush échoué"
end)

return {}
