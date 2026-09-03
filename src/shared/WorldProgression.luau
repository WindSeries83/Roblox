local Config = require(script.Parent.Config)

local WorldProgression = {}

function WorldProgression.SyncUnlocks(data: any)
	data.WorldUnlocks = data.WorldUnlocks or { World1 = true }
	for id, world in Config.WORLDS do
		if (data.Rebirths or 0) >= world.UnlockRebirths then
			data.WorldUnlocks[id] = true
		end
	end
	if not data.WorldUnlocks[data.CurrentWorld] then
		data.CurrentWorld = "World1"
	end
end

function WorldProgression.CanEnter(data: any, worldId: unknown): boolean
	return type(worldId) == "string" and Config.WORLDS[worldId] ~= nil and data.WorldUnlocks[worldId] == true
end

function WorldProgression.RecordRush(data: any, worldId: string, duration: number): boolean
	local rush = Config.WORLDS[worldId] and Config.WORLDS[worldId].Rush
	if not rush or duration > rush.TargetSeconds then
		return false
	end
	data.RushBest = data.RushBest or {}
	data.RushRewards = data.RushRewards or {}
	data.RushBest[worldId] = math.min(data.RushBest[worldId] or math.huge, duration)
	local first = data.RushRewards[worldId] ~= true
	data.RushRewards[worldId] = true
	return first
end

return WorldProgression
