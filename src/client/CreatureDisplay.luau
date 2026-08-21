local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Net = require(ReplicatedStorage.Shared.Net)
local Rarities = require(ReplicatedStorage.Shared.Data.Rarities)
local Mutations = require(ReplicatedStorage.Shared.Data.Mutations)
local Fx = require(script.Parent.Fx)
local CreatureHud = require(script.Parent.CreatureHud)

local CreatureDisplay = {}

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

local RARITY_SIZE = { 1, 1.12, 1.25, 1.38, 1.5, 1.62, 1.75, 1.9 }
local RARITY_PARTICLES = { 0, 4, 10, 16, 24, 32, 44, 60 }

local function RarityRank(rarity: string): number
	for i, name in Rarities.ORDER do
		if name == rarity then
			return i
		end
	end
	return 1
end

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
	local templates = Workspace:FindFirstChild("Creatures")
	if not templates then
		return
	end

	if not sanctuary or not sanctuary.Parent then
		sanctuary = Instance.new("Folder")
		sanctuary.Name = "SanctuaryDisplay"
		sanctuary.Parent = Workspace
	end

	local alive = {}
	for _, creature in state.Creatures do
		alive[creature.Id] = true
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
		local rank = RarityRank(creature.Rarity)
		ranks[creature.Id] = rank
		local displayColor = DisplayColor(creature)
		local model = spawned[creature.Id]
		if not model or not model.Parent then
			local template = templates:FindFirstChild(creature.SpeciesId)
			if not template then
				continue
			end
			model = template:Clone()
			model.Name = `Display_{creature.SpeciesId}`
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

		local scale = (1 + (creature.Stage - 1) * 0.25) * (RARITY_SIZE[rank] or 1) * MutationScale(creature.Mutation)
		if model.PrimaryPart then
			bases[creature.Id] = GridPosition(index)
			model:PivotTo(bases[creature.Id])
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
		local base = bases[id]
		local idx = order[id] or 0
		local rank = ranks[id] or 1
		if base and model.PrimaryPart then
			local bob = math.sin(t * 2 + idx * 0.8) * (0.15 + (rank - 1) * 0.06)
			local tilt = math.sin(t * 1.3 + idx * 0.8) * 0.02
			local popUntil = pops[id] or 0
			local pop = 0
			if t < popUntil then
				pop = math.sin((popUntil - t) * 8) * 1.2
			end
			model:PivotTo(base * CFrame.new(0, bob + pop, 0) * CFrame.Angles(0, 0, tilt))
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

return CreatureDisplay
