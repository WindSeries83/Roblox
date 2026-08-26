local ServerScriptService = game:GetService("ServerScriptService")

local ProfileStore = require(ServerScriptService.ServerPackages.ProfileStore)

local SaveService = {}

SaveService.Profiles = {}

local DATA_VERSION = 8

local Store = ProfileStore.New("RiftBeastsData_v1", {
	Essence = 0,
	Creatures = {},
	Eggs = {},
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
			FirstHatchAt = 0,
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
	SkillPoints = 0,
	SkillRanks = {},
	Offers = {
		FirstPurchaseEligible = false,
		FirstPurchaseClaimed = false,
		ReturnGifts = {},
	},
	VipGiftDate = "",
	TutorialDone = false,
	Version = DATA_VERSION,
})

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
				FirstHatchAt = 0,
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
}

function SaveService.Migrate(data)
	local version = data.Version or 1
	while version < DATA_VERSION do
		local migrate = MIGRATIONS[version]
		if migrate then
			migrate(data)
		end
		version += 1
	end
	return data
end

local function ProfileKey(player: Player): string
	return `Player_{player.UserId}`
end

function SaveService:Init(container)
	local log = container:Get("Log")
	Store.OnError:Connect(function(message, store_name, profile_key)
		warn(`[SaveService] Erreur DataStore: {store_name}/{profile_key} - {message}`)
	end)
	Store.OnOverwrite:Connect(function(store_name, profile_key)
		log:Economy("SaveService", "ProfileOverwrite", { Store = store_name, Key = profile_key })
	end)
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
		profile.OnSessionEnd:Connect(function()
			self.Profiles[player] = nil
		end)
	end
	return profile
end

function SaveService:GetProfile(player: Player)
	return self.Profiles[player]
end

function SaveService:ReleaseProfile(player: Player)
	local profile = self.Profiles[player]
	if profile then
		self.Profiles[player] = nil
		profile:EndSession()
	end
end

return SaveService
