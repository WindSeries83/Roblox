local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Evolution = require(ReplicatedStorage.Shared.Evolution)
local Index = require(ReplicatedStorage.Shared.Index)
local Rebirth = require(ReplicatedStorage.Shared.Rebirth)
local Sanctuary = require(ReplicatedStorage.Shared.Sanctuary)
local Species = require(ReplicatedStorage.Shared.Data.Species)
local Rarities = require(ReplicatedStorage.Shared.Data.Rarities)
local Mutations = require(ReplicatedStorage.Shared.Data.Mutations)
local Stages = require(ReplicatedStorage.Shared.Data.Stages)

local EconomySim = {}

local SIM_TICK = 1
local MAX_SIM_SECONDS = 7 * 24 * 3600

local function NewProfile(thresholds)
	return {
		Essence = Config.STARTER_ESSENCE,
		TotalEarned = 0,
		Creatures = {},
		Eggs = {},
		Index = {},
		Stars = 0,
		Rebirths = 0,
		SanctuaryLevel = 1,
		Thresholds = thresholds,
	}
end

local function GetRate(profile)
	local rate = 0
	for _, creature in profile.Creatures do
		local species = Species[creature.SpeciesId]
		local rarity = Rarities[creature.Rarity]
		local mutation = creature.Mutation ~= false and Mutations[creature.Mutation] or nil
		if species and rarity then
			rate += species.BaseRate * Config.ESSENCE_BASE_RATE * rarity.EssenceMult * (mutation and mutation.Multiplier or 1) * Evolution.RateMultFor(
				creature.Stage
			)
		end
	end
	local sanctuaryMult = 1 + Config.SANCTUARY_LEVEL_BONUS * (profile.SanctuaryLevel - 1)
	local indexMult = Index.ComputeMult(profile.Index)
	local starMult = Rebirth.StarEssenceMult(profile.Stars)
	return rate * sanctuaryMult * indexMult * starMult
end

local function DoRift(profile)
	local rate = GetRate(profile)
	local reward =
		math.max(Config.RIFT_MIN_REWARD, math.floor(rate * Config.RIFT_REWARD_SECONDS * Config.RIFT_ESSENCE_MULT))
	profile.Essence += reward
	profile.TotalEarned += reward
	local eggTier = Gameplay.WeightedRoll(Config.RIFT_EGG_WEIGHTS)
	table.insert(profile.Eggs, { Tier = eggTier })
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

local function BuyAndHatch(profile, tier)
	local price = Config.EGG_PRICES[tier]
	if profile.Essence < price then
		return false
	end
	if #profile.Creatures >= Sanctuary.MaxCreatures(profile.SanctuaryLevel) then
		return false
	end
	profile.Essence -= price
	local roll = Gameplay.RollEgg(tier)
	local creature = {
		Id = tostring(os.clock()),
		SpeciesId = roll.SpeciesId,
		Rarity = roll.Rarity,
		Mutation = roll.Mutation,
		Level = 1,
		XP = 0,
		Stage = 1,
		Power = 0,
		Equipment = {},
		Parents = {},
		Generation = 1,
	}
	creature.Power = Evolution.ComputePower(creature)
	table.insert(profile.Creatures, creature)
	Index.Register(profile.Index, roll.SpeciesId, roll.Rarity, roll.Mutation)
	return true
end

local function TryUpgrade(profile)
	if #profile.Creatures < Sanctuary.MaxCreatures(profile.SanctuaryLevel) then
		return false
	end
	local cost = Sanctuary.UpgradeCost(profile.SanctuaryLevel)
	if profile.Essence < cost then
		return false
	end
	profile.Essence -= cost
	profile.SanctuaryLevel += 1
	return true
end

local function TryEvolve(profile, creature)
	if not Evolution.CanEvolve(creature, profile.Essence) then
		return false
	end
	local cost = Evolution.EvolveCost(creature)
	profile.Essence -= cost
	if Stages[creature.Stage + 1].RequiresRelic then
		for i, item in creature.Equipment do
			if item.Type == "Relic" then
				table.remove(creature.Equipment, i)
				break
			end
		end
	end
	creature.Stage += 1
	creature.Power = Evolution.ComputePower(creature)
	return true
