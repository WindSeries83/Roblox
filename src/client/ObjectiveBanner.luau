local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Objective = require(ReplicatedStorage.Shared.Objective)
local UiKit = require(script.Parent.UiKit)

local ObjectiveBanner = {}

local TINTS = UiKit.TINTS

local frame: Frame? = nil
local label: TextLabel? = nil
local world = nil
local lastState = nil

function ObjectiveBanner.Mount(parent: Instance)
	frame = UiKit.Create("Frame", {
		Name = "ObjectiveBanner",
		BackgroundColor3 = TINTS.DARK,
		BackgroundTransparency = 0.25,
		Size = UDim2.fromOffset(420, 34),
		Position = UDim2.new(0.5, 0, 1, -206),
		AnchorPoint = Vector2.new(0.5, 0),
		ZIndex = 40,
		Visible = false,
		Parent = parent,
	})
	UiKit.Corner(frame)
	label = UiKit.Create("TextLabel", {
		Name = "Text",
		BackgroundTransparency = 1,
		TextColor3 = TINTS.ACCENT,
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		Size = UDim2.fromScale(1, 1),
		TextWrapped = true,
		ZIndex = 40,
		Text = "",
		Parent = frame,
	})
end

function ObjectiveBanner.Refresh(state)
	if not frame or not label then
		return
	end
	lastState = state or lastState
	local pick = Objective.Pick(lastState or {}, world)
	label.Text = pick and pick.Text or ""
	frame.Visible = pick ~= nil
end

Net.Sync.OnClientEvent:Connect(function(state)
	ObjectiveBanner.Refresh(state)
end)

Net.RiftWorld.OnClientEvent:Connect(function(payload)
	world = payload
	ObjectiveBanner.Refresh(nil)
end)

return ObjectiveBanner
