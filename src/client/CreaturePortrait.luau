local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rarities = require(ReplicatedStorage.Shared.Data.Rarities)
local Mutations = require(ReplicatedStorage.Shared.Data.Mutations)
local CreatureTemplates = require(ReplicatedStorage.Shared.CreatureTemplates)

-- Portrait vivant : ViewportFrame qui fait tourner lentement le modèle 3D
-- de l'espèce, teinté rareté/mutation. Réutilisable partout où on affiche
-- un nom de créature (index, révélation d'éclosion, HUD).
local CreaturePortrait = {}

local live: { any } = {}

RunService.Heartbeat:Connect(function(t)
	for _, state in live do
		if state.model and state.vp.Parent then
			state.angle = t * 0.9
			state.model:PivotTo(CFrame.Angles(0, state.angle, 0))
		end
	end
end)

function CreaturePortrait.Create(parent: Instance, position: UDim2, size: UDim2)
	local vp = Instance.new("ViewportFrame")
	vp.Name = "Portrait"
	vp.BackgroundColor3 = Color3.fromRGB(15, 12, 24)
	vp.BackgroundTransparency = 0.2
	vp.Ambient = Color3.fromRGB(150, 150, 175)
	vp.LightColor = Color3.fromRGB(255, 250, 235)
	vp.LightDirection = Vector3.new(-0.6, -1, -0.4)
	vp.Position = position
	vp.Size = size
	vp.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = vp

	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	camera.CFrame = CFrame.new(Vector3.new(0, 0.7, 7.5), Vector3.new(0, 0, 0))
	camera.Parent = vp
	vp.CurrentCamera = camera

	local world = Instance.new("WorldModel")
	world.Parent = vp

	local state = { vp = vp, world = world, camera = camera, model = nil, angle = math.random() * 6 }
	table.insert(live, state)
	vp.Destroying:Connect(function()
		for i, s in live do
			if s == state then
				table.remove(live, i)
				break
			end
		end
	end)
	return state
end

function CreaturePortrait.Show(
	_state: any,
	_speciesId: string?,
	_rarity: string?,
	_mutation: any,
	_silhouette: boolean?
)
	if _state and _state.model then
		_state.model:Destroy()
		_state.model = nil
	end
	if not _state or not _state.vp then
		return
	end
	_state.vp.BackgroundTransparency = 0.2
	local model = CreatureTemplates.Get(_speciesId or "")
	if model then
		model = model:Clone()
	else
		model = Instance.new("Model")
		local body = Instance.new("Part")
		body.Name = "Body"
		body.Shape = Enum.PartType.Ball
		body.Size = Vector3.new(2.4, 2.4, 2.4)
		body.Position = Vector3.new(0, 0, 0)
		body.Parent = model
		local eye = Instance.new("Part")
		eye.Name = "EyeL"
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(0.28, 0.28, 0.18)
		eye.Position = Vector3.new(-0.42, 0.35, -1.05)
		eye.Parent = model
		local eye2 = eye:Clone()
		eye2.Name = "EyeR"
		eye2.Position = Vector3.new(0.42, 0.35, -1.05)
		eye2.Parent = model
	end
	local definition = if _mutation and Mutations[_mutation]
		then Mutations[_mutation]
		else if _rarity then Rarities[_rarity] else nil
	local color = if _silhouette
		then Color3.fromRGB(20, 18, 28)
		else if definition then definition.Color else Color3.fromRGB(150, 155, 160)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.Color = if part.Name:find("Eye") then Color3.new(1, 1, 1) else color
			part.Material = Enum.Material.SmoothPlastic
		end
	end
	model:PivotTo(CFrame.new())
	model.Parent = _state.world
	_state.model = model
end

return CreaturePortrait
