local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Species = require(ReplicatedStorage.Shared.Data.Species)
local Evolution = require(ReplicatedStorage.Shared.Evolution)
local Net = require(ReplicatedStorage.Shared.Net)

local EvolutionService = {}

local log
local saveService
local essenceService
local dataSync

local function FindCreature(creatures: { any }, creatureId: string)
	for i, creature in creatures do
		if creature.Id == creatureId then
			return creature, i
		end
	end
	return nil, nil
end

function EvolutionService:Init(container)
	log = container:Get("Log")
	saveService = container:Get("SaveService")
	essenceService = container:Get("EssenceService")
	dataSync = container:Get("DataSync")
end

function EvolutionService:Start()
	Net.EvolveCreature.OnServerEvent:Connect(function(player: Player, creatureId: string)
		local profile = saveService:GetProfile(player)
		if not profile then
			return
		end
		local creature = FindCreature(profile.Data.Creatures, creatureId)
		if not creature then
			return
		end

		local ok, reason = Evolution.CanEvolve(creature, profile.Data.Essence)
		if not ok then
			log:Economy("Evolution", "Reject", { Player = player.Name, Creature = creature.Id, Reason = reason })
			return
		end

		local cost = Evolution.EvolveCost(creature)
		if not essenceService:Spend(player, cost, `Evolve_{creature.SpeciesId}`) then
			return
		end

		creature.Stage += 1
		Evolution.ConsumeRelic(creature)
		creature.MaxLevel = Evolution.MaxLevelFor(creature)
		creature.Power = Evolution.ComputePower(creature)
		profile.Data.LastPlayed = os.time()

		log:Economy("Evolution", "Stage", {
			Player = player.Name,
			Creature = creature.Id,
			Species = creature.SpeciesId,
			Stage = creature.Stage,
			Cost = cost,
		})
		dataSync:Send(player)
	end)

	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator < 1 then
			return
		end
		accumulator = 0

		for _, profile in pairs(saveService.Profiles) do
			local leveledAny = false
			for _, creature in profile.Data.Creatures do
				local species = Species[creature.SpeciesId]
				local xp = Config.CREATURE_XP_PER_SECOND * (species and species.BaseRate or 1)
				if Evolution.AddXP(creature, xp) then
					leveledAny = true
				end
			end
			if leveledAny then
				profile.Data.LastPlayed = os.time()
			end
		end
	end)
end

return EvolutionService
