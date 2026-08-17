local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Rarities = require(ReplicatedStorage.Shared.Data.Rarities)
local Mutations = require(ReplicatedStorage.Shared.Data.Mutations)
local Species = require(ReplicatedStorage.Shared.Data.Species)
local Equipment = require(ReplicatedStorage.Shared.Data.Equipment)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Sanctuary = require(ReplicatedStorage.Shared.Sanctuary)
local Net = require(ReplicatedStorage.Shared.Net)

local HatchService = {}

local log
local essenceService
local saveService
local indexService
local questService

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

local function Announce(player: Player, roll)
	local announceRank = Gameplay.RarityRank(Config.ANNOUNCE_MIN_RARITY)
	if Gameplay.RarityRank(roll.Rarity) < announceRank then
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

local function CollarBonus(profile): number
	local bonus = 0
	for _, creature in profile.Data.Creatures do
		for _, item in creature.Equipment do
			if item.Type == "Collar" then
				local def = Equipment.Collar.Tiers[item.Tier]
				if def then
					bonus += def.MutationChanceBonus
				end
			end
		end
	end
	return math.min(bonus, Config.COLLAR_MUTATION_CAP)
end

function HatchService:Init(container)
	log = container:Get("Log")
	essenceService = container:Get("EssenceService")
	saveService = container:Get("SaveService")
	indexService = container:Get("IndexService")
	questService = container:Get("QuestService")
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

		local maxCreatures = Sanctuary.MaxCreatures(profile.Data.SanctuaryLevel)
		if #profile.Data.Creatures >= maxCreatures then
			log:Economy("Hatch", "CapReached", {
				Player = player.Name,
				Creatures = #profile.Data.Creatures,
				MaxCreatures = maxCreatures,
			})
			return
		end

		local egg = table.remove(profile.Data.Eggs, eggIndex)
		local rarityWeights = nil
		if profile.Data.Stats.TotalHatched == 0 and egg.Tier == "CommonEgg" then
			rarityWeights = Config.FIRST_HATCH_WEIGHTS
		end
		local roll = Gameplay.RollEgg(egg.Tier, CollarBonus(profile), rarityWeights)
		local creature = Gameplay.CreateCreature(roll.Rarity, roll.SpeciesId, roll.Mutation)

		table.insert(profile.Data.Creatures, creature)
		profile.Data.Stats.TotalHatched += 1
		profile.Data.LastPlayed = os.time()
		indexService:Register(player, roll.SpeciesId, roll.Rarity, roll.Mutation)

		local species = Species[roll.SpeciesId]
		local mutationName = roll.Mutation ~= false and Mutations[roll.Mutation].Name or nil
		local announced = Gameplay.RarityRank(roll.Rarity) >= Gameplay.RarityRank(Config.ANNOUNCE_MIN_RARITY)
		questService:OnHatch(player, roll.Mutation ~= false)

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
