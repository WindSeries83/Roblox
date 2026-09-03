local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local FeatureUnlocks = require(ReplicatedStorage.Shared.FeatureUnlocks)

-- Bonus meute (bible §4.C) : compte les amis présents dans le serveur.
local PackService = {}

local counts: { [number]: number } = {}
local saveService

local function AreFriends(player: Player, otherUserId: number): boolean
	local ok, result = pcall(function()
		return player:IsFriendsWith(otherUserId)
	end)
	return ok and result == true
end

function PackService:Init(container)
	saveService = container:Get("SaveService")
end

function PackService:Count(player: Player): number
	local profile = saveService and saveService:GetProfile(player)
	if not profile or not FeatureUnlocks.For(profile.Data).Social then
		return 0
	end
	return counts[player.UserId] or 0
end

local function Recount()
	local list = Players:GetPlayers()
	for _, player in list do
		local count = 0
		for _, other in list do
			if other ~= player and AreFriends(player, other.UserId) then
				count += 1
			end
		end
		counts[player.UserId] = count
	end
	for userId in counts do
		local stillHere = false
		for _, player in list do
			if player.UserId == userId then
				stillHere = true
				break
			end
		end
		if not stillHere then
			counts[userId] = nil
		end
	end
end

function PackService:Start()
	Recount()
	Players.PlayerAdded:Connect(function(newcomer)
		for _, player in Players:GetPlayers() do
			local profile = saveService and saveService:GetProfile(player)
			if
				player ~= newcomer
				and profile
				and FeatureUnlocks.For(profile.Data).Social
				and AreFriends(player, newcomer.UserId)
			then
				Net.QuestsSync:FireClient(player, {
					Notice = { Type = "FriendJoined", Name = newcomer.DisplayName },
				})
			end
		end
		task.defer(Recount)
	end)
	Players.PlayerRemoving:Connect(function()
		task.defer(Recount)
	end)
	task.spawn(function()
		while true do
			task.wait(30)
			Recount()
		end
	end)
end

return PackService
