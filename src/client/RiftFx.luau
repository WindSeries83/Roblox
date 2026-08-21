local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Fx = require(script.Parent.Fx)
local CreatureDisplay = require(script.Parent.CreatureDisplay)
local FollowController = require(script.Parent.FollowController)

local RiftFx = {}

local IMPACT_COLOR = Color3.fromRGB(255, 80, 80)
local LUNGE_TIME = 0.15

local function GuardianPart(): BasePart?
	local player = Players.LocalPlayer
	return Workspace:FindFirstChild(`Guardian_{player.Name}`)
end

-- Ruée du compagnon vers le gardien + impact.
function RiftFx.OnAttack()
	local guardian = GuardianPart()
	if not guardian then
		return
	end

	local companionId, companionModel = nil, nil
	for id in FollowController.Current do
		companionId = id
		companionModel = CreatureDisplay.Models()[id]
	end
	if not companionId or not companionModel or not companionModel.PrimaryPart then
		return
	end
	if companionModel:GetAttribute("Lunging") then
		return
	end

	local origin = companionModel:GetPivot()
	local target = CFrame.lookAt(origin.Position, guardian.Position) * CFrame.new(0, 0, -6)

	companionModel:SetAttribute("Lunging", true)
	task.spawn(function()
		local start = os.clock()
		while os.clock() - start < LUNGE_TIME do
			local alpha = (os.clock() - start) / LUNGE_TIME
			companionModel:PivotTo(origin:Lerp(target, alpha))
			RunService.Heartbeat:Wait()
		end
		Fx.Burst(guardian, IMPACT_COLOR, 18)
		start = os.clock()
		while os.clock() - start < LUNGE_TIME do
			local alpha = (os.clock() - start) / LUNGE_TIME
			companionModel:PivotTo(target:Lerp(origin, alpha))
			RunService.Heartbeat:Wait()
		end
		companionModel:PivotTo(origin)
		companionModel:SetAttribute("Lunging", nil)
	end)
end

-- Tremblement caméra léger quand le gardien riposte.
function RiftFx.OnGuardianHit()
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	task.spawn(function()
		for _ = 1, 4 do
			humanoid.CameraOffset = Vector3.new(math.random(-10, 10) / 40, math.random(-10, 10) / 40, 0)
			task.wait(0.05)
		end
		TweenService:Create(humanoid, TweenInfo.new(0.12), { CameraOffset = Vector3.zero }):Play()
	end)
end

return RiftFx
