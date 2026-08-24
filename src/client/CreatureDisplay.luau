local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Net = require(ReplicatedStorage.Shared.Net)
local Rarities = require(ReplicatedStorage.Shared.Data.Rarities)
local Mutations = require(ReplicatedStorage.Shared.Data.Mutations)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local CreatureTemplates = require(ReplicatedStorage.Shared.CreatureTemplates)
local Fx = require(script.Parent.Fx)
local CreatureHud = require(script.Parent.CreatureHud)
local HoverCard = require(script.Parent.HoverCard)

local CreatureDisplay = {}
CreatureDisplay.Motion = {}

local TINTS = require(script.Parent.UiKit).TINTS

local spawned: { [string]: Model } = {}
local bases: { [string]: CFrame } = {}
local order: { [string]: number } = {}
local stages: { [string]: number } = {}
local ranks: { [string]: number } = {}
local pops: { [string]: number } = {}
local sanctuary: Folder? = nil
local lastEssence = 0
local lastState = nil

function CreatureDisplay.Models()
	return spawned
end

function CreatureDisplay.Creatures()
	return if lastState then lastState.Creatures else {}
end

-- Source unique de l'identité du compagnon choisi (nil = aucun).
function CreatureDisplay.CompanionId(): string?
	return if lastState then lastState.CompanionId else nil
end

local RARITY_SIZE = { 1, 1.12, 1.25, 1.38, 1.5, 1.62, 1.75, 1.9 }
local RARITY_PARTICLES = { 0, 4, 10, 16, 24, 32, 44, 60 }

-- Nouveau-né > juvénile > adolescent > adulte : silhouette clairement distincte.
local STAGE_SCALE = { 0.55, 0.8, 1.05, 1.3 }
local STAGE_INFO = {
	{ Name = "Nouveau-né", Color = Color3.fromRGB(255, 236, 210) },
	{ Name = "Juvénile", Color = Color3.fromRGB(140, 220, 150) },
	{ Name = "Adolescent", Color = Color3.fromRGB(255, 178, 92) },
	{ Name = "Adulte", Color = Color3.fromRGB(255, 215, 94) },
}

-- FX par mutation : matériau + teinte particules + intensité lumière.
local MUTATION_FX = {
	Shadow = { Material = Enum.Material.SmoothPlastic, Particle = Color3.fromRGB(45, 45, 65), Light = 0.4 },
	Frost = { Material = Enum.Material.Ice, Particle = Color3.fromRGB(200, 240, 255), Light = 0.8 },
	Golden = { Material = Enum.Material.Metal, Particle = Color3.fromRGB(255, 220, 120), Light = 1.2 },
	Prismatic = { Material = Enum.Material.Neon, Rainbow = true, Light = 1.4 },
	Corrupted = { Material = Enum.Material.Slate, Particle = Color3.fromRGB(120, 40, 160), Light = 0.7 },
	Celestial = { Material = Enum.Material.ForceField, Particle = Color3.fromRGB(255, 255, 255), Light = 2 },
}

local mutations: { [string]: string? } = {}

local function MutationScale(mutation: any): number
	if mutation ~= false and Mutations[mutation] then
		return 1 + math.log10(Mutations[mutation].Multiplier) * 0.06
	end
	return 1
end

local function DisplayColor(creature): Color3
	if creature.Mutation ~= false and Mutations[creature.Mutation] then
		return Mutations[creature.Mutation].Color
	end
	return Rarities[creature.Rarity].Color
end

local function PrepareClone(model: Model)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end
	if not model.PrimaryPart then
		local first = model:FindFirstChildWhichIsA("BasePart", true)
		if first then
			model.PrimaryPart = first
		end
	end
end

local function GridPosition(index: number): CFrame
	local row = math.floor((index - 1) / 8)
	local column = (index - 1) % 8
	return CFrame.new(-36 + column * 3, 11, -18 + row * 3) * CFrame.Angles(0, math.rad(180), 0)
end

