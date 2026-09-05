--!strict

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
local Luck = require(ReplicatedStorage.Shared.Luck)
local Sanctuary = require(ReplicatedStorage.Shared.Sanctuary)
local Vip = require(ReplicatedStorage.Shared.Vip)
local Net = require(ReplicatedStorage.Shared.Net)
local RotatingEgg = require(ReplicatedStorage.Shared.RotatingEgg)
local Probability = require(ReplicatedStorage.Shared.Probability)

local HatchService = {}

local log
local essenceService
local saveService
local indexService
local questService
local sessionLuck
local luckService
local analyticsService
local skillService
local tickerService
local eclipseService
local incubationService
local dataSync
local secretGate
local recognitionService

local container

function HatchService:GrantEgg(
	player: Player,
	tier: string,
	source: string,
	ascendChance: number?,
	rotatingEggId: string?
)
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
		RotatingEggId = rotatingEggId,
	}
	table.insert(profile.Data.Eggs, egg)
	profile.Data.LastPlayed = os.time()
	analyticsService:Funnel(profile, "FirstEggAt", player)
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
	if tickerService then
		tickerService:Publish(payload)
	end
	analyticsService:Event("rare_drop", {
		Rarity = roll.Rarity,
		Mutation = tostring(roll.Mutation),
		World = "Sanctuary",
	}, player)
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
	luckService = cont:Get("LuckService")
	skillService = cont:Get("SkillService")
	analyticsService = cont:Get("AnalyticsService")
	incubationService = cont:Get("IncubationService")
	secretGate = cont:Get("SecretGate")
	recognitionService = cont:Get("RecognitionService")
end

function HatchService:ContextFor(player: Player, egg): any?
	local profile = saveService:GetProfile(player)
	if not profile then
		return nil
	end
	local eff = skillService:EffectsOf(profile)
	local luck = Luck.Combine(
		sessionLuck.For(player),
		luckService:PotionBonus(player),
		eff.HatchLuck,
		if Vip.IsActive(profile.Data.VipExpiresAt, os.time()) then Config.VIP_LUCK_BONUS else 0
	)
	return Probability.Build({
		tier = egg.Tier,
		totalHatched = profile.Data.Stats.TotalHatched,
		hatchesSinceRare = profile.Data.Stats.HatchesSinceRare or 0,
		luck = luck,
		ascendChance = egg.AscendChance,
		mutationBonus = CollarBonus(profile) + luck + eff.MutationBonus + eclipseService:MutationBonus(),
	})
end

function HatchService:Reserve(player: Player, egg): ({ [string]: any }?, string?)
	local profile = saveService:GetProfile(player)
	if not profile then
		return nil, "Sauvegarde indisponible"
	end
	local eff = skillService:EffectsOf(profile)
	local context = self:ContextFor(player, egg)
	assert(context, "probability context unavailable")
	local rarityWeights = context.RarityWeights
	-- Bonus mutation de l'Éclipse ajouté APRÈS Luck.Combine : événement serveur, hors cap de chance achetable.
	local roll = Gameplay.RollEgg(egg.Tier, nil, rarityWeights)
	local mutationRoll = Gameplay.WeightedRoll(context.MutationWeights)
	roll.Mutation = if mutationRoll == "None" then false else mutationRoll
	-- Bride l'ascension : Mythique+ réservé aux œufs de la Faille.
	roll.Rarity = Ascension.ClampToSource(roll.Rarity, egg.Source or "Purchase")
	if
		secretGate.Triggered(
			egg.Tier,
			Workspace:GetAttribute("EclipseActive") == true,
			EquippedRelicTier(profile),
			eff.SecretOmen == true
		)
	then
		roll.Rarity = "Secret"
	end

	local rareRank = Gameplay.RarityRank("Rare")
	local hatchesSinceRare = profile.Data.Stats.HatchesSinceRare or 0
	if context.PityForced and Gameplay.RarityRank(roll.Rarity) < rareRank then
		roll = Gameplay.RollEgg(egg.Tier, nil, { Rare = 100 })
		local pityMutation = Gameplay.WeightedRoll(context.MutationWeights)
		roll.Mutation = if pityMutation == "None" then false else pityMutation
		log:Economy("Hatch", "PityTriggered", { Player = player.Name, SinceRare = hatchesSinceRare })
		analyticsService:Event(
			"pity_triggered",
			{ SinceRare = hatchesSinceRare, Threshold = Config.PITY_THRESHOLD },
			player
		)
	end
	if Gameplay.RarityRank(roll.Rarity) >= rareRank then
		profile.Data.Stats.HatchesSinceRare = 0
	else
		profile.Data.Stats.HatchesSinceRare = hatchesSinceRare + 1
	end
	local creature = Gameplay.CreateCreature(roll.Rarity, roll.SpeciesId, roll.Mutation)
	return {
		Species = roll.SpeciesId,
		Rarity = roll.Rarity,
		Mutation = if roll.Mutation == false then nil else roll.Mutation,
		Power = creature.Power,
	},
		nil
