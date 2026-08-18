local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)

local LeaderboardService = {}

local saveService

local Store
local storeOk = pcall(function()
	Store = DataStoreService:GetDataStore("RiftBeastsLeaderboard_v1")
end)
if not storeOk then
	Store = {
		GetAsync = function()
			return nil
		end,
		SetAsync = function() end,
	}
end

-- Cache local : entrées { userId = { Name, Essence, SanctuaryLevel, Ranks = { [rarity] = n }, Species = { [speciesId] = n } } }
local entries: { [number]: any } = {}
local cooldowns: { [Player]: number } = {}
local lastRefresh = 0

local MESSAGE_TOPIC = "RiftBeastsLeaderboard_v1"

--[[ Pure logic (unit-testable) ]]

function LeaderboardService.BuildEntry(userId: number, name: string, profile: any)
	local entry = {
		UserId = userId,
		Name = name,
		Essence = profile.Data.Stats.TotalEssenceEarned,
		SanctuaryLevel = profile.Data.SanctuaryLevel,
		Ranks = {},
		Species = {},
	}
	for _, creature in profile.Data.Creatures do
		entry.Ranks[creature.Rarity] = (entry.Ranks[creature.Rarity] or 0) + 1
		entry.Species[creature.SpeciesId] = (entry.Species[creature.SpeciesId] or 0) + 1
	end
	return entry
end

function LeaderboardService.TopEntries(entriesTable: { any }, limit: number): { any }
	local sorted = {}
	for _, entry in entriesTable do
		table.insert(sorted, entry)
	end
	table.sort(sorted, function(a, b)
		if a.Essence == b.Essence then
			return a.UserId < b.UserId
		end
		return a.Essence > b.Essence
	end)
	local result = {}
	for i = 1, math.min(limit, #sorted) do
		table.insert(result, sorted[i])
	end
	return result
end

--[[ Runtime ]]

local function PersistSnapshot(entry: any)
	pcall(function()
		Store:SetAsync(`Snapshot_{entry.UserId}`, entry)
	end)
end

local function RefreshLocal()
	local now = os.clock()
	if now - lastRefresh < Config.LEADERBOARD_REFRESH then
		return
	end
	lastRefresh = now
	for player, profile in pairs(saveService.Profiles) do
		local entry = LeaderboardService.BuildEntry(player.UserId, player.Name, profile)
		entries[player.UserId] = entry
		PersistSnapshot(entry)
	end

	local top = LeaderboardService.TopEntries(entries, Config.LEADERBOARD_TOP)
	local payload = {}
	for i, entry in top do
		table.insert(payload, {
			UserId = entry.UserId,
			Name = entry.Name,
			Essence = entry.Essence,
			SanctuaryLevel = entry.SanctuaryLevel,
			Rank = i,
		})
	end
	if not game:GetService("RunService"):IsStudio() then
		pcall(function()
			MessagingService:PublishAsync(MESSAGE_TOPIC, payload)
		end)
	end
end

function LeaderboardService:Init(container)
	saveService = container:Get("SaveService")
end

function LeaderboardService:Start()
	-- SubscribeAsync bloque indéfiniment en Studio (non publié) : skip en local.
	-- ponytail: sync cross-serveur à valider sur place publié ; le local reste fonctionnel.
	if not game:GetService("RunService"):IsStudio() then
		pcall(function()
			MessagingService:SubscribeAsync(MESSAGE_TOPIC, function(message)
				if type(message) ~= "table" then
					return
				end
				for _, row in message do
					if type(row.UserId) == "number" and type(row.Essence) == "number" and entries[row.UserId] then
						if row.Essence > entries[row.UserId].Essence then
							entries[row.UserId].Essence = row.Essence
						end
					end
				end
			end)
		end)
	end

	Players.PlayerAdded:Connect(function(player)
		local profile = saveService:GetProfile(player)
		if profile then
			entries[player.UserId] = LeaderboardService.BuildEntry(player.UserId, player.Name, profile)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		cooldowns[player] = nil
	end)

	Net.LeaderboardRequest.OnServerEvent:Connect(function(player: Player)
		local now = os.clock()
		if now - (cooldowns[player] or 0) < Config.LEADERBOARD_QUERY_COOLDOWN then
			return
		end
		cooldowns[player] = now
		RefreshLocal()
		local top = LeaderboardService.TopEntries(entries, Config.LEADERBOARD_TOP)
		local payload = {}
		for i, entry in top do
			table.insert(payload, {
				UserId = entry.UserId,
				Name = entry.Name,
				Essence = math.floor(entry.Essence),
				SanctuaryLevel = entry.SanctuaryLevel,
				Rank = i,
			})
		end
		Net.LeaderboardSync:FireClient(player, { Entries = payload })
	end)

	Net.LeaderboardVisit.OnServerEvent:Connect(function(player: Player, userId: any)
		local now = os.clock()
		if now - (cooldowns[player] or 0) < Config.LEADERBOARD_QUERY_COOLDOWN then
			return
		end
		cooldowns[player] = now
		if typeof(userId) ~= "number" then
			return
		end

		local entry = entries[userId]
		if not entry then
			local ok, snapshot = pcall(function()
				return Store:GetAsync(`Snapshot_{userId}`)
			end)
			if ok and type(snapshot) == "table" then
				entry = snapshot
			end
		end
		if not entry then
			return
		end

		-- Top species by count
		local speciesTop = {}
		for id, count in entry.Species do
			table.insert(speciesTop, { Id = id, Count = count })
		end
		table.sort(speciesTop, function(a, b)
			return a.Count > b.Count
		end)

		Net.LeaderboardDetail:FireClient(player, {
			Name = entry.Name,
			SanctuaryLevel = entry.SanctuaryLevel,
			Essence = math.floor(entry.Essence),
			Ranks = entry.Ranks,
			Species = speciesTop,
		})
	end)
end

return LeaderboardService
