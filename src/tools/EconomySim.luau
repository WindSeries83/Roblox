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
local GroupBonus = require(ReplicatedStorage.Shared.GroupBonus)

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
		SkillPoints = 0,
		SkillRanks = {},
		SanctuaryLevel = 1,
		Thresholds = thresholds,
		CurrentWorld = "World1",
	}
end

local function GetRate(profile)
	local rate = Gameplay.ComputeRate(profile.Creatures)
	local sanctuaryMult = 1 + Config.SANCTUARY_LEVEL_BONUS * (profile.SanctuaryLevel - 1)
	local indexMult = Index.ComputeMult(profile.Index)
	local starMult = Rebirth.StarEssenceMult(profile.Stars)
	local worldMult = Config.WORLDS[profile.CurrentWorld].EssenceMult
	rate = rate * sanctuaryMult * indexMult * starMult * (1 + SkillTree.Effects(profile.SkillRanks).EssenceRate)
	rate *= worldMult * GroupBonus.Mult(profile.GroupMember == true)
	if profile.PackFriends then
		rate *= Pack.Mult(profile.PackFriends)
	end
	if profile.Entitlements and profile.Entitlements.PassiveBoost then
		rate *= Config.PASSIVE_BOOST_MULT
	end
	return rate
end

local function DoRift(profile)
	local rate = GetRate(profile)
	local reward =
		math.max(Config.RIFT_MIN_REWARD, math.floor(rate * Config.RIFT_REWARD_SECONDS * Config.RIFT_ESSENCE_MULT))
	profile.Essence += reward
	profile.TotalEarned += reward
	local eggTier = Sanctuary.ResolveEggTier(Gameplay.WeightedRoll(Config.RIFT_EGG_WEIGHTS), profile.SanctuaryLevel)
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

local function BonusSlots(profile)
	if profile.Entitlements and profile.Entitlements.MoreSlots then
		return Config.GAMEPASSES.MoreSlots.BonusSlots
	end
	return 0
end

local function BuyAndHatch(profile, tier, hatchLuck)
	local price = Config.EGG_PRICES[tier]
	if profile.Essence < price then
		return false
	end
	if #profile.Creatures >= Sanctuary.MaxCreatures(profile.SanctuaryLevel, BonusSlots(profile)) then
		return false
	end
	profile.Essence -= price
	local roll = Gameplay.RollEgg(tier, hatchLuck)
	local creature = Gameplay.CreateCreature(roll.Rarity, roll.SpeciesId, roll.Mutation)
	table.insert(profile.Creatures, creature)
	Index.Register(profile.Index, roll.SpeciesId, roll.Rarity, roll.Mutation)
	return true
end

local function TryUpgrade(profile)
	if #profile.Creatures < Sanctuary.MaxCreatures(profile.SanctuaryLevel, BonusSlots(profile)) then
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
		Evolution.ConsumeRelic(creature)
	end
	creature.Stage += 1
	creature.Power = Evolution.ComputePower(creature)
	return true
end

local function TryRebirth(profile)
	local threshold = profile.Thresholds[profile.Stars + 1]
	if not threshold or profile.TotalEarned < threshold then
		return false
	end
	-- Renaissance = conservation totale (rév. 26/08) : créatures et objets intacts.
	profile.Eggs = {}
	profile.SanctuaryLevel = 1
	profile.Stars += 1
	profile.Rebirths += 1
	profile.SkillPoints += 1
	profile.Essence = Config.STARTER_ESSENCE
	if profile.Stars >= Config.WORLDS.World2.UnlockRebirths then
		profile.CurrentWorld = "World2"
	end
	return true
end

-- Priorité d'achat de l'Arbre d'Étoiles pour la sim (1 point/rénaissance).
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

-- Paniers joueur. La luck multiplie les poids de mutation (x1+bonus) :
-- bonus élevé = plus de chances sur TOUTES les mutations, sans jackpot
-- inflation (garanti par MutationWeights_Test "large luck bonus").
local PROFILE_LUCK = { f2p = 0, starter = 0.35, vip = 0.35 + Config.VIP_LUCK_BONUS, whale = 0.75 }

local function ApplyProfile(profile, kind)
	if kind == "meute" then
		-- f2p jouant avec 3 amis actifs dans le serveur (cap meute, bible §4.C).
		profile.PackFriends = Config.PACK_MAX_FRIENDS
		return profile
	end
	if kind == "groupe" then
		profile.GroupMember = true
		return profile
	end
	if kind == "f2p" then
		return profile
	end
	local creature = Gameplay.CreateCreature("Rare", "CinderSeraph", "Shadow")
	table.insert(profile.Creatures, creature)
	Index.Register(profile.Index, "CinderSeraph", "Rare", "Shadow")
	profile.Essence += 1000
	if kind == "whale" then
		profile.Entitlements = { MoreSlots = true, PassiveBoost = true }
	end
	return profile
end

local function Simulate(strategy: string?, options)
	options = options or {}
	local thresholds = options.thresholds or Config.REBIRTH_THRESHOLDS
	local kind = options.profileKind or "f2p"
	local baseLuck = PROFILE_LUCK[kind] or PROFILE_LUCK.f2p

	local profile = ApplyProfile(NewProfile(thresholds), kind)
	local time = 0
	local nextRift = Config.RIFT_INTERVAL
	local riftActiveUntil = 0
	local riftDone = false
	local milestones = {}
	local stats = { Hatched = 0, Rifts = 0, Evolutions = 0, Upgrades = 0, SkillNodes = 0 }

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
			-- ponytail: respecte le gate sanctuaire (œufs verrouillés par rang)
			local gate = Sanctuary.EggGate(profile.SanctuaryLevel)
			for _, candidate in { "LegendaryEgg", "EpicEgg", "RareEgg", "UncommonEgg", "CommonEgg" } do
				if
					profile.Essence >= Config.EGG_PRICES[candidate]
					and not (gate[candidate] and profile.SanctuaryLevel < gate[candidate])
				then
					tier = candidate
					break
				end
			end
		elseif strategy == "common" then
			tier = "CommonEgg"
		end
		if TryBuyNode(profile) then
			stats.SkillNodes += 1
		end

		if tier and BuyAndHatch(profile, tier, baseLuck + SkillTree.Effects(profile.SkillRanks).HatchLuck) then
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

		if TryRebirth(profile) then
			table.insert(milestones, { Rebirth = profile.Rebirths, At = time })
			if options.debug then
				local top = profile.Creatures[1]
				print(
					string.format(
						"[SIMDBG] %s R%d t=%ds earned=%d rate=%.1f creatures=%d sanc=%d top=%s %s",
						kind,
						profile.Rebirths,
						time,
						profile.TotalEarned,
						GetRate(profile),
						#profile.Creatures,
						profile.SanctuaryLevel,
						top and top.SpeciesId or "-",
						top and tostring(top.Rarity) .. "/" .. tostring(top.Mutation) or "-"
					)
				)
			end
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
		Profile = (options and options.profileKind) or "f2p",
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
