local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Evolution = require(ReplicatedStorage.Shared.Evolution)
local Index = require(ReplicatedStorage.Shared.Index)
local Rebirth = require(ReplicatedStorage.Shared.Rebirth)
local Sanctuary = require(ReplicatedStorage.Shared.Sanctuary)
local SkillTree = require(ReplicatedStorage.Shared.SkillTree)
local Pack = require(ReplicatedStorage.Shared.Pack)
local Stages = require(ReplicatedStorage.Shared.Data.Stages)

local EconomySim = {}

local SECONDS_PER_DAY = 24 * 60 * 60
local DEFAULT_DURATION_DAYS = 7
local MAX_DURATION_DAYS = 30
local ACTIVE_STEP_SECONDS = 60

local PROFILE_DEFINITIONS = {
	afk = { Active = false, InitialHatch = true, Paid = false },
	attentive = { Active = true, InitialHatch = true, Paid = false },
	moderate_payer = {
		Active = true,
		InitialHatch = true,
		Paid = true,
		-- Simulation-only basket; it has no SKU, price, date, or live activation.
		SimulatedBasket = { PassiveBoost = true, LuckBonus = Config.VIP_LUCK_BONUS },
	},
	-- Legacy profiles remain callable for existing internal tooling.
	starter = { Active = true, InitialHatch = false, Paid = true },
	meute = { Active = true, InitialHatch = true, Paid = false },
	whale = { Active = true, InitialHatch = false, Paid = true },
}

local PROFILE_ALIASES = {
	f2p = "attentive",
	attentif = "attentive",
	active = "attentive",
	moderate = "moderate_payer",
	moderatepayer = "moderate_payer",
	payeur = "moderate_payer",
	payeur_modere = "moderate_payer",
}

local PROFILE_LUCK = {
	afk = 0,
	attentive = 0,
	moderate_payer = 0,
	meute = 0,
	starter = 0.35,
	whale = 0.75,
}

local function CopyMap(source)
	return table.clone(source)
end

local function Increment(map, key, amount)
	map[key] = (map[key] or 0) + (amount or 1)
end

local function ResolveProfileKind(kind)
	kind = string.lower(kind or "attentive")
	kind = PROFILE_ALIASES[kind] or kind
	assert(PROFILE_DEFINITIONS[kind], `profil EconomySim inconnu: {kind}`)
	return kind
end

local function ResolveDuration(options)
	options = options or {}
	if options.durationSeconds ~= nil then
		assert(type(options.durationSeconds) == "number", "durationSeconds doit être un nombre")
		assert(
			options.durationSeconds > 0 and options.durationSeconds <= MAX_DURATION_DAYS * SECONDS_PER_DAY,
			"durationSeconds doit être compris entre 1 seconde et 30 jours"
		)
		return options.durationSeconds, options.durationSeconds / SECONDS_PER_DAY
	end

	local days = options.durationDays or options.days or options.duration or DEFAULT_DURATION_DAYS
	assert(type(days) == "number" and days % 1 == 0, "durationDays doit être un nombre entier")
	assert(days >= 1 and days <= MAX_DURATION_DAYS, "durationDays doit être compris entre 1 et 30")
	return days * SECONDS_PER_DAY, days
end

local function NewProfile(thresholds)
	return {
		Essence = Config.STARTER_ESSENCE,
		InitialEssence = Config.STARTER_ESSENCE,
		EssenceEarned = 0,
		EssenceSpent = 0,
		TotalEarned = 0,
		Creatures = {},
		Eggs = {},
		EggsPurchased = {},
		EggsGranted = {},
		Index = {},
		Stars = 0,
		Rebirths = 0,
		SkillPoints = 0,
		SkillRanks = {},
		SanctuaryLevel = 1,
		WorldStageWins = 0,
		Thresholds = thresholds,
	}
end

local function AddEssence(profile, amount)
	profile.Essence += amount
	profile.EssenceEarned += amount
	profile.TotalEarned += amount
end

local function SpendEssence(profile, amount)
	profile.Essence -= amount
	profile.EssenceSpent += amount
end