function CreatureDisplay.Refresh(state)
	if not sanctuary or not sanctuary.Parent then
		sanctuary = Instance.new("Folder")
		sanctuary.Name = "SanctuaryDisplay"
		sanctuary.Parent = Workspace
	end

	local alive = {}
	for _, creature in state.Creatures do
		alive[creature.Id] = true
	end

	-- Transition de compagnon : libère l'ancien et le nouveau du mode follow
	-- (sinon une créature rappelée reste figée hors grille).
	local previousCompanion = if lastState then lastState.CompanionId else nil
	if previousCompanion ~= state.CompanionId then
		if previousCompanion then
			CreatureDisplay.Motion[previousCompanion] = nil
		end
		if state.CompanionId then
			CreatureDisplay.Motion[state.CompanionId] = nil
		end
	end

	for id, model in spawned do
		if not alive[id] then
			model:Destroy()
			spawned[id] = nil
			bases[id] = nil
			order[id] = nil
			stages[id] = nil
			pops[id] = nil
		end
	end

	local index = 0
	for _, creature in state.Creatures do
		index += 1
		order[creature.Id] = index
		local rank = math.max(1, Gameplay.RarityRank(creature.Rarity))
		ranks[creature.Id] = rank
		local displayColor = DisplayColor(creature)
		local model = spawned[creature.Id]
		if not model or not model.Parent then
			local template = CreatureTemplates.Get(creature.SpeciesId)
			if not template then
				continue
			end
			model = template:Clone()
			model.Name = `Display_{creature.SpeciesId}`
			model:SetAttribute("CreatureId", creature.Id)
			PrepareClone(model)
			model.Parent = sanctuary
			spawned[creature.Id] = model
			local click = Instance.new("ClickDetector")
			click.MaxActivationDistance = 40
			click.MouseClick:Connect(function()
				local primary = model.PrimaryPart
				if primary then
					Fx.Burst(primary, DisplayColor(creature), 26)
					pops[creature.Id] = os.clock() + 0.5
				end
				CreatureHud.Open(creature, lastState)
			end)
			if model.PrimaryPart then
				click.Parent = model.PrimaryPart
			end
			local stage = STAGE_INFO[creature.Stage or 1]
			if stage then
				local billboard = Instance.new("BillboardGui")
				billboard.Name = "StageTag"
				billboard.Size = UDim2.fromOffset(90, 20)
				billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.2, 0)
				billboard.AlwaysOnTop = false
				billboard.MaxDistance = 60
				billboard.Adornee = model.PrimaryPart
				local tag = Instance.new("TextLabel")
				tag.Size = UDim2.fromScale(1, 1)
				tag.BackgroundTransparency = 0.35
				tag.BackgroundColor3 = Color3.fromRGB(15, 12, 24)
				tag.TextColor3 = stage.Color
				tag.Font = Enum.Font.GothamBold
				tag.TextSize = 11
				tag.Text = stage.Name
				tag.Parent = billboard
				billboard.Parent = model
			end
			local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
			if primary then
				Fx.Burst(primary, displayColor, 26)
				if rank >= 2 then
					local aura = Instance.new("Part")
					aura.Name = "Aura"
					aura.Shape = Enum.PartType.Cylinder
					aura.Size = Vector3.new(2.6, 0.15, 2.6)
					aura.Position = primary.Position + Vector3.new(0, -1.4, 0)
					aura.Anchored = true
					aura.CanCollide = false
					aura.CanQuery = false
					aura.CanTouch = false
					aura.CastShadow = false
					aura.Material = Enum.Material.Neon
					aura.Color = displayColor
					aura.Transparency = 0.45
					aura.Parent = model
					local glow = Instance.new("PointLight")
					glow.Color = displayColor
					glow.Brightness = 0.6 + rank * 0.12
					glow.Range = 8
					glow.Shadows = false
					glow.Parent = aura
					local emitter = Instance.new("ParticleEmitter")
					emitter.Name = "Ambient"
					emitter.Rate = RARITY_PARTICLES[rank] or 0
					emitter.Lifetime = NumberRange.new(1, 2)
					emitter.Speed = NumberRange.new(0.5, 1.5)
					emitter.SpreadAngle = Vector2.new(10, 60)
					emitter.EmissionDirection = Enum.NormalId.Top
					emitter.Size =
						NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0.6) })
					emitter.Transparency =
						NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
					emitter.Color = ColorSequence.new(displayColor)
					emitter.LightEmission = 0.5
					emitter.LightInfluence = 0
					emitter.Parent = primary
				end
			end
		end

		local scale = (STAGE_SCALE[creature.Stage or 1] or 1)
			* (RARITY_SIZE[rank] or 1)
			* MutationScale(creature.Mutation)
		if model.PrimaryPart then
			-- Le compagnon n'occupe pas de slot : sa base reste celle du follow.
			if state.CompanionId ~= creature.Id then
				bases[creature.Id] = GridPosition(index)
				if not CreatureDisplay.Motion[creature.Id] then
					model:PivotTo(bases[creature.Id])
				end
			end
			pcall(function()
				model:ScaleTo(scale)
			end)
		end
		local previousStage = stages[creature.Id]
		if previousStage and creature.Stage > previousStage then
			local primary = model.PrimaryPart
			if primary then
				Fx.Burst(primary, Color3.fromRGB(255, 215, 90), 34)
			end
		end
		stages[creature.Id] = creature.Stage
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				if part.Name ~= "Aura" then
					part.Color = displayColor
				end
			end
		end
		local mutated = creature.Mutation ~= false and creature.Mutation or nil
		mutations[creature.Id] = mutated
		local fx = mutated and MUTATION_FX[mutated] or nil
		if fx then
			for _, part in model:GetDescendants() do
				if part:IsA("BasePart") and part.Name ~= "Aura" and not part.Name:find("Eye", 1, true) then
					part.Material = fx.Material
				end
			end
			local aura = model:FindFirstChild("Aura")
			if aura then
				local glow = aura:FindFirstChildOfClass("PointLight")
				if glow then
					glow.Brightness = math.max(glow.Brightness, fx.Light or 0)
				end
				local emitter = model.PrimaryPart and model.PrimaryPart:FindFirstChild("Ambient")
				if emitter and fx.Particle then
					emitter.Color = ColorSequence.new(fx.Particle)
				end
			end
		end
		local aura = model:FindFirstChild("Aura")
		if aura then
			aura.Color = displayColor
			local glow = aura:FindFirstChildOfClass("PointLight")
			if glow then
				glow.Color = displayColor
			end
			local emitter = model.PrimaryPart and model.PrimaryPart:FindFirstChild("Ambient")
			if emitter then
				emitter.Color = ColorSequence.new(displayColor)
			end
		end
	end
