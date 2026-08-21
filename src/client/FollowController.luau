local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CreatureDisplay = require(script.Parent.CreatureDisplay)

local FollowController = {}

local OFFSET = Vector3.new(0, 0, 3)
local LERP = 0.12
local smoothed: { [string]: CFrame } = {}

FollowController.Current = {} -- [id] = CFrame du compagnon cette frame
FollowController.Idle = true

local function CompanionId(): string?
	local best, bestPower = nil, -1
	for _, creature in CreatureDisplay.Creatures() do
		if creature.Power > bestPower then
			best, bestPower = creature.Id, creature.Power
		end
	end
	return best
end

function FollowController.Start()
	RunService.Heartbeat:Connect(function(t)
		table.clear(FollowController.Current)

		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end

		local velocity = root.AssemblyLinearVelocity
		local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
		FollowController.Idle = speed < 1

		local id = CompanionId()
		local model = id and CreatureDisplay.Models()[id]
		if not id or not model or not model.PrimaryPart then
			return
		end
		if model:GetAttribute("Lunging") then
			FollowController.Current[id] = model:GetPivot()
			return
		end

		CreatureDisplay.Motion[id] = "follow"
		local target = root.CFrame * CFrame.new(OFFSET) * CFrame.Angles(0, math.rad(180), 0)
		target = target + Vector3.new(0, math.sin(t * 2) * 0.15, 0)
		local currentCFrame = smoothed[id] or model:GetPivot()
		local nextCFrame = currentCFrame:Lerp(target, LERP)
		smoothed[id] = nextCFrame
		model:PivotTo(nextCFrame)
		FollowController.Current[id] = nextCFrame
	end)
end

return FollowController
