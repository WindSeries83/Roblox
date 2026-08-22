local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Ascension = require(ReplicatedStorage.Shared.Ascension)
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
local sessionLuck

local container

local hatchCooldowns: { [Player]: number } = {}

function HatchService:GrantEgg(player: Player, tier: string, source: string, ascendChance: number?)
	local profile = saveService:GetProfile(player)
	if not profile then
		return
	end
	local egg = {
		Id = HttpService:GenerateGUID(false),
		Tier = tier,
		Timestamp = os.time(),
		Source = source,
		AscendChance = ascendChance,
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
		Rarity = roll.Rarity,
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

local function EquippedRelicTier(profile): string?
	local highest = nil
	for _, creature in profile.Data.Creatures do
		for _, item in creature.Equipment or {} do
			if item.Type == "Relic" and (highest == nil or item.Tier > highest) then
				highest = item.Tier
			end
		end
	end
	return if highest ~= nil then `T{highest}` else nil
end

function HatchService:Init(cont)
	container = cont
	log = cont:Get("Log")
	essenceService = cont:Get("EssenceService")
	saveService = cont:Get("SaveService")
	indexService = cont:Get("IndexService")
	questService = cont:Get("QuestService")
	sessionLuck = cont:Get("SessionLuck")
end

function HatchService:HatchEggById(player: Player, eggId: string, worldHatch: boolean?): boolean
	local profile = saveService:GetProfile(player)
	if not profile then
		return false
	end

	local eggIndex = nil
	for i, egg in profile.Data.Eggs do
		if egg.Id == eggId then
			eggIndex = i
			break
		end
	end
	if not eggIndex then
		return false
	end

	if not profile.Data.Entitlements.AutoHatch then
		local lastHatch = hatchCooldowns[player] or 0
		if os.clock() - lastHatch < Config.HATCH_COOLDOWN then
			return false
		end
		hatchCooldowns[player] = os.clock()
	end

	local bonusSlots = if profile.Data.Entitlements.MoreSlots then 2 else 0
	local maxCreatures = Sanctuary.MaxCreatures(profile.Data.SanctuaryLevel, bonusSlots)
	if #profile.Data.Creatures >= maxCreatures then
		log:Economy("Hatch", "CapReached", {
			Player = player.Name,
			Creatures = #profile.Data.Creatures,
			MaxCreatures = maxCreatures,
		})
		return false
	end

	local egg = table.remove(profile.Data.Eggs, eggIndex)
	local luck = sessionLuck.For(player)
	local rarityWeights = nil
	if profile.Data.Stats.TotalHatched == 0 and egg.Tier == "CommonEgg" then
		rarityWeights = Config.FIRST_HATCH_WEIGHTS
	end
	local roll = Gameplay.RollEgg(egg.Tier, CollarBonus(profile) + luck, rarityWeights)
	if egg.AscendChance then
		roll.Rarity = Ascension.RollFrom(roll.Rarity, luck, egg.AscendChance)
	end
	if
		Ascension.SecretTrigger(egg.Tier, Workspace:GetAttribute("EclipseActive") == true, EquippedRelicTier(profile))
	then
		roll.Rarity = "Secret"
	end
	local creature = Gameplay.CreateCreature(roll.Rarity, roll.SpeciesId, roll.Mutation)

	table.insert(profile.Data.Creatures, creature)
	profile.Data.Stats.TotalHatched += 1
	profile.Data.LastPlayed = os.time()
	indexService:Register(player, roll.SpeciesId, roll.Rarity, roll.Mutation)

	local species = Species[roll.SpeciesId]
	local mutationName = roll.Mutation ~= false and Mutations[roll.Mutation].Name or nil
	local announced = Gameplay.RarityRank(roll.Rarity) >= Gameplay.RarityRank(Config.ANNOUNCE_MIN_RARITY)
	questService:OnHatch(player, roll.Mutation ~= false)
	local seasonService = container:Get("SeasonService")
	if seasonService then
		seasonService:OnHatch(player)
	end

	Net.HatchResult:FireClient(player, {
		EggId = eggId,
		Creature = creature,
		SpeciesName = species.Name,
		RarityName = Rarities[roll.Rarity].Name,
		RarityColor = Rarities[roll.Rarity].Color,
		MutationName = mutationName,
		Announced = announced,
		WorldHatch = worldHatch or nil,
	})

	log:Economy("Hatch", "Success", {
		Player = player.Name,
		Tier = egg.Tier,
		Species = roll.SpeciesId,
		Rarity = roll.Rarity,
		Mutation = tostring(roll.Mutation),
		CreatureId = creature.Id,
		WorldHatch = worldHatch or nil,
	})

	Announce(player, roll)
	return true
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
		self:HatchEggById(player, eggId)
	end)
end

return HatchService
