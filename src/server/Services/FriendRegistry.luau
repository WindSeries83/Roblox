local HttpService = game:GetService("HttpService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local FeatureUnlocks = require(ReplicatedStorage.Shared.FeatureUnlocks)
local Net = require(ReplicatedStorage.Shared.Net)
local Social = require(ReplicatedStorage.Shared.Social)

-- Presence temporaire dans MemoryStore; les invitations sont éphémères dans
-- MessagingService et ne deviennent jamais une donnée de profil durable.
local FriendRegistry = {}

local TTL = 90
local HEARTBEAT = 30
local INVITE_TTL = 60
local INVITE_TOPIC_PREFIX = "RiftBeastsSessionInvite_"

local limits: { [string]: { StartedAt: number, Count: number } } = {}
local pendingInvites: { [number]: { [string]: { FromUserId: number, ExpiresAt: number, FromName: string } } } = {}
local subscriptions: { [number]: any } = {}

local log
local saveService
local worldService
local container
local store: MemoryStoreSortedMap? = nil

local function Log(event: string, fields: { [string]: any })
	if log then
		log:Economy("Friends", event, fields)
	end
end

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

local function Topic(userId: number): string
	return `{INVITE_TOPIC_PREFIX}{userId}`
end

local function Allow(userId: number, action: string, maxCount: number, window: number): boolean
	local key = `{userId}:{action}`
	local now = os.clock()
	local bucket = limits[key]
	if not bucket or now - bucket.StartedAt >= window then
		limits[key] = { StartedAt = now, Count = 1 }
		return true
	end
	if bucket.Count >= maxCount then
		return false
	end
	bucket.Count += 1
	return true
end

local function FriendOf(player: Player, userId: number): boolean
	if userId == player.UserId then
		return false
	end
	local ok, result = pcall(function()
		return player:IsFriendsWith(userId)
	end)
	return ok and result == true
end

local function SocialProfile(player: Player): (any?, string?)
	local profile = saveService and saveService:GetProfile(player)
	if not profile then
		return nil, "Profil indisponible"
	end
	local unlocked, reason = FeatureUnlocks.Require(profile.Data, "Social")
	if not unlocked then
		return nil, reason or "Les fonctions sociales sont verrouillées."
	end
	return profile, nil
end

local function Reply(player: Player, action: string, success: boolean, reason: string?, extra: { [string]: any }?)
	local result: { [string]: any } = { Action = action, Success = success }
	if reason then
		result.Reason = reason
	end
	if extra then
		for key, value in extra do
			result[key] = value
		end
	end
	Net.ActionResult:FireClient(player, result)
end

local function Heartbeat(player: Player)
	local map = GetStore()
	if not map then
		return
	end
	pcall(function()
		map:SetAsync(Key(player.UserId), {
			JobId = game.JobId,
			PlaceId = game.PlaceId,
			Name = player.DisplayName,
		}, TTL)
	end)
end

function FriendRegistry.IsValidUserId(userId: unknown): boolean
	return Social.IsValidUserId(userId)
end

function FriendRegistry.IsInviteValid(invite: any, now: number?): boolean
	return Social.IsInviteValid(invite, now)
end

function FriendRegistry:Lookup(userId: number): (string?, string?, number?)
	if not Social.IsValidUserId(userId) then
		return nil, nil, nil
	end
	local map = GetStore()
	if not map then
		return nil, nil, nil
	end
	local ok, value = pcall(function()
		return map:GetAsync(Key(userId))
	end)
	if ok and type(value) == "table" and type(value.JobId) == "string" and value.JobId ~= "" then
		local placeId = if type(value.PlaceId) == "number" then value.PlaceId else game.PlaceId
		return value.JobId, if type(value.Name) == "string" then value.Name else nil, placeId
	end
	return nil, nil, nil
end

local function AddFriendEntry(
	online: { [number]: { [string]: any } },
	seen: { [number]: boolean },
	userId: number,
	name: string?,
	here: boolean
)
	if seen[userId] then
		return
	end
	seen[userId] = true
	online[userId] = {
		UserId = userId,
		Name = name or `Joueur {userId}`,
		Here = here,
		PlotAvailable = here and worldService ~= nil and worldService:GetPlot(userId) ~= nil,
	}
end

local function BuildOnlineFriends(player: Player): ({ [number]: { [string]: any } }, string?)
	local online: { [number]: { [string]: any } } = {}
	local seen: { [number]: boolean } = {}
	for _, other in Players:GetPlayers() do
		if other ~= player and FriendOf(player, other.UserId) then
			AddFriendEntry(online, seen, other.UserId, other.DisplayName, true)
		end
	end

	local map = GetStore()
	if not map then
		local localEntries = {}
		for _, entry in online do
			table.insert(localEntries, entry)
		end
		table.sort(localEntries, function(a, b)
			return a.UserId < b.UserId
		end)
		return localEntries, "Les amis d'autres serveurs sont momentanément indisponibles."
	end

	local ok, pages = pcall(function()
		return Players:GetFriendsAsync(player.UserId)
	end)
	if not ok then
		local localEntries = {}
		for _, entry in online do
			table.insert(localEntries, entry)
		end
		return localEntries, "La liste Roblox des amis est momentanément indisponible."
	end

	local function ReadPage()
		for _, friend in pages:GetCurrentPage() do
			if Social.IsValidUserId(friend.Id) and not seen[friend.Id] then
				local jobId, name, placeId = FriendRegistry:Lookup(friend.Id)
				if jobId and placeId == game.PlaceId then
					AddFriendEntry(online, seen, friend.Id, name or friend.Username, jobId == game.JobId)
				end
			end
		end
	end

	local okPages, errPages = pcall(function()
		ReadPage()
		while not pages.IsFinished do
			pages:AdvanceToNextPageAsync()
			ReadPage()
		end
	end)
	if not okPages then
		Log("ListFail", { Player = player.Name, Err = tostring(errPages) })
		return {}, "La présence des amis est momentanément indisponible."
	end

	local entries = {}
	for _, entry in online do
		table.insert(entries, entry)
	end
	table.sort(entries, function(a, b)
		return a.UserId < b.UserId
	end)
	return entries, nil
end

local function TeleportTo(player: Player, jobId: string, placeId: number): (boolean, string?)
	if placeId ~= game.PlaceId then
		return false, "Cet ami n'est plus dans cette expérience."
	end
	if jobId == game.JobId then
		return true, nil
	end
	local ok, err = pcall(function()
		local options = Instance.new("TeleportOptions")
		options.ServerInstanceId = jobId
		TeleportService:TeleportAsync(game.PlaceId, { player }, options)
	end)
	if not ok then
		Log("TeleportFail", { Player = player.Name, Err = tostring(err) })
		return false, "La téléportation a échoué; tu peux réessayer."
	end
	return true, nil
end

local function SendInviteTo(
	target: Player,
	invite: { InviteId: string, FromUserId: number, ExpiresAt: number, FromName: string }
)
	pendingInvites[target.UserId] = pendingInvites[target.UserId] or {}
	pendingInvites[target.UserId][invite.InviteId] = {
		FromUserId = invite.FromUserId,
		ExpiresAt = invite.ExpiresAt,
		FromName = invite.FromName,
	}
	Net.FriendInvite:FireClient(target, {
		InviteId = invite.InviteId,
		FromUserId = invite.FromUserId,
		FromName = invite.FromName,
		ExpiresAt = invite.ExpiresAt,
	})
end

local function ReceiveInvite(player: Player, data: any)
	local _, reason = SocialProfile(player)
	if reason or type(data) ~= "table" then
		return
	end
	local invite = {
		InviteId = data.InviteId,
		FromUserId = data.FromUserId,
		ExpiresAt = data.ExpiresAt,
		FromName = if type(data.FromName) == "string" then data.FromName else "un ami",
	}
	if not Social.IsInviteValid(invite) or not FriendOf(player, invite.FromUserId) then
		return
	end
	SendInviteTo(player, invite)
end

local function Subscribe(player: Player)
	local ok, connection = pcall(function()
		return MessagingService:SubscribeAsync(Topic(player.UserId), function(message)
			ReceiveInvite(player, message.Data)
		end)
	end)
	if ok then
		subscriptions[player.UserId] = connection
	else
		Log("MessagingUnavailable", { Player = player.Name, Err = tostring(connection) })
	end
end

local function Unsubscribe(userId: number)
	local connection = subscriptions[userId]
	subscriptions[userId] = nil
	if connection then
		pcall(function()
			connection:Disconnect()
		end)
	end
end

function FriendRegistry:Init(cont)
	container = cont
	log = cont:Get("Log")
	saveService = cont:Get("SaveService")
end

function FriendRegistry:Start()
	worldService = container and container:Get("WorldService") or nil
	if not GetStore() then
		Log("RegistryUnavailable", { Reason = "MemoryStore indisponible (place non publiée)" })
	end
	for _, player in Players:GetPlayers() do
		task.spawn(Heartbeat, player)
		task.spawn(Subscribe, player)
	end
	Players.PlayerAdded:Connect(function(player)
		task.spawn(Heartbeat, player)
		task.spawn(Subscribe, player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		local map = GetStore()
		if map then
			pcall(function()
				map:RemoveAsync(Key(player.UserId))
			end)
		end
		pendingInvites[player.UserId] = nil
		Unsubscribe(player.UserId)
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
		local _, reason = SocialProfile(player)
		if reason then
			Reply(player, "FriendsSync", false, reason)
			return
		end
		if not Allow(player.UserId, "list", 3, 10) then
			Reply(player, "FriendsSync", false, "Attends avant d'actualiser la liste d'amis.")
			return
		end
		local online, warning = BuildOnlineFriends(player)
		Net.FriendsSync:FireClient(player, { Online = online, Warning = warning })
	end)

	Net.JoinFriend.OnServerEvent:Connect(function(player: Player, targetUserId: unknown)
		local _, reason = SocialProfile(player)
		if reason then
			Reply(player, "JoinFriend", false, reason)
			return
		end
		if not Allow(player.UserId, "join", 2, 10) then
			Reply(player, "JoinFriend", false, "Attends avant de rejoindre un ami.")
			return
		end
		if not Social.IsValidUserId(targetUserId) or not FriendOf(player, targetUserId) then
			Reply(player, "JoinFriend", false, "Cette cible n'est pas un ami valide.")
			return
		end
		local jobId, _, placeId = self:Lookup(targetUserId)
		if not jobId or not placeId then
			Reply(player, "JoinFriend", false, "Cet ami n'est plus en ligne.")
			return
		end
		local ok, teleportReason = TeleportTo(player, jobId, placeId)
		if not ok then
			Reply(player, "JoinFriend", false, teleportReason)
			return
		end
		Reply(player, "JoinFriend", true, nil, { ReadOnly = true })
	end)

	Net.InviteFriend.OnServerEvent:Connect(function(player: Player, targetUserId: unknown)
		local _, reason = SocialProfile(player)
		if reason then
			Reply(player, "InviteFriend", false, reason)
			return
		end
		if not Allow(player.UserId, "invite", 3, 30) then
			Reply(player, "InviteFriend", false, "Trop d'invitations; réessaie dans un instant.")
			return
		end
		if not Social.IsValidUserId(targetUserId) or not FriendOf(player, targetUserId) then
			Reply(player, "InviteFriend", false, "Cette cible n'est pas un ami valide.")
			return
		end
		local target = Players:GetPlayerByUserId(targetUserId)
		local jobId, _, placeId = self:Lookup(targetUserId)
		if target and not jobId then
			jobId, _, placeId = game.JobId, target.DisplayName, game.PlaceId
		end
		if not jobId or not placeId then
			Reply(player, "InviteFriend", false, "Cet ami n'est plus en ligne.")
			return
		end
		local invite = {
			InviteId = HttpService:GenerateGUID(false),
			FromUserId = player.UserId,
			ExpiresAt = os.time() + INVITE_TTL,
			FromName = player.DisplayName,
		}
		if target then
			SendInviteTo(target, invite)
		else
			local ok, err = pcall(function()
				MessagingService:PublishAsync(Topic(targetUserId), invite)
			end)
			if not ok then
				Log("InviteFail", { Player = player.Name, Err = tostring(err) })
				Reply(player, "InviteFriend", false, "Roblox ne peut pas envoyer l'invitation pour le moment.")
				return
			end
		end
		Log("InviteSent", { Player = player.Name, Target = targetUserId, ExpiresAt = invite.ExpiresAt })
		Reply(player, "InviteFriend", true, nil, { ExpiresAt = invite.ExpiresAt })
	end)

	Net.RespondFriendInvite.OnServerEvent:Connect(function(player: Player, inviteId: unknown, accepted: unknown)
		local _, reason = SocialProfile(player)
		if reason then
			Reply(player, "RespondFriendInvite", false, reason)
			return
		end
		if not Allow(player.UserId, "respond", 6, 10) then
			Reply(player, "RespondFriendInvite", false, "Attends avant de répondre à une invitation.")
			return
		end
		if not Social.IsValidInviteId(inviteId) or type(accepted) ~= "boolean" then
			Reply(player, "RespondFriendInvite", false, "Invitation invalide ou expirée.")
			return
		end
		local invitations = pendingInvites[player.UserId]
		local invite = invitations and invitations[inviteId]
		if not invite or invite.ExpiresAt <= os.time() then
			if invitations then
				invitations[inviteId] = nil
			end
			Reply(player, "RespondFriendInvite", false, "Cette invitation a expiré.", { InviteId = inviteId })
			return
		end
		invitations[inviteId] = nil
		if not accepted then
			Reply(player, "RespondFriendInvite", true, nil, { Accepted = false, InviteId = inviteId })
			return
		end
		if not FriendOf(player, invite.FromUserId) then
			Reply(player, "RespondFriendInvite", false, "Cet ami n'est plus une cible valide.", { InviteId = inviteId })
			return
		end
		local target = Players:GetPlayerByUserId(invite.FromUserId)
		local jobId, _, placeId = self:Lookup(invite.FromUserId)
		if target and not jobId then
			jobId, _, placeId = game.JobId, target.DisplayName, game.PlaceId
		end
		if not jobId or not placeId then
			Reply(player, "RespondFriendInvite", false, "Ton ami n'est plus en ligne.", { InviteId = inviteId })
			return
		end
		local ok, teleportReason = TeleportTo(player, jobId, placeId)
		if not ok then
			invitations[inviteId] = invite
			Reply(player, "RespondFriendInvite", false, teleportReason, { InviteId = inviteId })
			return
		end
		Reply(player, "RespondFriendInvite", true, nil, { Accepted = true, ReadOnly = true, InviteId = inviteId })
	end)

	Net.VisitPlot.OnServerEvent:Connect(function(player: Player, ownerUserId: unknown)
		local _, reason = SocialProfile(player)
		if reason then
			Reply(player, "VisitPlot", false, reason)
			return
		end
		if not Allow(player.UserId, "plot", 4, 10) then
			Reply(player, "VisitPlot", false, "Attends avant de visiter un plot.")
			return
		end
		if not Social.IsValidUserId(ownerUserId) then
			Reply(player, "VisitPlot", false, "Plot invalide.")
			return
		end
		local owner = Players:GetPlayerByUserId(ownerUserId)
		if not owner or (owner ~= player and not FriendOf(player, ownerUserId)) then
			Reply(player, "VisitPlot", false, "Ce plot n'est pas visitable.")
			return
		end
		if not worldService or not worldService:GetPlot(ownerUserId) then
			Reply(player, "VisitPlot", false, "Le plot n'est pas disponible.")
			return
		end
		-- Aucun remote d'édition n'est exposé : la visite est explicitement lecture seule.
		Reply(player, "VisitPlot", true, nil, { ReadOnly = true, OwnerUserId = ownerUserId })
	end)
end

return FriendRegistry
