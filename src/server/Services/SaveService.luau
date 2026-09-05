--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ProfileStore = require(ServerScriptService.ServerPackages.ProfileStore)
local Config = require(ReplicatedStorage.Shared.Config)
local Incubation = require(ReplicatedStorage.Shared.Incubation)
local Worlds = require(ReplicatedStorage.Shared.Worlds)
local PurchaseLedger = require(ReplicatedStorage.Shared.PurchaseLedger)

local SaveService = {}

SaveService.Profiles = {}
SaveService.ProfileLoaded = Instance.new("BindableEvent")

local DATA_VERSION = 17

local function NormalizeIncubators(data)
	local valid = {}
	if type(data.Incubators) == "table" then
		for _, record in data.Incubators do
			if Incubation.IsRecord(record) then
				table.insert(valid, record)
			end
		end
	end
	data.Incubators = valid
end

local function NormalizeRush(data)
	local source = data.Rush
	local candidate = nil
	if type(source) == "table" then
		candidate = if type(source.Active) == "table" then source.Active else source
	end
	if type(candidate) ~= "table" then
		data.Rush = {}
		return
	end

	local worldId = candidate.WorldId
	local world = if type(worldId) == "string" then Worlds.Get(worldId) else nil
	local startedAt = candidate.StartedAt
	if
		not world
		or type(startedAt) ~= "number"
		or startedAt < 0
		or startedAt == math.huge
		or startedAt ~= startedAt
	then
		data.Rush = {}
		return
	end
	local endsAt = candidate.EndsAt
	if type(endsAt) ~= "number" or endsAt < startedAt or endsAt == math.huge or endsAt ~= endsAt then
		endsAt = startedAt + world.Rush.TargetSeconds
	end
	data.Rush = {
		Active = {
			WorldId = worldId,
			AttemptId = if type(candidate.AttemptId) == "string" and candidate.AttemptId ~= ""
				then candidate.AttemptId
				else `legacy:{worldId}:{startedAt}`,
			StartedAt = math.floor(startedAt),
			EndsAt = math.floor(endsAt),
			Completed = candidate.Completed == true,
			Claimed = candidate.Claimed == true,
			Expired = candidate.Expired == true,
		},
	}
end

local Store = ProfileStore.New("RiftBeastsData_v1", {
	Essence = 0,
	Creatures = {},
	Eggs = {},
	Incubators = {},
	SanctuaryLevel = 1,
	Stats = {
		TotalHatched = 0,
		TotalEssenceEarned = 0,
		RiftsCompleted = 0,
		TotalBred = 0,
		DuelsWon = 0,
		DuelsLost = 0,
		MarketSales = 0,
		HatchesSinceRare = 0,
		Funnel = {
			FirstInteractionAt = 0,
			FirstEggAt = 0,
			FirstHatchAt = 0,
			FirstRiftAt = 0,
			FirstWinAt = 0,
			FirstOptimizationAt = 0,
			FirstRarePlusAt = 0,
			FirstEpicPlusAt = 0,
			FirstPurchaseAt = 0,
		},
	},
	Index = {},
	Items = {},
	Stars = 0,
	Rebirths = 0,
	LastPlayed = 0,
	LoginStreak = 0,
	LastLoginDate = "",
	Quests = {
		Day = "",
		Daily = {},
		Achievements = {},
	},
	Season = {
		Version = 1,
		Level = 1,
		XP = 0,
		ClaimedFree = {},
		ClaimedPremium = {},
	},
	Titles = {},
	MarketHistory = {},
	Entitlements = {
		MoreSlots = false,
		PassiveBoost = false,
		AutoHatch = false,
		StarterBundle = false,
		SeasonPremium = false,
	},
	PurchaseReceipts = {},
	PurchaseReceiptOrder = {},
	EconomyLedger = {},
	MarketLedger = {
		Buys = {},
		Credits = {},
		Listings = {},
	},
	DuelDefense = {},
	DuelLedger = {},
	DuelSeason = {
		Version = 1,
		Rating = 1000,
		Wins = 0,
		Losses = 0,
	},
	LuckPotion = nil,
	VipExpiresAt = 0,
	SkillPoints = 0,
	SkillRanks = {},
	Offers = {
		FirstPurchaseEligible = false,
		FirstPurchaseClaimed = false,
		ReturnGifts = {},
	},
	VipGiftDate = "",
	TutorialDone = false,
	WorldProgress = {},
	Rush = {},
	SanctuaryAssignments = {},
	Version = DATA_VERSION,
})

