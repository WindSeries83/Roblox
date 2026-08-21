local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = require(ReplicatedStorage.Shared.Net)
local CreatureDisplay = require(script.Parent.CreatureDisplay)

local FollowController = {}

local OFFSETS = {
	Vector3.new(-2.5, 0, 2.5),
	Vector3.new(2.5, 0, 2.5),
	Vector3.new(0, 0, 4.5),
}
local LERP = 0.12
local smoothed: { [string]: CFrame } = {}
local inRift = false

Net.RiftSync.OnClientEvent:Connect(function(payload)
	inRift = payload.InRift == true
end)

local function FollowerIds(): { [string]: number }
	local creatures = CreatureDisplay.Creatures()
	local sorted = table.clone(creatures)
	table.sort(sorted, function(a, b)
		return a.Power > b.Power
	end)
	local picked: { [string]: number } = {}
	for i, creature in sorted do
		if i > #OFFSETS then
			break
		end
		picked[creature.Id] = i
	end
	return picked
end

function FollowController.Start()
	RunService.Heartbeat:Connect(function(t)
		if inRift then
			for id in smoothed do
				CreatureDisplay.Motion[id] = nil
			end
			table.clear(smoothed)
			return
		end

		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end

		local picked = FollowerIds()
		for id in smoothed do
			if not picked[id] then
				CreatureDisplay.Motion[id] = nil
				smoothed[id] = nil
			end
		end

		for id, slot in picked do
			local model = CreatureDisplay.Models()[id]
			if model and model.PrimaryPart then
				CreatureDisplay.Motion[id] = "follow"
				local offset = OFFSETS[slot]
				local target = root.CFrame * CFrame.new(offset) * CFrame.Angles(0, math.rad(180), 0)
				target = target + Vector3.new(0, math.sin(t * 2 + slot * 1.7) * 0.15, 0)
				local currentCFrame = smoothed[id]
				if not currentCFrame then
					currentCFrame = model:GetPivot()
				end
				local nextCFrame = currentCFrame:Lerp(target, LERP)
				smoothed[id] = nextCFrame
				model:PivotTo(nextCFrame)
			end
		end
	end)
end

return FollowController
