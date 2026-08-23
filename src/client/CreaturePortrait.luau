local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Rarities = require(ReplicatedStorage.Shared.Data.Rarities)
local Mutations = require(ReplicatedStorage.Shared.Data.Mutations)

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

function CreaturePortrait.Show(state: any, speciesId: string?, rarity: string?, mutation: any)
	if state.model then
		state.model:Destroy()
		state.model = nil
	end
	if not speciesId then
		return
	end
	local templates = Workspace:FindFirstChild("Creatures")
	local template = templates and templates:FindFirstChild(speciesId)
	if not template then
		return
	end

	local model = template:Clone()
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
		end
	end
	if not model.PrimaryPart then
		model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart", true)
	end

	local def = (mutation ~= false and mutation and Mutations[mutation]) or Rarities[rarity or ""]
	local color = def and def.Color or Color3.new(1, 1, 1)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and not part.Name:find("Eye", 1, true) then
			part.Color = color
		end
	end

	local ext = model:GetExtentsSize()
	local maxDim = math.max(ext.X, ext.Y, ext.Z, 0.01)
	pcall(function()
		model:ScaleTo(3.6 / maxDim)
	end)
	model:PivotTo(CFrame.new())

	model.Parent = state.world
	state.model = model
end

return CreaturePortrait
