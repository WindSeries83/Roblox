--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local FeatureUnlocks = require(ReplicatedStorage.Shared.FeatureUnlocks)
local Objective = require(ReplicatedStorage.Shared.Objective)
local Offers = require(ReplicatedStorage.Shared.Offers)
local RotatingEgg = require(ReplicatedStorage.Shared.RotatingEgg)
local Rush = require(ReplicatedStorage.Shared.Rush)
local Config = require(ReplicatedStorage.Shared.Config)
local Sanctuary = require(ReplicatedStorage.Shared.Sanctuary)
local PaidRandomPolicy = require(ReplicatedStorage.Shared.PaidRandomPolicy)

local DataSync = {}

local container
local sessionLuck
local packService
local boostService
local analyticsService

function DataSync:Init(cont)
	container = cont
	sessionLuck = cont:Get("SessionLuck")
	packService = cont:Get("PackService")
	boostService = cont:Get("BoostService")
	analyticsService = cont:Get("AnalyticsService")
end

function DataSync:Send(player: Player)
	local saveService = container:Get("SaveService")
	local essenceService = container:Get("EssenceService")
	local profile = saveService:GetProfile(player)
	if not profile then
		return
	end
	local now = os.time()
	local featureUnlocks = FeatureUnlocks.For(profile.Data)
	local nextAction = Objective.Pick(profile.Data, nil)
	local offerState = profile.Data.Offers or {}
	local rotatingSnapshot = RotatingEgg.Snapshot(now, profile.Data.Stats.HatchesSinceRare)
	local hatchService = container:Get("HatchService")
	local eggProbabilityContext = {}
	for _, tier in Sanctuary.EGG_TIERS do
		local context = hatchService:ContextFor(player, { Tier = tier })
		if context then
			eggProbabilityContext[tier] = {
				RarityRates = context.RarityWeights,
				MutationRates = context.MutationWeights,
				Luck = context.Luck,
				PityForced = context.PityForced,
			}
		end
	end
	if rotatingSnapshot then
		local proposalKey = tostring(rotatingSnapshot.WindowIndex)
		if player:GetAttribute("RotatingEggProposal") ~= proposalKey then
			player:SetAttribute("RotatingEggProposal", proposalKey)
			analyticsService:Event("rotating_egg_proposed", {
				Id = rotatingSnapshot.Id,
				Tier = rotatingSnapshot.Tier,
				WindowIndex = rotatingSnapshot.WindowIndex,
			})
		end
	end
	local policyService = container:Get("PolicyService")
	local policy = policyService:GetState(player)
	local catalog = Offers.VisibleFor(profile.Data, featureUnlocks, now)
	for key, offer in catalog do
		local product = Config.DEV_PRODUCTS[offer.ConfigKey]
		if PaidRandomPolicy.RequiresEligibility(product)
			and (not policy.Loaded or policy.ArePaidRandomItemsRestricted)
		then
			catalog[key] = nil
		end
	end
	Net.Sync:FireClient(player, {
		Policy = policy,
		Essence = math.floor(profile.Data.Essence),
		Creatures = profile.Data.Creatures,
		Eggs = profile.Data.Eggs,
		Incubators = profile.Data.Incubators,
		Rate = essenceService.GetRate(player),
		SanctuaryLevel = profile.Data.SanctuaryLevel,
		Index = profile.Data.Index,
		Items = profile.Data.Items,
		Stars = profile.Data.Stars,
		Rebirths = profile.Data.Rebirths,
		Stats = profile.Data.Stats,
		Quests = profile.Data.Quests,
		TutorialDone = profile.Data.TutorialDone,
		WorldProgress = profile.Data.WorldProgress,
		SanctuaryAssignments = profile.Data.SanctuaryAssignments,
		FeatureUnlocks = featureUnlocks,
		UnlockReasons = FeatureUnlocks.Reasons(profile.Data),
		Social = {
			Enabled = featureUnlocks.Social == true,
			PackFriends = packService and packService:Count(player) or 0,
		},
		NextAction = nextAction,
		Entitlements = profile.Data.Entitlements,
		Offers = {
			FirstPurchaseEligible = offerState.FirstPurchaseEligible == true,
			FirstPurchaseClaimed = offerState.FirstPurchaseClaimed == true,
			Catalog = catalog,
		},
		Luck = sessionLuck.For(player),
		LuckPotion = profile.Data.LuckPotion,
		SkillPoints = profile.Data.SkillPoints,
		SkillRanks = profile.Data.SkillRanks,
		CompanionId = profile.Data.CompanionId,
		DuelDefense = profile.Data.DuelDefense,
		DuelSeason = profile.Data.DuelSeason,
		VipExpiresAt = profile.Data.VipExpiresAt,
		ServerBoostUntil = boostService and boostService:Until() or 0,
		Meute = packService and packService:Count(player) or 0,
		RotatingEgg = rotatingSnapshot,
		EggProbabilityContext = eggProbabilityContext,
		Rush = Rush.Snapshot(profile.Data.Rush and profile.Data.Rush.Active, now),
	})
end

function DataSync:Start()
	task.spawn(function()
		local rotation = RotatingEgg.RotationIndex(os.time())
		while true do
			local now = os.time()
			local nextBoundary = (rotation + 1) * Config.ROTATING_EGG_ROTATION_SECONDS
			task.wait(math.max(1, nextBoundary - now))
			local current = RotatingEgg.RotationIndex(os.time())
			if current ~= rotation then
				rotation = current
				for _, player in Players:GetPlayers() do
					self:Send(player)
				end
			end
		end
	end)
end

return DataSync
