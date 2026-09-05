--!strict

-- Accès aux templates d'espèces (modèles sources clonés pour l'affichage).
-- Le serveur les déplace de Workspace vers ReplicatedStorage au boot ;
-- le fallback couvre les sessions où le boot serveur n'a pas tourné.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CreatureTemplates = {}
local fallback: { [string]: Model } = {}

local function BuildFallback(speciesId: string): Model
	local cached = fallback[speciesId]
	if cached then
		return cached
	end

	local model = Instance.new("Model")
	model.Name = speciesId
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(2.4, 2, 2.4)
	body.Position = Vector3.new(0, 0, 0)
	body.Anchored = true
	body.CanCollide = false
	body.Material = Enum.Material.SmoothPlastic
	body.Parent = model

	local fin = Instance.new("WedgePart")
	fin.Name = "Fin"
	fin.Size = Vector3.new(0.9, 0.9, 0.45)
	fin.CFrame = CFrame.new(0, 0.75, 0.7) * CFrame.Angles(math.rad(-25), 0, 0)
	fin.Anchored = true
	fin.CanCollide = false
	fin.Material = Enum.Material.SmoothPlastic
	fin.Parent = model

	for side, x in { L = -0.42, R = 0.42 } do
		local eye = Instance.new("Part")
		eye.Name = `Eye{side}`
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(0.28, 0.28, 0.18)
		eye.CFrame = CFrame.new(x, 0.35, -1.05)
		eye.Anchored = true
		eye.CanCollide = false
		eye.Material = Enum.Material.Neon
		eye.Color = Color3.new(1, 1, 1)
		eye.Parent = model
	end

	model.PrimaryPart = body
	fallback[speciesId] = model
	return model
end

local function FindModel(folder: Instance?, speciesId: string): Model?
	local candidate = folder and folder:FindFirstChild(speciesId)
	return if candidate and candidate:IsA("Model") then candidate else nil
end

function CreatureTemplates.Get(speciesId: string): Model?
	local folder = ReplicatedStorage:FindFirstChild("CreatureTemplates")
	if folder then
		return FindModel(folder, speciesId) or BuildFallback(speciesId)
	end
	folder = Workspace:FindFirstChild("Creatures")
	return FindModel(folder, speciesId) or BuildFallback(speciesId)
end

return CreatureTemplates
