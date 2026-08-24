local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)

local QuestService = {}

local log
local saveService
local essenceService

local container

function QuestService.RollDaily(day: string, userId: number): { string }
	local seed = 0
	for i = 1, #day do
		seed += string.byte(day, i) * i
	end
	seed += userId * 17

	local pool = {}
	for id in Config.DAILY_QUESTS do
		table.insert(pool, id)
	end

	local list = {}
	for _ = 1, math.min(Config.DAILY_QUESTS_COUNT, #pool) do
		local idx = (seed % #pool) + 1
		table.insert(list, pool[idx])
		table.remove(pool, idx)
		seed = seed * 31 + 7
	end
	return list
end

function QuestService.EvaluateAchievements(data: any): { [string]: boolean }
	local result = {}
	local function met(id: string)
		result[id] = true
	end

	if data.Stats.TotalHatched >= 1 then
		met("FirstHatch")
	end
	if data.Stats.TotalHatched >= 10 then
		met("TenHatch")
	end
	if data.Stats.TotalHatched >= 100 then
		met("HundredHatch")
	end
	if #data.Creatures >= 5 then
		met("FiveCreatures")
	end
	if data.Stats.RiftsCompleted >= 1 then
		met("FirstRift")
	end
	if data.Stats.RiftsCompleted >= 10 then
		met("RiftMaster")
	end
	if data.Stats.TotalBred >= 1 then
		met("FirstBreed")
	end
	if data.Stats.TotalBred >= 10 then
		met("Breeder")
	end
	if data.Rebirths >= 1 then
		met("FirstRebirth")
	end
	if data.Stats.TotalEssenceEarned >= 10000 then
		met("Essence10k")
	end

	local indexCount = 0
	for _ in data.Index do
		indexCount += 1
	end
	if indexCount >= 10 then
		met("Dex10")
	end
	if indexCount >= 50 then
		met("Dex50")
	end

	local hasMutation = false
	for _, creature in data.Creatures do
		if creature.Mutation ~= false and creature.Mutation ~= nil then
			hasMutation = true
			break
		end
	end
	if hasMutation then
		met("FirstMutation")
	end

	return result
end

local function SyncQuests(player: Player, notice: any?)
	local profile = saveService:GetProfile(player)
	if not profile then
		return
	end
	Net.QuestsSync:FireClient(player, {
		Quests = profile.Data.Quests,
		Notice = notice,
	})
end

local function EnsureQuests(player: Player)
	local profile = saveService:GetProfile(player)
	if not profile then
		return nil
	end
	local quests = profile.Data.Quests
	if quests.Day ~= os.date("%Y-%m-%d") then
		quests.Day = os.date("%Y-%m-%d")
		quests.Daily = {}
		for _, questId in QuestService.RollDaily(quests.Day, player.UserId) do
			table.insert(quests.Daily, { Id = questId, Progress = 0, Claimed = false })
		end
	end
	return quests
end

local function UnlockAchievements(player: Player): { string }
	local profile = saveService:GetProfile(player)
	if not profile then
		return {}
	end
	local met = QuestService.EvaluateAchievements(profile.Data)
	local unlocked = {}
	for id, def in Config.ACHIEVEMENTS do
		if met[id] and not profile.Data.Quests.Achievements[id] then
			profile.Data.Quests.Achievements[id] = true
			profile.Data.LastPlayed = os.time()
			essenceService:Add(player, def.Reward, `Achievement_{id}`)
			log:Economy("Quests", "Achievement", {
				Player = player.Name,
				Achievement = id,
				Reward = def.Reward,
			})
			table.insert(unlocked, { Id = id, Name = def.Name })
		end
	end
	return unlocked
end

local function ProgressDaily(player: Player, questId: string, amount: number)
	local profile = saveService:GetProfile(player)
	local quests = EnsureQuests(player)
	if not profile or not quests then
		return
	end
	local target = Config.DAILY_QUESTS[questId] and Config.DAILY_QUESTS[questId].Target or 0
	local completed = nil
	for _, quest in quests.Daily do
		if quest.Id == questId and not quest.Claimed and quest.Progress < target then
			quest.Progress = math.min(quest.Progress + amount, target)
			if quest.Progress >= target then
				completed = questId
			end
			break
		end
	end
	profile.Data.LastPlayed = os.time()
	local notice = nil
	if completed then
		notice = { Type = "QuestComplete", Name = Config.DAILY_QUESTS[completed].Name }
		log:Economy("Quests", "DailyComplete", { Player = player.Name, Quest = completed })
		SyncQuests(player, notice)
	end
	return notice
end

local function ProgressAndUnlock(player: Player, questId: string, amount: number)
	ProgressDaily(player, questId, amount)
	local unlocked = UnlockAchievements(player)
	if #unlocked > 0 then
		SyncQuests(player, { Type = "Achievement", Name = unlocked[1].Name })
	end
end

function QuestService:OnHatch(player: Player, _mutated: boolean)
	ProgressAndUnlock(player, "HatchDaily", 1)
end

function QuestService:OnBreed(player: Player)
	ProgressAndUnlock(player, "BreedDaily", 1)
end

function QuestService:OnRiftWon(player: Player)
	ProgressAndUnlock(player, "RiftDaily", 1)
end

function QuestService:OnEssenceGained(player: Player, amount: number, source: string)
	if source == "QuestReward" then
		return
	end
	if string.find(source, "Achievement_", 1, true) == 1 then
		return
	end
	ProgressDaily(player, "EssenceDaily", amount)
	UnlockAchievements(player)
end

function QuestService:OnIndex(player: Player)
	ProgressAndUnlock(player, "IndexDaily", 1)
end

function QuestService:OnRebirth(player: Player)
	UnlockAchievements(player)
end

function QuestService:Init(cont)
	container = cont
	log = cont:Get("Log")
	saveService = cont:Get("SaveService")
	essenceService = cont:Get("EssenceService")
end

function QuestService:Start()
	Net.QuestClaim.OnServerEvent:Connect(function(player: Player, questId: string)
		local quests = EnsureQuests(player)
		if not quests then
			return
		end
		for _, quest in quests.Daily do
			local def = Config.DAILY_QUESTS[quest.Id]
			if quest.Id == questId and def and not quest.Claimed and quest.Progress >= def.Target then
				quest.Claimed = true
				quest.Progress = def.Target
				local profile = saveService:GetProfile(player)
				profile.Data.LastPlayed = os.time()
				essenceService:Add(player, def.Reward, "QuestReward")
				log:Economy("Quests", "Claim", {
					Player = player.Name,
					Quest = questId,
					Reward = def.Reward,
				})
				SyncQuests(player)
				container:Get("DataSync"):Send(player)
				container:Get("SeasonService"):OnQuestClaim(player)
				return
			end
		end
	end)

	Net.TutorialComplete.OnServerEvent:Connect(function(player: Player)
		local profile = saveService:GetProfile(player)
		if not profile or profile.Data.TutorialDone then
			return
		end
		profile.Data.TutorialDone = true
		profile.Data.LastPlayed = os.time()
		essenceService:Add(player, Config.TUTORIAL_REWARD, "TutorialReward")
		log:Economy("Quests", "TutorialComplete", {
			Player = player.Name,
			Reward = Config.TUTORIAL_REWARD,
		})
	end)

	Players.PlayerAdded:Connect(function(player)
		EnsureQuests(player)
	end)

	for _, player in Players:GetPlayers() do
		EnsureQuests(player)
	end
end

return QuestService
