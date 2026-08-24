local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Audio = require(script.Parent.Audio)
local Fx = require(script.Parent.Fx)
local UiKit = require(script.Parent.UiKit)
local CreaturePortrait = require(script.Parent.CreaturePortrait)

local HatchCinematic = {}

-- Carte courante : une éclosion rapprochée remplace la précédente.
local currentCard: BasePart? = nil

local function ShowRevealCard(anchor: Vector3, result)
	if currentCard then
		currentCard:Destroy()
		currentCard = nil
	end

	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.new(0.1, 0.1, 0.1)
	holder.CFrame = CFrame.new(anchor + Vector3.new(0, 3, 0))
	holder.Parent = Workspace
	currentCard = holder

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(280, 120)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 80
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.Parent = holder

	local card = UiKit.Create("Frame", {
		Name = "RevealCard",
		BackgroundColor3 = UiKit.TINTS.PANEL,
		BackgroundTransparency = 0.4,
		Size = UDim2.fromScale(1, 1),
		Parent = billboard,
	})
	UiKit.Corner(card)
	local stroke = Instance.new("UIStroke")
	stroke.Color = result.RarityColor or Color3.new(1, 1, 1)
	stroke.Thickness = 2
	stroke.Parent = card

	local portrait = CreaturePortrait.Create(card, UDim2.fromOffset(6, 6), UDim2.new(0, 100, 1, -12))
	if result.Creature then
		CreaturePortrait.Show(portrait, result.Creature.SpeciesId, result.Creature.Rarity, result.Creature.Mutation)
	end

	UiKit.Create("TextLabel", {
		Name = "SpeciesName",
		BackgroundTransparency = 1,
		TextColor3 = UiKit.TINTS.WHITE,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Position = UDim2.fromOffset(112, 18),
		Size = UDim2.new(1, -120, 0, 40),
		Text = result.SpeciesName or "?",
		Parent = card,
	})
	local mutationText = result.MutationName and ` · {result.MutationName}` or ""
	UiKit.Create("TextLabel", {
		Name = "RarityName",
		BackgroundTransparency = 1,
		TextColor3 = result.RarityColor or UiKit.TINTS.WHITE,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Position = UDim2.fromOffset(112, 62),
		Size = UDim2.new(1, -120, 0, 40),
		Text = `{result.RarityName or ""}{mutationText}`,
		Parent = card,
	})

	-- Entrée : scale-up + opacification, puis hold 4 s et fondu.
	local scale = Instance.new("UIScale")
	scale.Scale = 0.6
	scale.Parent = card
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 })
		:Play()
	TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.1,
	}):Play()

	task.delay(4, function()
		local fade = TweenService:Create(card, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1,
		})
		local shrink = TweenService:Create(scale, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Scale = 0.8,
		})
		fade:Play()
		shrink:Play()
		fade.Completed:Wait()
		if currentCard == holder then
			currentCard = nil
		end
		holder:Destroy()
	end)
end

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

	-- Carte de révélation au-dessus du nid (ou du joueur si œuf introuvable)
	local anchor = egg and egg.Position
	if not anchor then
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		anchor = root and root.Position or Vector3.zero
	end
	ShowRevealCard(anchor, result)
end

return HatchCinematic
