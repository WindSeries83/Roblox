local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CreatureDisplay = require(script.Parent.CreatureDisplay)

local FollowController = {}

local OFFSET = Vector3.new(0, 0, 3)
local LERP = 0.18
local smoothed: { [string]: CFrame } = {}

FollowController.Current = {} -- [id] = CFrame du compagnon cette frame
FollowController.Idle = true

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

		local id = CreatureDisplay.CompanionId()
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

		-- Yaw seul vers la direction du déplacement, pitch/roll laissés neutres.
		local delta = nextCFrame.Position - currentCFrame.Position
		local flat = Vector3.new(delta.X, 0, delta.Z)
		if flat.Magnitude > 0.05 then
			nextCFrame = CFrame.lookAt(nextCFrame.Position, nextCFrame.Position + flat.Unit)
		end

		smoothed[id] = nextCFrame

		-- Hop discret du modèle entier si aucune part animable (fallback posé par CreatureMotion).
		-- Composé ici : PivotTo unique par frame, aucun risque d'être écrasé.
		local display = nextCFrame
		if not FollowController.Idle and model:GetAttribute("HopFallback") then
			display *= CFrame.new(0, math.sin(t * 6) * 0.12, 0) * CFrame.Angles(0, 0, math.sin(t * 6) * 0.04)
		end

		model:PivotTo(display)
		FollowController.Current[id] = nextCFrame
	end)
end

return FollowController
