local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Species = require(ReplicatedStorage.Shared.Data.Species)
local Fx = require(script.Parent.Fx)
local CreatureDisplay = require(script.Parent.CreatureDisplay)
local FollowController = require(script.Parent.FollowController)

local FarmBehaviors = {}

local DIRT_COLOR = Color3.fromRGB(110, 80, 50)
local NUGGET_COLOR = Color3.fromRGB(255, 200, 60)

local home: { [string]: CFrame } = {}
local nextDig: { [string]: number } = {}
local digStart: { [string]: number } = {}
local fxDone: { [string]: boolean } = {}
local claimed: { [string]: boolean } = {}

local function Hash(id: string): number
	local sum = 0
	for i = 1, #id do
		sum += string.byte(id, i)
	end
	return sum % 100 / 100
end

local function RoleFor(creature): string
	local def = Species[creature.SpeciesId]
	return (def and def.Role) or "Digger"
end

-- Cycle de creusage partagé : retourne le décalage y et déclenche les effets.
-- base CFrame fournie par l'appelant (grille ou position du compagnon).
local function ApplyDig(id: string, t: number, base: CFrame, model: Model): boolean
	local started = digStart[id]
	local digging = started ~= nil and t - started < 1.2
	if not digging and t >= (nextDig[id] or 0) then
		digStart[id] = t
		fxDone[id] = false
		digging = true
	end
	if not digging then
		model:PivotTo(base * CFrame.new(0, math.sin(t * 2 + Hash(id) * 8) * 0.12, 0))
		return false
	end

	local elapsed = t - digStart[id]
	local dip = 0
	if elapsed < 0.3 then
		dip = -0.5 * math.sin(elapsed / 0.3 * math.pi / 2)
	elseif elapsed < 0.7 then
		dip = -0.5
		if not fxDone[id] then
			fxDone[id] = true
			Fx.Burst(model.PrimaryPart :: BasePart, DIRT_COLOR, 10)
		end
	else
		dip = -0.5 * math.cos((elapsed - 0.7) / 0.5 * math.pi / 2)
		if elapsed > 0.9 and fxDone[id] then
			Fx.Confetti(model:GetPivot().Position + Vector3.new(0, 1, 0), NUGGET_COLOR, 6)
			fxDone[id] = false
			nextDig[id] = t + 6 + Hash(id) * 4
			digStart[id] = nil
		end
	end
	model:PivotTo(base * CFrame.new(0, dip, 0))
	return true
end

function FarmBehaviors.Start()
	-- Heartbeat passe deltaTime : on accumule pour un temps absolu d'animation
	local elapsed = 0
	RunService.Heartbeat:Connect(function(deltaTime)
		elapsed += deltaTime
		local models = CreatureDisplay.Models()
		local creatures = CreatureDisplay.Creatures()
		local seen = {}

		for _, creature in creatures do
			local id = creature.Id
			seen[id] = true

			local model = models[id]
			if not model or not model.PrimaryPart then
				continue
			end

			-- Compagnon : suit le joueur ; creuse à ses côtés quand il est à l'arrêt.
			if CreatureDisplay.Motion[id] == "follow" then
				local companionBase = FollowController.Current[id]
				if companionBase and FollowController.Idle then
					ApplyDig(id, elapsed, companionBase, model)
				end
				continue
			end

			if not claimed[id] then
				CreatureDisplay.Motion[id] = "farm"
				claimed[id] = true
				home[id] = model:GetPivot()
				nextDig[id] = elapsed + 2 + Hash(id) * 4
			end

			local role = RoleFor(creature)
			local base = home[id]
			local seed = Hash(id)

			if role == "Gatherer" then
				local angle = elapsed * 0.8 + seed * math.pi * 2
				local x = math.cos(angle) * 2.6
				local z = math.sin(angle) * 2.6
				model:PivotTo(base * CFrame.new(x, 0, z) * CFrame.Angles(0, -angle + math.pi / 2, 0))
			elseif role == "Guardian" then
				local phaseT = elapsed * 0.9 + seed * 6
				local x = math.sin(phaseT) * 3.2
				local facing = if math.cos(phaseT) >= 0 then 90 else -90
				model:PivotTo(base * CFrame.new(x, 0, 0) * CFrame.Angles(0, math.rad(facing), 0))
			else
				ApplyDig(id, elapsed, base, model)
			end
		end

		for id in claimed do
			if not seen[id] then
				claimed[id] = nil
				home[id] = nil
				nextDig[id] = nil
				digStart[id] = nil
				fxDone[id] = nil
				CreatureDisplay.Motion[id] = nil
			end
		end
	end)
end

return FarmBehaviors