end

function HatchService:ClaimReserved(player: Player, record, worldHatch: boolean?): (boolean, string?)
	local profile = saveService:GetProfile(player)
	if not profile then
		return false, "Sauvegarde indisponible"
	end
	local reserved = record.ReservedHatch
	if not Species[reserved.Species] or not Rarities[reserved.Rarity] then
		return false, "Résultat d'incubation invalide"
	end
	local bonusSlots = if profile.Data.Entitlements.MoreSlots then Config.GAMEPASSES.MoreSlots.BonusSlots else 0
	local maxCreatures = Sanctuary.MaxCreatures(profile.Data.SanctuaryLevel, bonusSlots)
	if #profile.Data.Creatures >= maxCreatures then
		log:Economy("Hatch", "CapReached", {
			Player = player.Name,
			Creatures = #profile.Data.Creatures,
			MaxCreatures = maxCreatures,
		})
		return false, "Sanctuaire plein"
	end
	local mutation = reserved.Mutation or false
	local creature = Gameplay.CreateCreature(reserved.Rarity, reserved.Species, mutation)
	creature.Power = reserved.Power
	local previousTotalHatched = profile.Data.Stats.TotalHatched
	local previousLastPlayed = profile.Data.LastPlayed
	local creatureIndex = #profile.Data.Creatures + 1
	local materialized, materializeError = pcall(function()
		table.insert(profile.Data.Creatures, creature)
		profile.Data.Stats.TotalHatched += 1
		profile.Data.LastPlayed = os.time()
		indexService:Register(player, reserved.Species, reserved.Rarity, mutation)
	end)
	if not materialized then
		table.remove(profile.Data.Creatures, creatureIndex)
		profile.Data.Stats.TotalHatched = previousTotalHatched
		profile.Data.LastPlayed = previousLastPlayed
		return false, tostring(materializeError)
	end

	local species = Species[reserved.Species]
	local mutationName = reserved.Mutation and Mutations[reserved.Mutation].Name or nil
	if reserved.Rarity == "Secret" then
		task.spawn(function()
			recognitionService:RecordSecret(player, species.Name, creature.Id, mutationName)
		end)
	end
	local announced = Gameplay.RarityRank(reserved.Rarity) >= Gameplay.RarityRank(Config.ANNOUNCE_MIN_RARITY)
	questService:OnHatch(player, reserved.Mutation ~= nil, `{record.EggId}:{record.IncubatorId}`)
	container:Get("SeasonService"):OnHatch(player)

	Net.HatchResult:FireClient(player, {
		EggId = record.EggId,
		IncubatorId = record.IncubatorId,
		Creature = creature,
		SpeciesName = species.Name,
		Rarity = reserved.Rarity,
		RarityName = Rarities[reserved.Rarity].Name,
		RarityColor = Rarities[reserved.Rarity].Color,
		MutationName = mutationName,
		Announced = announced,
		WorldHatch = worldHatch or nil,
		PityProgress = profile.Data.Stats.HatchesSinceRare,
		PityMax = Config.PITY_THRESHOLD,
	})

	log:Economy("Hatch", "Success", {
		Player = player.Name,
		Tier = record.EggTier or "Incubation",
		Species = reserved.Species,
		Rarity = reserved.Rarity,
		Mutation = tostring(reserved.Mutation),
		CreatureId = creature.Id,
		WorldHatch = worldHatch or nil,
	})
	local rank = Gameplay.RarityRank(reserved.Rarity)
	local hatchProperties = {
		Rarity = reserved.Rarity,
		Mutation = tostring(reserved.Mutation),
		Source = record.EggTier or "Incubation",
		RotatingEggId = record.RotatingEggId,
	}
	analyticsService:Event("hatch", hatchProperties, player)
	if record.RotatingEggId then
		analyticsService:Event("rotating_egg_hatch", { Id = record.RotatingEggId, Tier = record.EggTier }, player)
	end
	analyticsService:Funnel(profile, "FirstHatchAt", player)
	local rareRank = Gameplay.RarityRank("Rare")
	if rank >= rareRank then
		analyticsService:Funnel(profile, "FirstRarePlusAt", player)
	end
	if rank >= Gameplay.RarityRank("Epic") then
		analyticsService:Funnel(profile, "FirstEpicPlusAt", player)
		profile.Data.Offers.FirstPurchaseEligible = true
	end

	Announce(player, {
		SpeciesId = reserved.Species,
		Rarity = reserved.Rarity,
		Mutation = mutation,
	})
	return true