local function GetRate(profile, includePaid)
	local rate = Gameplay.ComputeRate(profile.Creatures)
	local sanctuaryMult = 1 + Config.SANCTUARY_LEVEL_BONUS * (profile.SanctuaryLevel - 1)
	local indexMult = Index.ComputeMult(profile.Index)
	local starMult = Rebirth.StarEssenceMult(profile.Stars)
	rate = rate * sanctuaryMult * indexMult * starMult * (1 + SkillTree.Effects(profile.SkillRanks).EssenceRate)
	if profile.PackFriends then
		rate *= Pack.Mult(profile.PackFriends)
	end
	if includePaid ~= false and profile.Entitlements and profile.Entitlements.PassiveBoost then
		rate *= Config.PASSIVE_BOOST_MULT
	end
	return rate
end

local function DoRift(profile)
	local effects = SkillTree.Effects(profile.SkillRanks)
	local rate = GetRate(profile)
	local reward = math.max(
		Config.RIFT_MIN_REWARD,
		math.floor(rate * Config.RIFT_REWARD_SECONDS * Config.RIFT_ESSENCE_MULT * (1 + effects.RiftRewardMult))
	)
	AddEssence(profile, reward)
	profile.WorldStageWins += 1

	local eggTier = Sanctuary.ResolveEggTier(Gameplay.WeightedRoll(Config.RIFT_EGG_WEIGHTS), profile.SanctuaryLevel)
	table.insert(profile.Eggs, { Tier = eggTier })
	Increment(profile.EggsGranted, eggTier)

	local relicRoll = Gameplay.WeightedRoll(Config.RIFT_RELIC_WEIGHTS)
	if relicRoll and relicRoll ~= "None" then
		local tier = tonumber(relicRoll:sub(2))
		if tier then
			local target = profile.Creatures[1]
			if target then
				table.insert(target.Equipment, { Type = "Relic", Tier = tier })
			end
		end
	end
	return reward
end

local function BonusSlots(profile)
	if profile.Entitlements and profile.Entitlements.MoreSlots then
		return Config.GAMEPASSES.MoreSlots.BonusSlots
	end
	return 0
end

local function BuyAndHatch(profile, tier, hatchLuck)
	local price = Config.EGG_PRICES[tier]
	if not price or profile.Essence < price then
		return false
	end
	if #profile.Creatures >= Sanctuary.MaxCreatures(profile.SanctuaryLevel, BonusSlots(profile)) then
		return false
	end
	SpendEssence(profile, price)
	local roll = Gameplay.RollEgg(tier, hatchLuck)
	local creature = Gameplay.CreateCreature(roll.Rarity, roll.SpeciesId, roll.Mutation)
	table.insert(profile.Creatures, creature)
	Index.Register(profile.Index, roll.SpeciesId, roll.Rarity, roll.Mutation)
	Increment(profile.EggsPurchased, tier)
	return true
end

local function TryUpgrade(profile)
	if #profile.Creatures < Sanctuary.MaxCreatures(profile.SanctuaryLevel, BonusSlots(profile)) then
		return false
	end
	local effects = SkillTree.Effects(profile.SkillRanks)
	local cost = math.floor(Sanctuary.UpgradeCost(profile.SanctuaryLevel) * (1 - effects.UpgradeCostReduction))
	if profile.Essence < cost then
		return false
	end
	SpendEssence(profile, cost)
	profile.SanctuaryLevel += 1
	return true
end

local function TryEvolve(profile, creature)
	if not Evolution.CanEvolve(creature, profile.Essence) then
		return false
	end
	local cost = Evolution.EvolveCost(creature)
	SpendEssence(profile, cost)
	local nextStage = Stages[creature.Stage + 1]
	if nextStage and nextStage.RequiresRelic then
		Evolution.ConsumeRelic(creature)
	end
	creature.Stage += 1
	creature.Power = Evolution.ComputePower(creature)
	return true
end

local function TryRebirth(profile)
	local threshold = profile.Thresholds[profile.Stars + 1]
	if not threshold or profile.TotalEarned < threshold or profile.WorldStageWins < 6 then
		return false
	end
	-- Renaissance : conservation totale des créatures et de l'équipement.
	profile.Eggs = {}
	profile.SanctuaryLevel = 1
	profile.Stars += 1
	profile.Rebirths += 1
	profile.SkillPoints += 1
	profile.Essence = Config.STARTER_ESSENCE
	profile.WorldStageWins = 0
	return true
end

local NODE_PRIORITY = { "FarmRate1", "RiftReward", "MarketFeeCut", "FarmLuck", "MutOmen" }

local function TryBuyNode(profile)
	for _, id in NODE_PRIORITY do
		if SkillTree.CanBuy(profile.SkillPoints, profile.SkillRanks, id) then
			profile.SkillPoints = SkillTree.Buy(profile.SkillPoints, profile.SkillRanks, id)
			return true
		end
	end
	return false
