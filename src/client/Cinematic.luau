local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Rarities = require(ReplicatedStorage.Shared.Data.Rarities)

local MIN_RANK = 5 -- Légendaire+ (pyramide de célébration, bible §4.B)
local GOLDEN_TINT = Color3.fromRGB(255, 238, 190)

local Cinematic = {}

local busy = false
local generation = 0
local blur: BlurEffect? = nil
local correction: ColorCorrectionEffect? = nil
local cadreGui: ScreenGui? = nil
local cadreStroke: UIStroke? = nil

function Cinematic.Play(payload)
	local rank = if payload.Rank then payload.Rank else Gameplay.RarityRank(payload and payload.Rarity or "")
	if rank < MIN_RANK then
		return
	end
	if busy then
		return
	end
	busy = true
	generation += 1
	local gen = generation

	local player = Players.LocalPlayer
	local camera = workspace.CurrentCamera
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local savedSpeed = humanoid and humanoid.WalkSpeed or 16
	local savedFov = camera and camera.FieldOfView or 70

	local tweens = {}
	local function PlayTween(instance: Instance, info: TweenInfo, goal: { [string]: any })
		local tween = TweenService:Create(instance, info, goal)
		table.insert(tweens, tween)
		tween:Play()
	end

	local function Restore()
		if gen ~= generation then
			return
		end
		generation += 1
		for _, tween in tweens do
			tween:Cancel()
		end
		if humanoid and humanoid.Parent then
			humanoid.WalkSpeed = savedSpeed
		end
		if camera then
			camera.FieldOfView = savedFov
		end
		if blur then
			blur:Destroy()
			blur = nil
		end
		if correction then
			correction:Destroy()
			correction = nil
		end
		if cadreGui then
			cadreGui:Destroy()
			cadreGui = nil
			cadreStroke = nil
		end
		busy = false
	end

	local diedConn = nil
	if humanoid then
		humanoid.WalkSpeed = 3
		diedConn = humanoid.Died:Connect(Restore)
	end

	local Audio = require(script.Parent.Audio)
	Audio.Play("RebirthRoar")

	blur = Instance.new("BlurEffect")
	blur.Name = "CinematicBlur"
	blur.Size = 0
	blur.Parent = Lighting

	correction = Instance.new("ColorCorrectionEffect")
	correction.Name = "CinematicColor"
	correction.Saturation = 0
	correction.Parent = Lighting

	cadreGui = Instance.new("ScreenGui")
	cadreGui.Name = "CinematicCadre"
	cadreGui.ResetOnSpawn = false
	cadreGui.IgnoreGuiInset = true
	cadreGui.DisplayOrder = 50
	local frame = Instance.new("Frame")
	frame.Name = "Cadre"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.new(1, -24, 1, -24)
	frame.BackgroundTransparency = 1
	frame.Parent = cadreGui
	cadreStroke = Instance.new("UIStroke")
	cadreStroke.Thickness = 12
	cadreStroke.Color = Rarities.UltraRare.Color
	cadreStroke.Transparency = 1
	cadreStroke.Parent = frame
	cadreGui.Parent = player.PlayerGui

	local punch = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local release = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

	PlayTween(blur, punch, { Size = 14 })
	PlayTween(correction, punch, { Saturation = -0.3 })
	PlayTween(camera, release, { FieldOfView = 60 })
	PlayTween(cadreStroke :: UIStroke, punch, { Transparency = 0 })

	task.delay(0.7, function()
		if gen ~= generation then
			return
		end
		PlayTween(correction :: ColorCorrectionEffect, release, { Saturation = 0.15, TintColor = GOLDEN_TINT })
	end)
	task.delay(1.2, function()
		if gen ~= generation then
			return
		end
		PlayTween(blur :: BlurEffect, release, { Size = 0 })
		PlayTween(correction :: ColorCorrectionEffect, release, { Saturation = 0, TintColor = Color3.new(1, 1, 1) })
		PlayTween(camera, release, { FieldOfView = savedFov })
		PlayTween(cadreStroke :: UIStroke, release, { Transparency = 1 })
	end)
	task.delay(2, function()
		if diedConn then
			diedConn:Disconnect()
		end
		Restore()
	end)
end

return Cinematic