if RunService:IsStudio() then
	Store = Store.Mock
end

local MIGRATIONS = {
	[1] = function(data)
		data.Index = data.Index or {}
		data.Items = data.Items or {}
		data.Stars = data.Stars or 0
		data.Rebirths = data.Rebirths or 0
		for _, creature in data.Creatures do
			creature.Stage = creature.Stage or 1
			creature.XP = creature.XP or 0
			creature.MaxLevel = creature.MaxLevel or 10
			creature.Equipment = creature.Equipment or {}
			creature.Parents = creature.Parents or {}
			creature.Generation = creature.Generation or 1
			creature.HatchedAt = creature.HatchedAt or 0
		end
		data.Version = 2
	end,
	[2] = function(data)
		data.Stats = data.Stats or {}
		data.Stats.TotalBred = data.Stats.TotalBred or 0
		data.Quests = data.Quests or {
			Day = "",
			Daily = {},
			Achievements = {},
		}
		data.TutorialDone = data.TutorialDone or false
		data.Version = 3
	end,
	[3] = function(data)
		data.Stats = data.Stats or {}
		data.Stats.DuelsWon = data.Stats.DuelsWon or 0
		data.Stats.DuelsLost = data.Stats.DuelsLost or 0
		data.Stats.MarketSales = data.Stats.MarketSales or 0
		data.Season = data.Season or {
			Level = 1,
			XP = 0,
			ClaimedFree = {},
			ClaimedPremium = {},
		}
		data.Titles = data.Titles or {}
		data.MarketHistory = data.MarketHistory or {}
		data.Entitlements = data.Entitlements
			or {
				MoreSlots = false,
				PassiveBoost = false,
				AutoHatch = false,
				StarterBundle = false,
				SeasonPremium = false,
			}
		data.Entitlements.SeasonPremium = data.Entitlements.SeasonPremium or false
		data.Version = 4
	end,
	[4] = function(data)
		data.LoginStreak = data.LoginStreak or 0
		data.LastLoginDate = data.LastLoginDate or ""
		data.Stats = data.Stats or {}
		data.Stats.HatchesSinceRare = data.Stats.HatchesSinceRare or 0
		data.Version = 5
	end,
	[5] = function(data)
		data.SkillPoints = data.SkillPoints or 0
		data.SkillRanks = data.SkillRanks or {}
		data.Offers = data.Offers
			or {
				FirstPurchaseEligible = false,
				FirstPurchaseClaimed = false,
				ReturnGifts = {},
			}
		data.Offers.FirstPurchaseEligible = data.Offers.FirstPurchaseEligible or false
		data.Offers.FirstPurchaseClaimed = data.Offers.FirstPurchaseClaimed or false
		data.Offers.ReturnGifts = data.Offers.ReturnGifts or {}
		data.Stats = data.Stats or {}
		data.Stats.Funnel = data.Stats.Funnel
			or {
				FirstInteractionAt = 0,
				FirstEggAt = 0,
				FirstHatchAt = 0,
				FirstRiftAt = 0,
				FirstWinAt = 0,
				FirstOptimizationAt = 0,
				FirstRarePlusAt = 0,
				FirstEpicPlusAt = 0,
				FirstPurchaseAt = 0,
			}
		data.VipGiftDate = data.VipGiftDate or ""
		data.Version = 6
	end,
	[6] = function(data)
		data.CompanionId = data.CompanionId or nil
		data.Version = 7
	end,
	[7] = function(data)
		data.PurchaseReceipts = data.PurchaseReceipts or {}
		data.Version = 8
	end,
	[8] = function(data)
		data.PurchaseReceipts = data.PurchaseReceipts or {}
		data.PurchaseReceiptOrder = data.PurchaseReceiptOrder or {}
		data.EconomyLedger = data.EconomyLedger or {}
		data.MarketLedger = data.MarketLedger or { Buys = {}, Credits = {}, Listings = {} }
		data.MarketLedger.Buys = data.MarketLedger.Buys or {}
		data.MarketLedger.Credits = data.MarketLedger.Credits or {}
		data.MarketLedger.Listings = data.MarketLedger.Listings or {}
		data.DuelDefense = data.DuelDefense or {}
		data.VipExpiresAt = data.VipExpiresAt or 0
		data.Version = 9
	end,
	[9] = function(data)
		data.Incubators = data.Incubators or {}
		data.Version = 10
	end,
	[10] = function(data)
		NormalizeIncubators(data)
		data.Version = 11
	end,
	[11] = function(data)
		local worlds = { "TwilightGrove", "AshForge", "GalePeaks", "NyxAbyss" }
		local progress = {}
		if type(data.WorldProgress) == "table" then
			for _, worldId in worlds do
				local state = data.WorldProgress[worldId]
				if type(state) == "table" then
					local highest = if type(state.HighestStage) == "number" then state.HighestStage else 0
					progress[worldId] = {
						HighestStage = math.clamp(math.floor(highest), 0, 5),
						BossDefeated = state.BossDefeated == true,
					}
				end
			end
		end
		data.WorldProgress = progress

		local assignments = {}
		if type(data.SanctuaryAssignments) == "table" then
			for index = 1, 3 do
				local sanctuaryId = `Sanctuary{index}`
				local assignment = data.SanctuaryAssignments[sanctuaryId]
				if type(assignment) == "table" then
					local creatureIds = {}
					if type(assignment.CreatureIds) == "table" then
						for _, creatureId in assignment.CreatureIds do
							if type(creatureId) == "string" and creatureId ~= "" then
								table.insert(creatureIds, creatureId)
							end
						end
					end
					assignments[sanctuaryId] = {
						CreatureIds = creatureIds,
						LastCollectedAt = if type(assignment.LastCollectedAt) == "number"
							then math.max(0, math.floor(assignment.LastCollectedAt))
							else 0,
					}
				end
			end
		end
		data.SanctuaryAssignments = assignments
		data.Version = 12
	end,
	[12] = function(data)
		data.Season = data.Season or {}
		data.Season.Version = if type(data.Season.Version) == "number" then data.Season.Version else 1
		data.Season.XP = if type(data.Season.XP) == "number" then math.max(0, data.Season.XP) else 0
		data.Season.Level = if type(data.Season.Level) == "number"
			then math.clamp(math.floor(data.Season.Level), 1, Config.SEASON_MAX_LEVEL)
			else 1
		data.Season.ClaimedFree = data.Season.ClaimedFree or {}
		data.Season.ClaimedPremium = data.Season.ClaimedPremium or {}
		data.Version = 13
	end,
	[13] = function(data)
		NormalizeRush(data)
		data.Version = 14
	end,
	[14] = function(data)
		data.DuelLedger = if type(data.DuelLedger) == "table" then data.DuelLedger else {}
		data.Version = 15
	end,
	[15] = function(data)
		data.DuelSeason = if type(data.DuelSeason) == "table" then data.DuelSeason else {}
		data.DuelSeason.Version = Config.DUEL_SEASON_VERSION
		data.DuelSeason.Rating = if type(data.DuelSeason.Rating) == "number"
			then math.max(0, math.floor(data.DuelSeason.Rating))
			else 1000
		data.DuelSeason.Wins = if type(data.DuelSeason.Wins) == "number"
			then math.max(0, math.floor(data.DuelSeason.Wins))
			else 0
		data.DuelSeason.Losses = if type(data.DuelSeason.Losses) == "number"
			then math.max(0, math.floor(data.DuelSeason.Losses))
			else 0
		data.Version = 16
	end,
	[16] = function(data)
		data.Stats = if type(data.Stats) == "table" then data.Stats else {}
		data.Stats.Funnel = if type(data.Stats.Funnel) == "table" then data.Stats.Funnel else {}
		for _, key in
			{
				"FirstInteractionAt",
				"FirstEggAt",
				"FirstHatchAt",
				"FirstRiftAt",
				"FirstWinAt",
				"FirstOptimizationAt",
				"FirstRarePlusAt",
				"FirstEpicPlusAt",
				"FirstPurchaseAt",
			}
		do
			if type(data.Stats.Funnel[key]) ~= "number" then
				data.Stats.Funnel[key] = 0
			end
		end
		data.Version = 17
	end,
}

