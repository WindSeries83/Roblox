local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local SessionLuck = {}

local joins: { [Player]: number } = {}

function SessionLuck.Compute(elapsedHours: number): number
	if elapsedHours <= 0 then
		return 0
	end
	return math.min(Config.SESSION_LUCK_MAX, elapsedHours * Config.SESSION_LUCK_PER_HOUR)
end

function SessionLuck.For(player: Player): number
	local join = joins[player]
	if not join then
		return 0
	end
	return SessionLuck.Compute(math.floor((os.time() - join) / 3600))
end

function SessionLuck:Init(_container)
	for _, player in Players:GetPlayers() do
		joins[player] = os.time()
	end
	Players.PlayerAdded:Connect(function(player)
		joins[player] = os.time()
	end)
	Players.PlayerRemoving:Connect(function(player)
		joins[player] = nil
	end)
end

return SessionLuck
