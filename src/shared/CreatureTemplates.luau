--!strict

-- Accès aux templates d'espèces (modèles sources clonés pour l'affichage).
-- Le serveur les déplace de Workspace vers ReplicatedStorage au boot ;
-- le fallback couvre les sessions où le boot serveur n'a pas tourné.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Rarities = require(ReplicatedStorage.Shared.Data.Rarities)
local Species = require(ReplicatedStorage.Shared.Data.Species)

local CreatureTemplates = {}
local fallback: { [string]: Model } = {}

local function Has(concept: string, word: string): boolean
	return string.find(string.lower(concept), word, 1, true) ~= nil
end

local function Detail(model: Model, name: string, size: Vector3, cframe: CFrame, color: Color3): WedgePart
	local part = Instance.new("WedgePart")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
	part.Parent = model
	return part
end

local function BuildFallback(speciesId: string): Model
	local cached = fallback[speciesId]
	if cached then
		return cached
	end

	local model = Instance.new("Model")
	model.Name = speciesId
	local definition = Species[speciesId]
	local concept = if definition then definition.Concept else speciesId
	local rarity = if definition then Rarities[definition.Rarity] else nil
	local color = if rarity then rarity.Color else Color3.fromRGB(150, 155, 160)
	local wide = Has(concept, "manta") or Has(concept, "shelled")
	local long = Has(concept, "eel") or Has(concept, "serpent") or Has(concept, "leviathan")
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = if wide
		then Vector3.new(3.8, 1.1, 2.7)
		elseif long then Vector3.new(3.4, 1.35, 1.35)
		elseif Has(concept, "colossus") or Has(concept, "titan") or Has(concept, "warden") then Vector3.new(
			3.1,
			2.8,
			2.6
		)
		else Vector3.new(2.4, 2, 2.4)
	body.Position = Vector3.new(0, 0, 0)
	body.Anchored = true
	body.CanCollide = false
	body.Material = Enum.Material.SmoothPlastic
	body.Color = color
	body.Parent = model

	if
		Has(concept, "wing")
		or Has(concept, "seraph")
		or Has(concept, "kite")
		or Has(concept, "wyvern")
		or Has(concept, "drake")
	then
		Detail(
			model,
			"WingL",
			Vector3.new(1.5, 0.8, 0.35),
			CFrame.new(-1.25, 0.35, 0.15) * CFrame.Angles(0, 0, math.rad(-18)),
			color
		)
		Detail(
			model,
			"WingR",
			Vector3.new(1.5, 0.8, 0.35),
			CFrame.new(1.25, 0.35, 0.15) * CFrame.Angles(0, 0, math.rad(18)),
			color
		)
	elseif Has(concept, "fin") or Has(concept, "manta") or Has(concept, "eel") or Has(concept, "leviathan") then
		Detail(
			model,
			"Fin",
			Vector3.new(1.1, 0.7, 0.45),
			CFrame.new(0, 0.7, 0.7) * CFrame.Angles(math.rad(-25), 0, 0),
			color
		)
		Detail(
			model,
			"FinSideL",
			Vector3.new(0.8, 0.45, 0.3),
			CFrame.new(-1.45, 0, 0.2) * CFrame.Angles(0, 0, math.rad(-30)),
			color
		)
		Detail(
			model,
			"FinSideR",
			Vector3.new(0.8, 0.45, 0.3),
			CFrame.new(1.45, 0, 0.2) * CFrame.Angles(0, 0, math.rad(30)),
			color
		)
	else
		Detail(
			model,
			"Fin",
			Vector3.new(0.9, 0.9, 0.45),
			CFrame.new(0, 0.75, 0.7) * CFrame.Angles(math.rad(-25), 0, 0),
			color
		)
	end

	if
		Has(concept, "horn")
		or Has(concept, "antler")
		or Has(concept, "ram")
		or Has(concept, "stag")
		or Has(concept, "doe")
	then
		Detail(
			model,
			"HornL",
			Vector3.new(0.35, 1.1, 0.35),
			CFrame.new(-0.55, 1.15, -0.2) * CFrame.Angles(math.rad(-20), 0, math.rad(-12)),
			color
		)
		Detail(
			model,
			"HornR",
			Vector3.new(0.35, 1.1, 0.35),
			CFrame.new(0.55, 1.15, -0.2) * CFrame.Angles(math.rad(-20), 0, math.rad(12)),
			color
		)
	end

	if Has(concept, "shell") or Has(concept, "armored") or Has(concept, "colossus") or Has(concept, "titan") then
		local shell = Instance.new("Part")
		shell.Name = "Shell"
		shell.Shape = Enum.PartType.Cylinder
		shell.Size = Vector3.new(0.45, 2.2, 2.2)
		shell.CFrame = CFrame.new(0, 0.15, 0.9) * CFrame.Angles(0, 0, math.rad(90))
		shell.Anchored = true
		shell.CanCollide = false
		shell.Material = Enum.Material.SmoothPlastic
		shell.Color = color
		shell.Parent = model
	end

	if
		Has(concept, "tail")
		or Has(concept, "fox")
		or Has(concept, "pup")
		or Has(concept, "crawler")
		or Has(concept, "mole")
	then
		Detail(
			model,
			"Tail",
			Vector3.new(0.45, 0.45, 1.5),
			CFrame.new(0, 0.15, 1.55) * CFrame.Angles(math.rad(25), 0, 0),
			color
		)
	end

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