function SaveService.Migrate(data)
	local version = if type(data.Version) == "number" then math.floor(data.Version) else 1
	while version < DATA_VERSION do
		local migrate = MIGRATIONS[version]
		if migrate then
			migrate(data)
		end
		version += 1
	end
	-- Les profils déjà migrés peuvent aussi provenir d'une sauvegarde partiellement corrompue.
	-- Nettoyer ici garantit que Restore ne transforme pas une entrée invalide en couveuse bloquée.
	NormalizeIncubators(data)
	NormalizeRush(data)
	data.DuelLedger = if type(data.DuelLedger) == "table" then data.DuelLedger else {}
	data.DuelSeason = if type(data.DuelSeason) == "table" then data.DuelSeason else {}
	data.DuelSeason.Version = if type(data.DuelSeason.Version) == "number"
		then data.DuelSeason.Version
		else Config.DUEL_SEASON_VERSION
	data.DuelSeason.Rating = if type(data.DuelSeason.Rating) == "number"
		then math.max(0, math.floor(data.DuelSeason.Rating))
		else 1000
	data.DuelSeason.Wins = if type(data.DuelSeason.Wins) == "number"
		then math.max(0, math.floor(data.DuelSeason.Wins))
		else 0
	data.DuelSeason.Losses = if type(data.DuelSeason.Losses) == "number"
		then math.max(0, math.floor(data.DuelSeason.Losses))
		else 0
	return data