end

RunService.Heartbeat:Connect(function(t)
	for id, model in spawned do
		if CreatureDisplay.Motion[id] then
			continue
		end
		local base = bases[id]
		local idx = order[id] or 0
		local rank = ranks[id] or 1
		local stage = stages[id] or 1
		if base and model.PrimaryPart then
			local bobAmp = 0.15 + (rank - 1) * 0.06 + (stage == 1 and 0.08 or 0)
			local bobSpeed = stage <= 2 and 3.2 or 2
			local bob = math.sin(t * bobSpeed + idx * 0.8) * bobAmp
			local tilt = math.sin(t * 1.3 + idx * 0.8) * 0.02
			local popUntil = pops[id] or 0
			local pop = 0
			if t < popUntil then
				pop = math.sin((popUntil - t) * 8) * 1.2
			end
			model:PivotTo(base * CFrame.new(0, bob + pop, 0) * CFrame.Angles(0, 0, tilt))
		end
		if mutations[id] == "Prismatic" then
			local aura = model:FindFirstChild("Aura")
			if aura then
				local hue = (t * 0.18 + idx * 0.13) % 1
				aura.Color = Color3.fromHSV(hue, 0.75, 1)
				local glow = aura:FindFirstChildOfClass("PointLight")
				if glow then
					glow.Color = aura.Color
				end
			end
		end
	end
end)

Net.Sync.OnClientEvent:Connect(function(state)
	CreatureDisplay.Refresh(state)
	lastState = state
	local gained = state.Essence - lastEssence
	lastEssence = state.Essence
	if gained >= 1 then
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			Fx.FloatText(root.Position + Vector3.new(0, 5, 0), `+{math.floor(gained)}`, TINTS.ACCENT)
		end
	end
end)

local mouse = Players.LocalPlayer:GetMouse()
local hoveredId: string? = nil
local lastHoverCheck = 0

RunService.RenderStepped:Connect(function()
	local now = os.clock()
	if now - lastHoverCheck < 0.05 then
		return
	end
	lastHoverCheck = now

	local model = nil
	local node = mouse.Target
	while node and node ~= Workspace do
		if node:IsA("Model") and node:GetAttribute("CreatureId") then
			model = node
			break
		end
		node = node.Parent
	end

	local id = model and model:GetAttribute("CreatureId")
	if id == hoveredId then
		return
	end
	hoveredId = id

	local creature = nil
	if id and lastState then
		for _, candidate in lastState.Creatures do
			if candidate.Id == id then
				creature = candidate
				break
			end
		end
	end
	if creature then
		HoverCard.Show(model.PrimaryPart or model, {
			SpeciesId = creature.SpeciesId,
			Rarity = creature.Rarity,
			Mutation = creature.Mutation,
			Level = creature.Level,
			Power = creature.Power,
			SuggestedPrice = CreatureHud.SuggestedPrice(creature.Rarity),
		})
	else
		HoverCard.Hide()
	end
end)

return CreatureDisplay