end

function HatchService:Start()
	tickerService = container:Get("TickerService")
	eclipseService = container:Get("EclipseService")
	dataSync = container:Get("DataSync")
	Net.BuyEgg.OnServerEvent:Connect(function(player: Player, tier: string)
		if type(tier) ~= "string" then
			return
		end
		local purchaseTier = tier
		local rotatingEggId: string?
		if tier == "RotatingEgg" then
			local active = RotatingEgg.GetActive(os.time())
			if not active then
				return
			end
			purchaseTier = active.Tier
			rotatingEggId = active.Id
		end
		local price = Config.EGG_PRICES[purchaseTier]
		if not price then
			return
		end
		local profile = saveService:GetProfile(player)
		if profile then
			analyticsService:Funnel(profile, "FirstInteractionAt", player)
		end
		if profile and profile.Data.Entitlements.AutoHatch and #profile.Data.Incubators > 0 then
			Net.ActionResult:FireClient(player, { Action = "BuyEgg", Success = false, Reason = "Couveuse occupee" })
			return
		end
		local required = Sanctuary.EggLocked(purchaseTier, if profile then profile.Data.SanctuaryLevel else 1)
		if required then
			log:Economy("Eggs", "EggLocked", { Player = player.Name, Tier = purchaseTier, RequiredRank = required })
			return
		end
		local eff = if profile then skillService:EffectsOf(profile) else {}
		price = math.max(1, math.floor(price * (1 - (eff.EggPriceReduction or 0))))
		if not essenceService:Spend(player, price, `BuyEgg_{purchaseTier}`) then
			return
		end
		self:GrantEgg(player, purchaseTier, if rotatingEggId then "Rotating" else "Purchase", nil, rotatingEggId)
		if rotatingEggId then
			analyticsService:Event(
				"rotating_egg_purchase",
				{ Id = rotatingEggId, Tier = purchaseTier, Price = price },
				player
			)
		end
		if profile and profile.Data.Entitlements.AutoHatch then
			-- Éclosion auto : dernier œuf fraîchement accordé (Source="Purchase").
			for i = #profile.Data.Eggs, 1, -1 do
				local fresh = profile.Data.Eggs[i]
				if fresh.Source == "Purchase" or fresh.Source == "Rotating" then
					local ok = incubationService:AutoPlaceAndHatch(player, fresh.Id, tier)
					if not ok then
						for j = #profile.Data.Eggs, 1, -1 do
							if profile.Data.Eggs[j].Id == fresh.Id then
								table.remove(profile.Data.Eggs, j)
								profile.Data.Essence += price
								break
							end
						end
					end
					break
				end
			end
		end
		-- Feedback immédiat : l'œuf et la déduction d'essence apparaissent sans attendre le tick 1 s.
		dataSync:Send(player)
	end)
end

return HatchService