end

local function ProfileKey(player: Player): string
	return `Player_{player.UserId}`
end

local function SaveAndConfirm(profile: any, proof: ((any) -> boolean)?): boolean
	local ok = pcall(function()
		profile:Save()
	end)
	if not ok then
		return false
	end
	if not proof then
		return true
	end
	local deadline = os.clock() + 8
	repeat
		local saved = profile.LastSavedData
		if saved and proof(saved) then
			return true
		end
		task.wait(0.1)
	until os.clock() >= deadline
	return false
end

function SaveService:Init(container)
	local log = container:Get("Log")
	if Store.OnError then
		Store.OnError:Connect(function(message, store_name, profile_key)
			warn(`[SaveService] Erreur DataStore: {store_name}/{profile_key} - {message}`)
		end)
	end
	if Store.OnOverwrite then
		Store.OnOverwrite:Connect(function(store_name, profile_key)
			log:Economy("SaveService", "ProfileOverwrite", { Store = store_name, Key = profile_key })
		end)
	end
end

function SaveService:LoadProfileAsync(player: Player)
	local profile = Store:StartSessionAsync(ProfileKey(player), {
		Cancel = function()
			return not player:IsDescendantOf(game:GetService("Players"))
		end,
	})
	if profile then
		profile:AddUserId(player.UserId)
		profile:Reconcile()
		SaveService.Migrate(profile.Data)
		self.Profiles[player] = profile
		self.ProfileLoaded:Fire(player, profile)
		profile:MessageHandler(function(message, processed)
			if type(message) ~= "table" then
				processed()
				return
			end
			if message.Type == "DuelSettlement" then
				local challengeId = message.ChallengeId
				local role = message.Role
				local amount = message.Amount
				if
					type(challengeId) ~= "string"
					or challengeId == ""
					or (role ~= "Winner" and role ~= "Loser" and role ~= "Refund")
					or type(amount) ~= "number"
					or amount < 0
					or amount ~= math.floor(amount)
					or amount > Config.DUEL_MAX_WAGER * 2
				then
					processed()
					return
				end
				local marker = `Duel{role}Applied`
				profile.Data.DuelLedger = profile.Data.DuelLedger or {}
				if profile.Data.DuelLedger[challengeId] == marker then
					processed()
					return
				end
				if role == "Refund" and profile.Data.DuelLedger[challengeId] ~= "ChallengerEscrowed" then
					processed()
					return
				end
				local snapshot = PurchaseLedger.Snapshot(profile.Data)
				profile.Data.DuelLedger[challengeId] = marker
				if role == "Winner" then
					profile.Data.Essence += amount
					profile.Data.Stats.TotalEssenceEarned += amount
					profile.Data.Stats.DuelsWon += 1
				elseif role == "Loser" then
					profile.Data.Stats.DuelsLost += 1
				else
					profile.Data.Essence += amount
					profile.Data.Stats.TotalEssenceEarned += amount
				end
				if role == "Winner" or role == "Loser" then
					local duelSeason = profile.Data.DuelSeason
					if role == "Winner" then
						duelSeason.Rating += 25
						duelSeason.Wins += 1
					else
						duelSeason.Rating = math.max(0, duelSeason.Rating - 15)
						duelSeason.Losses += 1
					end
				end
				profile.Data.LastPlayed = os.time()
				local saved = SaveAndConfirm(profile, function(data)
					return data.DuelLedger and data.DuelLedger[challengeId] == marker
				end)
				if not saved then
					PurchaseLedger.Restore(profile.Data, snapshot)
					return
				end
				processed()
				return
			end
			if message.Type ~= "MarketCredit" then
				processed()
				return
			end
			local transactionId = message.TransactionId
			local payout = message.Payout
			if type(transactionId) ~= "string" or type(payout) ~= "number" or payout <= 0 then
				processed()
				return
			end
			local ledger = profile.Data.MarketLedger
			if not ledger.Credits[transactionId] then
				ledger.Credits[transactionId] = true
				local amount = math.floor(payout)
				profile.Data.Essence += amount
				profile.Data.Stats.TotalEssenceEarned += amount
				profile.Data.Stats.MarketSales += 1
				profile.Data.LastPlayed = os.time()
				local saved = SaveAndConfirm(profile, function(data)
					return data.MarketLedger
						and data.MarketLedger.Credits
						and data.MarketLedger.Credits[transactionId] == true
				end)
				if not saved then
					ledger.Credits[transactionId] = nil
					return
				end
			end
			processed()
		end)
		profile.OnSessionEnd:Connect(function()
			self.Profiles[player] = nil
		end)
	end
	return profile
end

function SaveService:GetProfile(player: Player)
	return self.Profiles[player]
end

function SaveService:WaitForProfile(player: Player, timeout: number?): any
	local profile = self:GetProfile(player)
	if profile then
		return profile
	end
	local deadline = os.clock() + (timeout or 10)
	while player:IsDescendantOf(Players) and os.clock() < deadline do
		task.wait(0.1)
		profile = self:GetProfile(player)
		if profile then
			return profile
		end
	end
	return nil
end

function SaveService:SaveProfile(player: Player, proof: ((any) -> boolean)?): boolean
	local profile = self.Profiles[player]
	if not profile then
		return false
	end
	return SaveAndConfirm(profile, proof)
end

function SaveService:QueueProfileMessage(userId: number, message: { [string]: any }): boolean
	local ok, result = pcall(function()
		return Store:MessageAsync(`Player_{userId}`, message)
	end)
	return ok and result == true
end

function SaveService:ReleaseProfile(player: Player)
	local profile = self.Profiles[player]
	if profile then
		self.Profiles[player] = nil
		profile:EndSession()
	end
end

return SaveService
