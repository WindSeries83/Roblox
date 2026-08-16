local ServerScriptService = game:GetService("ServerScriptService")

local ProfileStore = require(ServerScriptService.ServerPackages.ProfileStore)

local SaveService = {}

SaveService.Profiles = {}

local Store = ProfileStore.New("RiftBeastsData_v1", {
	Essence = 0,
	Creatures = {},
	Eggs = {},
	SanctuaryLevel = 1,
	Stats = { TotalHatched = 0, TotalEssenceEarned = 0, RiftsCompleted = 0 },
	LastPlayed = 0,
	Version = 1,
})

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

function SaveService:SaveProfile(player: Player)
	local profile = self.Profiles[player]
	if profile then
		profile:Save()
	end
end

return SaveService
