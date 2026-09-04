--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)

local DataSync = {}

local container
local sessionLuck
local packService
local luckService
local boostService
local skillService
local Config = require(ReplicatedStorage.Shared.Config)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)

function DataSync:Init(cont)
	container = cont
	sessionLuck = cont:Get("SessionLuck")
	packService = cont:Get("PackService")
	luckService = cont:Get("LuckService")
	boostService = cont:Get("BoostService")
	skillService = cont:Get("SkillService")
end

function DataSync:Send(player: Player)
	local saveService = container:Get("SaveService")
	local essenceService = container:Get("EssenceService")
	local profile = saveService:GetProfile(player)
	if not profile then
		return
	end
	local eff = skillService:EffectsOf(profile)
	local luck = sessionLuck.For(player)
		+ luckService:PotionBonus(player)
		+ boostService:CurrentBonus()
		+ eff.HatchLuck
		+ if profile.Data.Entitlements.VIP then Config.VIP_LUCK_BONUS else 0
	local eggRates = {}
	local stats = profile.Data.Stats
	for tier in Config.EGG_RARITY_WEIGHTS do
		eggRates[tier] = Gameplay.FinalHatchWeights(tier, luck, nil, stats.TotalHatched, stats.HatchesSinceRare or 0)
	end
	Net.Sync:FireClient(player, {
		Essence = math.floor(profile.Data.Essence),
		Creatures = profile.Data.Creatures,
		Eggs = profile.Data.Eggs,
		Rate = essenceService.GetRate(player),
		SanctuaryLevel = profile.Data.SanctuaryLevel,
		Index = profile.Data.Index,
		Items = profile.Data.Items,
		Stars = profile.Data.Stars,
		Rebirths = profile.Data.Rebirths,
		Stats = profile.Data.Stats,
		Quests = profile.Data.Quests,
		TutorialDone = profile.Data.TutorialDone,
		Entitlements = profile.Data.Entitlements,
		Offers = profile.Data.Offers,
		Luck = luck,
		EggRates = eggRates,
		LuckPotion = profile.Data.LuckPotion,
		SkillPoints = profile.Data.SkillPoints,
		SkillRanks = profile.Data.SkillRanks,
		CompanionId = profile.Data.CompanionId,
		Meute = packService and packService:Count(player) or 0,
	})
end

return DataSync