end

local function EffectiveHatchLuck(profile, baseLuck)
	local skillLuck = SkillTree.Effects(profile.SkillRanks).HatchLuck
	return math.clamp(baseLuck + skillLuck, 0, Config.LUCK_HARD_CAP), skillLuck
end

local function BaseLuckForProfile(kind)
	local definition = PROFILE_DEFINITIONS[kind]
	if definition.Paid and definition.SimulatedBasket then
		return definition.SimulatedBasket.LuckBonus
	end
	return PROFILE_LUCK[kind] or 0
end

local function ApplyProfile(profile, kind)
	if kind == "meute" then
		profile.PackFriends = Config.PACK_MAX_FRIENDS
	end

	local definition = PROFILE_DEFINITIONS[kind]
	if definition.Paid and definition.SimulatedBasket then
		profile.Entitlements = {
			PassiveBoost = definition.SimulatedBasket.PassiveBoost,
		}
	end
	if definition.InitialHatch then
		local luck = BaseLuckForProfile(kind)
		BuyAndHatch(profile, "CommonEgg", luck)
	end

	if kind == "starter" or kind == "whale" then
		local creature = Gameplay.CreateCreature("Rare", "CinderSeraph", "Shadow")
		table.insert(profile.Creatures, creature)
		Index.Register(profile.Index, "CinderSeraph", "Rare", "Shadow")
		profile.Essence += 1000
		profile.InitialEssence += 1000
	end
	if kind == "whale" then
		profile.Entitlements = { MoreSlots = true, PassiveBoost = true }
	end
	return profile
end

local function ChooseEgg(profile, strategy)
	if strategy == "common" then
		return "CommonEgg"
	end
	if strategy ~= "progression" then
		return nil
	end

	local gate = Sanctuary.EggGate(profile.SanctuaryLevel)
	for _, candidate in { "LegendaryEgg", "EpicEgg", "RareEgg", "UncommonEgg", "CommonEgg" } do
		if
			profile.Essence >= (Config.EGG_PRICES[candidate] or math.huge)
			and not (gate[candidate] and profile.SanctuaryLevel < gate[candidate])
		then
			return candidate
		end
	end
	return nil
end

local function PerformActiveStep(profile, strategy, baseLuck, stats)
	if TryBuyNode(profile) then
		stats.SkillNodes += 1
	end

	local tier = ChooseEgg(profile, strategy)
	local hatchLuck = EffectiveHatchLuck(profile, baseLuck)
	if tier and BuyAndHatch(profile, tier, hatchLuck) then
		stats.Hatched += 1
	end

	if TryUpgrade(profile) then
		stats.Upgrades += 1
	end

	for _, creature in profile.Creatures do
		if TryEvolve(profile, creature) then
			stats.Evolutions += 1
		end
	end
end

local function Accrue(profile, elapsed)
	if elapsed <= 0 then
		return
	end
	local rate = GetRate(profile)
	AddEssence(profile, rate * elapsed)
	for _, creature in profile.Creatures do
		Evolution.AddXP(creature, Config.CREATURE_XP_PER_SECOND * elapsed)
	end
end

local function HighestUnlockedEgg(sanctuaryLevel)
	local highest = Sanctuary.EGG_TIERS[1]
	for _, tier in Sanctuary.EGG_TIERS do
		if not Sanctuary.EggLocked(tier, sanctuaryLevel) then
			highest = tier
		end
	end
	return highest
end

