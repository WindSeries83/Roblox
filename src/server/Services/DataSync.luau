local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)

local DataSync = {}

local container
local sessionLuck

function DataSync:Init(cont)
	container = cont
	sessionLuck = cont:Get("SessionLuck")
end

function DataSync:Send(player: Player)
	local saveService = container:Get("SaveService")
	local essenceService = container:Get("EssenceService")
	local profile = saveService:GetProfile(player)
	if not profile then
		return
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
		Luck = sessionLuck.For(player),
		LuckPotion = profile.Data.LuckPotion,
		SkillPoints = profile.Data.SkillPoints,
		SkillRanks = profile.Data.SkillRanks,
	})
end

return DataSync
