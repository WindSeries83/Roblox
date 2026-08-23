local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)

-- Bonus meute (bible §4.C) : compte les amis présents dans le serveur.
local PackService = {}

local counts: { [number]: number } = {}

function PackService:Count(player: Player): number
	return counts[player.UserId] or 0
end

local function Recount()
	local list = Players:GetPlayers()
	for _, player in list do
		local count = 0
		for _, other in list do
			if other ~= player and player:IsFriendsWith(other.UserId) then
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
			if player ~= newcomer and player:IsFriendsWith(newcomer.UserId) then
				Net.QuestsSync:FireClient(player, {
					Notice = { Type = "FriendJoined", Name = newcomer.Name },
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
