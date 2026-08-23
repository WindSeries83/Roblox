local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local Net = require(ReplicatedStorage.Shared.Net)

-- Amis (bible §4.B) : registre cross-serveur userId -> serveur courant.
-- MemoryStore = source de vérité éphémère (TTL), teleport validé serveur.
-- ponytail: MemoryStore indisponible en place non publiée -> mode no-op silencieux,
-- le registre s'activera dès la publication (Lot 5).
local FriendRegistry = {}

local TTL = 90
local HEARTBEAT = 30

local log
local store: MemoryStoreSortedMap? = nil

local function GetStore(): MemoryStoreSortedMap?
	if store then
		return store
	end
	local ok, map = pcall(function()
		return MemoryStoreService:GetSortedMap("FriendRegistry")
	end)
	if ok then
		store = map
	end
	return store
end

local function Key(userId: number): string
	return `u{userId}`
end

local function Heartbeat(player: Player)
	local map = GetStore()
	if not map then
		return
	end
	pcall(function()
		map:SetAsync(Key(player.UserId), { JobId = game.JobId, Name = player.Name }, TTL)
	end)
end

function FriendRegistry:Lookup(userId: number): (string?, string?)
	local map = GetStore()
	if not map then
		return nil, nil
	end
	local ok, value = pcall(function()
		return map:GetAsync(Key(userId))
	end)
	if ok and type(value) == "table" and type(value.JobId) == "string" then
		return value.JobId, value.Name
	end
	return nil, nil
end

function FriendRegistry:Init(container)
	log = container:Get("Log")
end

function FriendRegistry:Start()
	if not GetStore() then
		log:Economy("Friends", "RegistryUnavailable", { Reason = "MemoryStore indisponible (place non publiée)" })
	end
	for _, player in Players:GetPlayers() do
		task.spawn(Heartbeat, player)
	end
	Players.PlayerAdded:Connect(function(player)
		task.spawn(Heartbeat, player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		local map = GetStore()
		if map then
			pcall(function()
				map:RemoveAsync(Key(player.UserId))
			end)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(HEARTBEAT)
			for _, player in Players:GetPlayers() do
				task.spawn(Heartbeat, player)
			end
		end
	end)

	Net.FriendsSync.OnServerEvent:Connect(function(player: Player)
		if not GetStore() then
			Net.FriendsSync:FireClient(player, { Online = {} })
			return
		end
		local ok, pages = pcall(function()
			return Players:GetFriendsAsync(player.UserId)
		end)
		if not ok then
			return
		end
		local online = {}
		local seen = {}
		local function AddCurrentPage()
			for _, friend in pages:GetCurrentPage() do
				if not seen[friend.Id] then
					seen[friend.Id] = true
					local jobId, name = FriendRegistry:Lookup(friend.Id)
					if jobId then
						table.insert(online, {
							UserId = friend.Id,
							Name = name or friend.Username,
							Here = jobId == game.JobId,
							JobId = if jobId ~= game.JobId then jobId else nil,
						})
					end
				end
			end
		end
		local okPages, errPages = pcall(function()
			AddCurrentPage()
			while not pages.IsFinished do
				pages:AdvanceToNextPageAsync()
				AddCurrentPage()
			end
		end)
		if not okPages then
			log:Economy("Friends", "ListFail", { Player = player.Name, Err = tostring(errPages) })
			return
		end
		Net.FriendsSync:FireClient(player, { Online = online })
	end)

	Net.JoinFriend.OnServerEvent:Connect(function(player: Player, targetUserId: unknown)
		if type(targetUserId) ~= "number" then
			return
		end
		local isFriend = false
		pcall(function()
			isFriend = player:IsFriendsWith(targetUserId)
		end)
		if not isFriend then
			log:Economy("Friends", "JoinReject", { Player = player.Name, Target = targetUserId, Reason = "pas ami" })
			return
		end
		local jobId = FriendRegistry:Lookup(targetUserId)
		if not jobId or jobId == game.JobId then
			log:Economy("Friends", "JoinReject", {
				Player = player.Name,
				Target = targetUserId,
				Reason = "introuvable ou même serveur",
			})
			return
		end
		log:Economy("Friends", "Teleport", { Player = player.Name, Target = targetUserId })
		pcall(function()
			TeleportService:TeleportAsync(game.PlaceId, jobId, { player })
		end)
	end)
end

return FriendRegistry