local function Simulate(strategy, options)
	options = options or {}
	local durationSeconds, durationDays = ResolveDuration(options)
	local thresholds = options.thresholds or Config.REBIRTH_THRESHOLDS
	local kind = ResolveProfileKind(options.profileKind)
	local baseLuck = BaseLuckForProfile(kind)
	local definition = PROFILE_DEFINITIONS[kind]
	local profile = ApplyProfile(NewProfile(thresholds), kind)
	local time = 0
	local nextAction = ACTIVE_STEP_SECONDS
	local nextRift = Config.FIRST_RIFT_DELAY or Config.RIFT_INTERVAL
	local milestones = {}
	local stats = {
		Hatched = 0,
		Rifts = 0,
		Evolutions = 0,
		Upgrades = 0,
		SkillNodes = 0,
	}

	while time < durationSeconds do
		local nextEvent = durationSeconds
		if definition.Active then
			nextEvent = math.min(nextEvent, nextAction, nextRift)
		end
		Accrue(profile, nextEvent - time)
		time = nextEvent

		if definition.Active and time >= nextRift then
			while nextRift <= time do
				DoRift(profile)
				stats.Rifts += 1
				nextRift += Config.RIFT_INTERVAL
			end
		end
		if definition.Active and time >= nextAction then
			while nextAction <= time do
				PerformActiveStep(profile, strategy, baseLuck, stats)
				nextAction += ACTIVE_STEP_SECONDS
			end
		end
		if TryRebirth(profile) then
			table.insert(milestones, { Rebirth = profile.Rebirths, At = time })
		end
	end

	local effectiveLuck, skillLuck = EffectiveHatchLuck(profile, baseLuck)
	local rate = GetRate(profile)
	local rateWithoutPaid = GetRate(profile, false)
	local isNonPayer = kind == "afk" or kind == "attentive" or kind == "meute"
	local paidBasket = if definition.Paid and definition.SimulatedBasket
		then {
			Modeled = true,
			SimulationOnly = true,
			LiveActivation = false,
			Items = {
				PassiveBoost = {
					Applied = definition.SimulatedBasket.PassiveBoost,
					Multiplier = Config.PASSIVE_BOOST_MULT,
				},
				VipLuck = {
					Applied = true,
					Bonus = definition.SimulatedBasket.LuckBonus,
					Cap = Config.LUCK_HARD_CAP,
				},
			},
			EssenceRateBefore = rateWithoutPaid,
			EssenceRateAfter = rate,
			EssenceRateMultiplier = if rateWithoutPaid > 0 then rate / rateWithoutPaid else 1,
		}
		else {
			Modeled = false,
			EssenceRateMultiplier = 1,
			Reason = "Aucun panier payeur n'est appliqué à ce profil.",
		}
	local flow = {
		Initial = profile.InitialEssence,
		Earned = profile.EssenceEarned,
		Spent = profile.EssenceSpent,
		Ending = profile.Essence,
		NetEarned = profile.EssenceEarned - profile.EssenceSpent,
	}
	local metrics = {
		Inflation = {
			Modeled = false,
			Reason = "Le simulateur est mono-joueur et ne modélise ni masse monétaire globale ni évolution des prix.",
			ObservedEssenceFlow = flow,
		},
		RebirthSpeed = {
			Modeled = true,
			Rebirths = profile.Rebirths,
			FirstRebirthSeconds = milestones[1] and milestones[1].At or nil,
			Milestones = milestones,
		},
		EggAvailability = {
			Modeled = true,
			PurchasedByTier = CopyMap(profile.EggsPurchased),
			GrantedByTier = CopyMap(profile.EggsGranted),
			HighestUnlockedTier = HighestUnlockedEgg(profile.SanctuaryLevel),
			SanctuaryLevel = profile.SanctuaryLevel,
		},
		NonPayerProgression = {
			Modeled = isNonPayer,
			Profile = kind,
			Rebirths = profile.Rebirths,
			Stars = profile.Stars,
			Reason = if isNonPayer
				then nil
				else "Ce profil contient une dépense payeur, mais ses avantages ne sont pas activés sans validation humaine.",
		},
		LuckCap = {
			Modeled = true,
			BaseBonus = baseLuck,
			SkillBonus = skillLuck,
			EffectiveBonus = effectiveLuck,
			Cap = Config.LUCK_HARD_CAP,
			CapReached = effectiveLuck >= Config.LUCK_HARD_CAP,
		},
		OfflineYield = {
			Modeled = false,
			Reason = "Aucune reconnexion ni fenêtre hors-ligne n'est simulée.",
		},
		MarketValue = {
			Modeled = false,
			Reason = "Aucun carnet, échange ou estimation de valeur de marché n'est simulé.",
		},
		PaidConversion = {
			Modeled = false,
			Reason = "Les IDs, prix et offres non validés restent désactivés.",
		},
		PaidBasket = paidBasket,
	}

	return {
		Time = time,
		DurationDays = durationDays,
		DurationSeconds = durationSeconds,
		Profile = kind,
		Rebirths = profile.Rebirths,
		Stars = profile.Stars,
		Milestones = milestones,
		Rate = rate,
		Creatures = #profile.Creatures,
		SanctuaryLevel = profile.SanctuaryLevel,
		Stats = stats,
		Essence = flow,
		Eggs = {
			PurchasedByTier = CopyMap(profile.EggsPurchased),
			GrantedByTier = CopyMap(profile.EggsGranted),
		},
		Metrics = metrics,
	}
