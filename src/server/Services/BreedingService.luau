local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Breeding = require(ReplicatedStorage.Shared.Breeding)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Sanctuary = require(ReplicatedStorage.Shared.Sanctuary)
local Net = require(ReplicatedStorage.Shared.Net)

local BreedingService = {}

local log
local saveService
local essenceService
local indexService
local dataSync
local questService

local cooldowns: { [Player]: number } = {}

local function FindCreature(creatures: { any }, creatureId: string)
	for _, creature in creatures do
		if creature.Id == creatureId then
			return creature
		end
	end
	return nil
end

function BreedingService:Init(container)
	log = container:Get("Log")
	saveService = container:Get("SaveService")
	essenceService = container:Get("EssenceService")
	indexService = container:Get("IndexService")
	dataSync = container:Get("DataSync")
	questService = container:Get("QuestService")
end

function BreedingService:Start()
	Net.BreedCreatures.OnServerEvent:Connect(function(player: Player, fatherId: string, motherId: string)
		local profile = saveService:GetProfile(player)
		if not profile then
			return
		end

		local last = cooldowns[player] or 0
		if os.clock() - last < Config.BREED_COOLDOWN then
			return
		end

		local father = FindCreature(profile.Data.Creatures, fatherId)
		local mother = FindCreature(profile.Data.Creatures, motherId)
		local ok, reason = Breeding.CanBreed(father, mother)
		if not ok then
			log:Economy("Breeding", "Reject", { Player = player.Name, Reason = reason })
			return
		end

		local maxCreatures = Sanctuary.MaxCreatures(profile.Data.SanctuaryLevel)
		if #profile.Data.Creatures >= maxCreatures then
			log:Economy("Breeding", "CapReached", {
				Player = player.Name,
				Creatures = #profile.Data.Creatures,
				MaxCreatures = maxCreatures,
			})
			return
		end

		if not essenceService:Spend(player, Config.BREED_COST, `Breed_{father.SpeciesId}`) then
			return
		end
		cooldowns[player] = os.clock()

		local roll = Breeding.RollChild(father, mother)
		local child = Gameplay.CreateCreature(roll.Rarity, roll.SpeciesId, roll.Mutation)
		child.Parents = roll.Parents
		child.Generation = roll.Generation

		table.insert(profile.Data.Creatures, child)
		profile.Data.Stats.TotalHatched += 1
		profile.Data.LastPlayed = os.time()
		indexService:Register(player, child.SpeciesId, child.Rarity, child.Mutation)

		Net.BreedResult:FireClient(player, {
			FatherId = father.Id,
			MotherId = mother.Id,
			Creature = child,
		})

		profile.Data.Stats.TotalBred += 1
		questService:OnBreed(player)

		log:Economy("Breeding", "Success", {
			Player = player.Name,
			Father = father.Id,
			Mother = mother.Id,
			Species = child.SpeciesId,
			Rarity = child.Rarity,
			Mutation = tostring(child.Mutation),
			Generation = child.Generation,
			ChildId = child.Id,
		})
		dataSync:Send(player)
	end)
end

return BreedingService