end

local function TryRebirth(profile, keepCreature)
	local threshold = profile.Thresholds[profile.Stars + 1]
	if not threshold or profile.TotalEarned < threshold then
		return false
	end
	profile.Creatures = keepCreature and Rebirth.KeepBestCreature(profile.Creatures) or {}
	profile.Eggs = {}
	profile.SanctuaryLevel = 1
	profile.Stars += 1
	profile.Rebirths += 1
	profile.Essence = Config.STARTER_ESSENCE
	return true
end

local function Simulate(strategy: string, options)
	options = options or {}
	local keepCreature = options.keepCreature ~= false
	local thresholds = options.thresholds or Config.REBIRTH_THRESHOLDS

	local profile = NewProfile(thresholds)
	local time = 0
	local nextRift = Config.RIFT_INTERVAL
	local riftActiveUntil = 0
	local riftDone = false
	local milestones = {}
	local stats = { Hatched = 0, Rifts = 0, Evolutions = 0, Upgrades = 0 }

	while time < MAX_SIM_SECONDS do
		time += SIM_TICK

		-- ponytail: yield périodique pour ne pas geler le DataModel pendant la sim
		if time % 60000 == 0 then
			task.wait()
		end

		local rate = GetRate(profile)
		profile.Essence += rate
		profile.TotalEarned += rate

		for _, creature in profile.Creatures do
			Evolution.AddXP(creature, Config.CREATURE_XP_PER_SECOND)
		end

		if time >= nextRift then
			riftActiveUntil = time + Config.RIFT_ACTIVE_SECONDS
			nextRift = time + Config.RIFT_INTERVAL
			riftDone = false
		end
		if time < riftActiveUntil and not riftDone then
			DoRift(profile)
			riftDone = true
			stats.Rifts += 1
		end

		local tier = nil
		if strategy == "progression" then
			if profile.Essence >= Config.EGG_PRICES.RareEgg then
				tier = "RareEgg"
			elseif profile.Essence >= Config.EGG_PRICES.UncommonEgg then
				tier = "UncommonEgg"
			elseif profile.Essence >= Config.EGG_PRICES.CommonEgg then
				tier = "CommonEgg"
			end
		elseif strategy == "common" then
			tier = "CommonEgg"
		end
		if tier and BuyAndHatch(profile, tier) then
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

		if TryRebirth(profile, keepCreature) then
			table.insert(milestones, { Rebirth = profile.Rebirths, At = time })
		end
	end

	return {
		Time = time,
		Rebirths = profile.Rebirths,
		Stars = profile.Stars,
		Milestones = milestones,
		Rate = GetRate(profile),
		Creatures = #profile.Creatures,
		SanctuaryLevel = profile.SanctuaryLevel,
		Stats = stats,
	}
end

local function HumanTime(seconds)
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	return string.format("%dh%02dm", h, m)
end

function EconomySim.Run(strategy: string?, options)
	strategy = strategy or "progression"
	local runs = options and options.runs or 3
	local best = nil
	local runsOut = {}
	for _ = 1, runs do
		local r = Simulate(strategy, options)
		table.insert(runsOut, r)
		if not best or r.Rebirths > best.Rebirths then
			best = r
		end
	end

	local avgRebirths = 0
	local milestones = {}
	for _, r in runsOut do
		avgRebirths += r.Rebirths
		for _, m in r.Milestones do
			if not milestones[m.Rebirth] or m.At < milestones[m.Rebirth] then
				milestones[m.Rebirth] = m.At
			end
		end
	end

	local out = {
		Strategy = strategy,
		Runs = #runsOut,
		AvgRebirths7j = math.floor(avgRebirths / #runsOut),
		BestRebirths7j = best and best.Rebirths or 0,
		RateApres7j = best and math.floor(best.Rate * 100) / 100 or 0,
		CreaturesApres7j = best and best.Creatures or 0,
		SanctuaryLevel = best and best.SanctuaryLevel or 1,
		Stats = best and best.Stats or {},
		Milestones = {},
	}
	for rebirth, at in milestones do
		out.Milestones[rebirth] = { At = at, Human = HumanTime(at) }
	end

	return out
end

return EconomySim
