local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Audio = require(script.Parent.Audio)
local Fx = require(script.Parent.Fx)

local HatchCinematic = {}

-- Éclosion spectaculaire dans le monde : l'œuf du nid tremble, éclate de lumière,
-- et la créature est annoncée en surimpression. Remplace le popup de menu pour ce cas.
function HatchCinematic.Play(result)
	Audio.Play("HatchCrack")

	local egg = Workspace:FindFirstChild("Nest") and Workspace.Nest:FindFirstChild("NestEgg")
	local color = result.RarityColor or Color3.fromRGB(255, 255, 255)

	if egg and egg:IsA("BasePart") then
		task.spawn(function()
			for i = 1, 3 do
				local grow = TweenService:Create(egg, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
					Size = Vector3.new(1.7 + i * 0.15, 2.1 + i * 0.2, 1.7 + i * 0.15),
				})
				grow:Play()
				grow.Completed:Wait()
				local shrink = TweenService:Create(egg, TweenInfo.new(0.08), {
					Size = Vector3.new(1.5, 1.9, 1.5),
				})
				shrink:Play()
				shrink.Completed:Wait()
			end
			Fx.Burst(egg, color, 40)
			Fx.Confetti(egg.Position + Vector3.new(0, 1.5, 0), color, 24)

			local flash = Instance.new("PointLight")
			flash.Color = color
			flash.Brightness = 6
			flash.Range = 18
			flash.Shadows = false
			flash.Parent = egg
			TweenService:Create(flash, TweenInfo.new(0.8), { Brightness = 0 }):Play()
			task.delay(1, function()
				flash:Destroy()
			end)

			egg.Transparency = 1
		end)
	end

	-- Punch caméra FOV
	local camera = Workspace.CurrentCamera
	local fov0 = camera.FieldOfView
	task.spawn(function()
		local tweenOut =
			TweenService:Create(camera, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { FieldOfView = fov0 - 12 })
		tweenOut:Play()
		tweenOut.Completed:Wait()
		TweenService:Create(camera, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { FieldOfView = fov0 }):Play()
	end)

	-- Nom de la créature au-dessus du nid (ou du joueur si œuf introuvable)
	local anchor = egg and egg.Position
	if not anchor then
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		anchor = root and root.Position or Vector3.zero
	end
	Fx.FloatText(anchor + Vector3.new(0, 3.5, 0), `{result.SpeciesName} · {result.RarityName}`, color)
end

return HatchCinematic
