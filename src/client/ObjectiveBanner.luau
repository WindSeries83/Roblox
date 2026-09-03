local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Objective = require(ReplicatedStorage.Shared.Objective)
local TutorialBridge = require(ReplicatedStorage.Shared.TutorialBridge)
local UiKit = require(script.Parent.UiKit)

local ObjectiveBanner = {}

local TINTS = UiKit.TINTS

local frame: Frame? = nil
local label: TextLabel? = nil
local world = nil
local lastState = nil
local action: TextButton? = nil

function ObjectiveBanner.Mount(parent: Instance)
	frame = UiKit.Create("Frame", {
		Name = "ObjectiveBanner",
		BackgroundColor3 = TINTS.DARK,
		BackgroundTransparency = 0.08,
		Size = UDim2.new(1, -24, 0, 48),
		Position = UDim2.new(0.5, 0, 1, -196),
		AnchorPoint = Vector2.new(0.5, 0),
		ZIndex = 40,
		Visible = false,
		Parent = parent,
	})
	UiKit.Corner(frame)
	local constraint = Instance.new("UISizeConstraint")
	constraint.MinSize = Vector2.new(280, 48)
	constraint.MaxSize = Vector2.new(460, 48)
	constraint.Parent = frame
	label = UiKit.Create("TextLabel", {
		Name = "Text",
		BackgroundTransparency = 1,
		TextColor3 = TINTS.WHITE,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		Size = UDim2.new(1, -112, 1, 0),
		TextWrapped = true,
		ZIndex = 40,
		Text = "",
		Parent = frame,
	})
	action = UiKit.Button(frame, "Passer", UDim2.fromOffset(96, 36), UDim2.new(1, -104, 0.5, -18))
	action.Name = "TutorialAction"
	action.Activated:Connect(function()
		Net.TutorialComplete:FireServer()
		if frame then
			frame.Visible = false
		end
	end)
end

function ObjectiveBanner.Refresh(state)
	if not frame or not label then
		return
	end
	lastState = state or lastState
	local pick = if lastState and not lastState.TutorialDone
		then Objective.Tutorial(lastState)
		elseif world and world.Active then Objective.Pick(lastState or {}, world)
		elseif lastState and lastState.NextAction then lastState.NextAction
		else Objective.Pick(lastState or {}, world)
	label.Text = pick and pick.Text or ""
	frame.Visible = pick ~= nil and not TutorialBridge.state.MenuOpen
	if action then
		action.Visible = pick ~= nil and pick.Need == "Claim"
		action.Text = if pick and pick.Need == "Claim" then "Réclamer" else "Passer"
	end
end

TutorialBridge.Changed(function(key)
	if key == "MenuOpen" then
		ObjectiveBanner.Refresh(nil)
	end
end)

Net.Sync.OnClientEvent:Connect(function(state)
	ObjectiveBanner.Refresh(state)
end)

Net.RiftWorld.OnClientEvent:Connect(function(payload)
	world = payload
	ObjectiveBanner.Refresh(nil)
end)

Net.ActionResult.OnClientEvent:Connect(function(result)
	if result and result.Action == "TutorialComplete" and not result.Success then
		ObjectiveBanner.Refresh(nil)
	end
end)

return ObjectiveBanner
