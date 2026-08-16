local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Rarities = require(ReplicatedStorage.Shared.Data.Rarities)
local Mutations = require(ReplicatedStorage.Shared.Data.Mutations)
local Species = require(ReplicatedStorage.Shared.Data.Species)
local Net = require(ReplicatedStorage.Shared.Net)

local HatchService = {}

local log
local essenceService
local saveService

local function WeightedRoll(weights: { [string]: number }): string
	local total = 0
	for _, weight in weights do
		total += weight
	end
	local roll = Random.new():NextNumber() * total
	for key, weight in weights do
		roll -= weight
		if roll <= 0 then
			return key
		end
	end
	return (next(weights))
end

function HatchService.RollEgg(tier: string)
	local weights = Config.EGG_RARITY_WEIGHTS[tier]
	local rarity = WeightedRoll(weights)

	local pool = {}
	for speciesId, def in Species do
		if def.Rarity == rarity then
			table.insert(pool, speciesId)
		end
	end
	local speciesId = pool[Random.new():NextInteger(1, #pool)]

	local mutationWeight = WeightedRoll(Config.MUTATION_WEIGHTS)
	local mutation = mutationWeight == "None" and false or mutationWeight

	return {
		SpeciesId = speciesId,
		Rarity = rarity,
		Mutation = mutation,
	}
end

function HatchService.CreateCreature(rarity: string, speciesId: string, mutation)
	local species = Species[speciesId]
	local rarityDef = Rarities[rarity]
	local mutationDef = mutation ~= false and Mutations[mutation] or nil
	local power = math.round(species.BasePower * rarityDef.PowerMult * (mutationDef and mutationDef.Multiplier or 1))

	return {
		Id = HttpService:GenerateGUID(false),
		SpeciesId = speciesId,
		Rarity = rarity,
		Mutation = mutation,
		Level = 1,
		Power = power,
	}
end

function HatchService:GrantEgg(player: Player, tier: string, source: string)
	local profile = saveService:GetProfile(player)
	if not profile then
		return
	end
	local egg = {
		Id = HttpService:GenerateGUID(false),
		Tier = tier,
		Timestamp = os.time(),
	}
	table.insert(profile.Data.Eggs, egg)
	profile.Data.LastPlayed = os.time()
	log:Economy("Eggs", "Grant", { Player = player.Name, Tier = tier, Source = source, EggId = egg.Id })
end

local function RarityRank(rarity: string): number
	local rank = table.find(Rarities.ORDER, rarity)
	return rank or 0
end

local function Announce(player: Player, roll)
	local announceRank = RarityRank(Config.ANNOUNCE_MIN_RARITY)
	if RarityRank(roll.Rarity) < announceRank then
		return
	end

	local mutationName = roll.Mutation ~= false and Mutations[roll.Mutation].Name or nil

	local payload = {
		PlayerName = player.Name,
		SpeciesName = Species[roll.SpeciesId].Name,
		RarityName = Rarities[roll.Rarity].Name,
		MutationName = mutationName,
	}

	Net.RareDrop:FireAllClients(payload)
	log:Economy("Hatch", "Announce", payload)
end

function HatchService:Init(container)
	log = container:Get("Log")
	essenceService = container:Get("EssenceService")
	saveService = container:Get("SaveService")
end

function HatchService:Start()
	Net.BuyEgg.OnServerEvent:Connect(function(player: Player, tier: string)
		local price = Config.EGG_PRICES[tier]
		if not price then
			return
		end
		if not essenceService:Spend(player, price, `BuyEgg_{tier}`) then
			return
		end
		self:GrantEgg(player, tier, "Purchase")
	end)

	Net.HatchEgg.OnServerEvent:Connect(function(player: Player, eggId: string)
		local profile = saveService:GetProfile(player)
		if not profile then
			return
		end

		local eggIndex = nil
		for i, egg in profile.Data.Eggs do
			if egg.Id == eggId then
				eggIndex = i
				break
			end
		end
		if not eggIndex then
			return
		end

		local egg = table.remove(profile.Data.Eggs, eggIndex)
		local roll = HatchService.RollEgg(egg.Tier)
		local creature = HatchService.CreateCreature(roll.Rarity, roll.SpeciesId, roll.Mutation)

		table.insert(profile.Data.Creatures, creature)
		profile.Data.Stats.TotalHatched += 1
		profile.Data.LastPlayed = os.time()

		local species = Species[roll.SpeciesId]
		local mutationName = roll.Mutation ~= false and Mutations[roll.Mutation].Name or nil
		local announced = RarityRank(roll.Rarity) >= RarityRank(Config.ANNOUNCE_MIN_RARITY)

		Net.HatchResult:FireClient(player, {
			EggId = eggId,
			Creature = creature,
			SpeciesName = species.Name,
			RarityName = Rarities[roll.Rarity].Name,
			RarityColor = Rarities[roll.Rarity].Color,
			MutationName = mutationName,
			Announced = announced,
		})

		log:Economy("Hatch", "Success", {
			Player = player.Name,
			Tier = egg.Tier,
			Species = roll.SpeciesId,
			Rarity = roll.Rarity,
			Mutation = tostring(roll.Mutation),
			CreatureId = creature.Id,
		})

		Announce(player, roll)
	end)
end

return HatchService