end

local function HumanTime(seconds)
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	return string.format("%dh%02dm", h, m)
end

local function CopyOptions(options)
	return table.clone(options or {})
end

function EconomySim.Run(strategy: string?, options)
	strategy = strategy or "progression"
	options = options or {}
	local durationSeconds, durationDays = ResolveDuration(options)
	local runs = options.runs or 3
	assert(type(runs) == "number" and runs >= 1 and runs % 1 == 0, "runs doit être un entier positif")
	local kind = ResolveProfileKind(options.profileKind)
	local runsOut = {}
	local best = nil
	for _ = 1, runs do
		local runOptions = CopyOptions(options)
		runOptions.profileKind = kind
		runOptions.durationSeconds = durationSeconds
		local result = Simulate(strategy, runOptions)
		table.insert(runsOut, result)
		if
			not best
			or result.Rebirths > best.Rebirths
			or (result.Rebirths == best.Rebirths and result.Rate > best.Rate)
		then
			best = result
		end
	end

	local avgRebirths = 0
	local avgRate = 0
	local milestones = {}
	for _, result in runsOut do
		avgRebirths += result.Rebirths
		avgRate += result.Rate
		for _, milestone in result.Milestones do
			if not milestones[milestone.Rebirth] or milestone.At < milestones[milestone.Rebirth] then
				milestones[milestone.Rebirth] = milestone.At
			end
		end
	end
	avgRebirths /= #runsOut
	avgRate /= #runsOut

	local aggregateMilestones = {}
	for rebirth, at in milestones do
		aggregateMilestones[rebirth] = { At = at, Human = HumanTime(at) }
	end
	local representative = best or runsOut[1]
	local representativeMetrics = representative.Metrics
	return {
		Strategy = strategy,
		Profile = kind,
		Runs = #runsOut,
		DurationDays = durationDays,
		DurationSeconds = durationSeconds,
		Results = runsOut,
		Representative = representative,
		AvgRebirths = avgRebirths,
		BestRebirths = representative.Rebirths,
		AvgRateAfter = math.floor(avgRate * 100) / 100,
		RateAfter = math.floor(representative.Rate * 100) / 100,
		CreaturesAfter = representative.Creatures,
		SanctuaryLevel = representative.SanctuaryLevel,
		Stats = representative.Stats,
		Milestones = aggregateMilestones,
		-- Legacy 7-day fields stay available but are empty for another duration.
		AvgRebirths7j = if durationDays == 7 then math.floor(avgRebirths) else nil,
		BestRebirths7j = if durationDays == 7 then representative.Rebirths else nil,
		RateApres7j = if durationDays == 7 then math.floor(representative.Rate * 100) / 100 else nil,
		CreaturesApres7j = if durationDays == 7 then representative.Creatures else nil,
		Metrics = {
			Inflation = representativeMetrics.Inflation,
			RebirthSpeed = {
				Modeled = true,
				AverageRebirths = avgRebirths,
				BestRebirths = representative.Rebirths,
				FirstRebirthSeconds = representativeMetrics.RebirthSpeed.FirstRebirthSeconds,
			},
			EggAvailability = representativeMetrics.EggAvailability,
			NonPayerProgression = representativeMetrics.NonPayerProgression,
			LuckCap = representativeMetrics.LuckCap,
			OfflineYield = representativeMetrics.OfflineYield,
			MarketValue = representativeMetrics.MarketValue,
			PaidConversion = representativeMetrics.PaidConversion,
			PaidBasket = representativeMetrics.PaidBasket,
		},
	}
end

function EconomySim.RunMatrix(strategy: string?, options)
	options = options or {}
	local profiles = options.profiles or { "afk", "attentive", "moderate_payer" }
	local durations = options.durations or { 1, 7, 14, 30 }
	local results = {}
	for _, profileKind in profiles do
		local canonical = ResolveProfileKind(profileKind)
		results[canonical] = {}
		for _, durationDays in durations do
			local runOptions = CopyOptions(options)
			runOptions.profileKind = canonical
			runOptions.durationDays = durationDays
			runOptions.durationSeconds = nil
			results[canonical][durationDays] = EconomySim.Run(strategy, runOptions)
		end
	end
	return {
		Strategy = strategy or "progression",
		Profiles = profiles,
		Durations = durations,
		Results = results,
		NonPayerProgression = results.attentive,
	}
end

return EconomySim
