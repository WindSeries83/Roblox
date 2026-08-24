local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local TutorialBridge = require(ReplicatedStorage.Shared.TutorialBridge)

local UiKit = require(script.Parent.UiKit)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TINTS = UiKit.TINTS

local STEPS = {
	{
		Text = "Approche-toi de l'œuf du nid et touche-le pour éclore ta première créature.",
		Need = "Hatch",
	},
	{
		Text = "Ta créature te suit et farm pour toi. Ouvre le Menu pour en faire plus.",
		Need = "MenuOpen",
	},
	{
		Text = "La Faille s'est ouverte ! Entre dans l'arche violette.",
		Need = "RiftEntered",
	},
	{
		Text = "C'est tout ! Une récompense de 50 essence t'attend.",
		Need = "Claim",
	},
}

local bannerGui = Instance.new("ScreenGui")
bannerGui.Name = "TutorialGui"
bannerGui.ResetOnSpawn = false
bannerGui.IgnoreGuiInset = true
bannerGui.Parent = playerGui

local banner = UiKit.Create("Frame", {
	BackgroundColor3 = TINTS.PANEL,
	Size = UDim2.new(1, -32, 0, 96),
	Position = UDim2.new(0.5, 0, 1, -148), -- au-dessus de la barre d'action (lot 3)
	AnchorPoint = Vector2.new(0.5, 0),
	ZIndex = 50,
	Visible = false,
	Parent = bannerGui,
})

local function SkipTutorial()
	if banner then
		banner.Visible = false
		banner:Destroy()
	end
end

local active = false
local stepIndex = 0
local state = nil

local function ShowStep(index: number)
	if not active then
		return
	end
	if not banner or not banner.Parent then
		return
	end
	banner.Visible = true
	stepIndex = index
	for _, child in banner:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	local step = STEPS[index]
	if not step then
		SkipTutorial()
		return
	end

	local header = UiKit.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -48, 0, 28),
		Position = UDim2.fromOffset(0, 4),
		ZIndex = 50,
		Parent = banner,
	})
	UiKit.Create("TextLabel", {
		BackgroundTransparency = 1,
		TextColor3 = TINTS.ACCENT,
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.fromScale(0.5, 1),
		ZIndex = 50,
		Text = `Étape {index}/{#STEPS}`,
		Parent = header,
	})

	UiKit.Create("TextLabel", {
		BackgroundTransparency = 1,
		TextColor3 = TINTS.WHITE,
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -12, 1, -40),
		Position = UDim2.fromOffset(0, 34),
		ZIndex = 50,
		Text = step.Text,
		Parent = banner,
	})

	local closeButton = UiKit.Create("TextButton", {
		Name = "CloseButton",
		BackgroundColor3 = TINTS.RED,
		TextColor3 = TINTS.WHITE,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, -34, 0, 4),
		Text = "✕",
		ZIndex = 50,
		Parent = banner,
	})
	UiKit.Corner(closeButton)
	closeButton.Activated:Connect(SkipTutorial)

	if step.Need == "Claim" then
		local claimButton = UiKit.Button(banner, "Réclamer", UDim2.fromOffset(120, 34), UDim2.new(1, -132, 0, 4))
		claimButton.Name = "ClaimTutorialButton"
		claimButton.TextSize = 14
		claimButton.ZIndex = 50
		claimButton.Activated:Connect(function()
			Net.TutorialComplete:FireServer()
			SkipTutorial()
		end)
	end
end

local function Check()
	if not active then
		return
	end
	local step = STEPS[stepIndex]
	if not step then
		return
	end
	local advance = false
	if step.Need == "MenuOpen" then
		advance = TutorialBridge.state.MenuOpen
	elseif step.Need == "RiftEntered" then
		advance = TutorialBridge.state.RiftEntered
	end
	if advance then
		ShowStep(stepIndex + 1)
	end
end

Net.Sync.OnClientEvent:Connect(function(newState)
	state = newState
	if state and state.TutorialDone then
		SkipTutorial()
		return
	end
	if not active and state and not state.TutorialDone then
		active = true
		ShowStep(1)
		return
	end
	Check()
end)

Net.HatchResult.OnClientEvent:Connect(function()
	if active and STEPS[stepIndex] and STEPS[stepIndex].Need == "Hatch" then
		ShowStep(stepIndex + 1)
	end
end)

TutorialBridge.Changed(function(key)
	if key == "MenuOpen" or key == "RiftEntered" then
		Check()
	end
end)

return nil
