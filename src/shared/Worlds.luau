--!strict

local Worlds = {}

Worlds.BOSS_STAGE = 6

export type Stage = {
	Index: number,
	Template: "Wave" | "Choice" | "Elite",
	Reward: { [string]: number },
}

export type Rush = {
	TargetSeconds: number,
	Reward: { [string]: number },
}

export type Boss = {
	SpeciesId: string,
	Reward: { [string]: number },
}

export type World = {
	Id: string,
	Name: string,
	RegionName: string,
	RequiredStars: number,
	PreviousWorld: string?,
	Stages: { Stage },
	Boss: Boss,
	Rush: Rush,
}

local function Stages(rewards: { number }): { Stage }
	return {
		{ Index = 1, Template = "Wave", Reward = { Essence = rewards[1] } },
		{ Index = 2, Template = "Choice", Reward = { Essence = rewards[2] } },
		{ Index = 3, Template = "Elite", Reward = { Essence = rewards[3] } },
		{ Index = 4, Template = "Wave", Reward = { Essence = rewards[4] } },
		{ Index = 5, Template = "Elite", Reward = { Essence = rewards[5] } },
	}
end

Worlds.All = {
	{
		Id = "TwilightGrove",
		Name = "Bosquet du Crépuscule",
		RegionName = "TwilightGrove",
		RequiredStars = 0,
		Stages = Stages({ 100, 125, 175, 225, 300 }),
		Boss = { SpeciesId = "PondSentinel", Reward = { Essence = 500 } },
		Rush = { TargetSeconds = 180, Reward = { Essence = 750 } },
	},
	{
		Id = "AshForge",
		Name = "Fournaise de Cendre",
		RegionName = "AshForge",
		RequiredStars = 1,
		PreviousWorld = "TwilightGrove",
		Stages = Stages({ 250, 325, 450, 600, 800 }),
		Boss = { SpeciesId = "EmberColossus", Reward = { Essence = 1500 } },
		Rush = { TargetSeconds = 240, Reward = { Essence = 2250 } },
	},
	{
		Id = "GalePeaks",
		Name = "Cimes des Bourrasques",
		RegionName = "GalePeaks",
		RequiredStars = 2,
		PreviousWorld = "AshForge",
		Stages = Stages({ 700, 900, 1250, 1650, 2200 }),
		Boss = { SpeciesId = "AuroraLeviathan", Reward = { Essence = 4500 } },
		Rush = { TargetSeconds = 300, Reward = { Essence = 6750 } },
	},
	{
		Id = "NyxAbyss",
		Name = "Abîme de Nyx",
		RegionName = "NyxAbyss",
		RequiredStars = 3,
		PreviousWorld = "GalePeaks",
		Stages = Stages({ 1800, 2300, 3200, 4200, 5600 }),
		Boss = { SpeciesId = "NyxWarden", Reward = { Essence = 12000 } },
		Rush = { TargetSeconds = 360, Reward = { Essence = 18000 } },
	},
}

local byId: { [string]: World } = {}
for _, world in Worlds.All do
	byId[world.Id] = world
end

function Worlds.Get(id: string): World?
	return byId[id]
end

function Worlds.NextStage(progress: { [string]: any }?, worldId: string): number?
	local state = if progress then progress[worldId] else nil
	if state and state.BossDefeated == true then
		return nil
	end
	local highest = if state and type(state.HighestStage) == "number" then state.HighestStage else 0
	return math.clamp(math.floor(highest) + 1, 1, Worlds.BOSS_STAGE)
end

function Worlds.CanEnter(progress: { [string]: any }?, stars: number, worldId: string): boolean
	local world = byId[worldId]
	if not world or type(stars) ~= "number" or stars < world.RequiredStars then
		return false
	end
	if not world.PreviousWorld then
		return true
	end
	local previous = if progress then progress[world.PreviousWorld] else nil
	return previous ~= nil and previous.BossDefeated == true
end

function Worlds.Validate(): boolean
	local templates = { "Wave", "Choice", "Elite", "Wave", "Elite" }
	for _, world in Worlds.All do
		if type(world.Id) ~= "string" or type(world.Name) ~= "string" or type(world.RegionName) ~= "string" then
			return false
		end
		if #world.Stages ~= 5 or type(world.Boss.SpeciesId) ~= "string" then
			return false
		end
		for index, stage in world.Stages do
			if stage.Index ~= index or stage.Template ~= templates[index] or stage.Reward.Essence <= 0 then
				return false
			end
		end
		if world.Boss.Reward.Essence <= 0 or world.Rush.TargetSeconds <= 0 or world.Rush.Reward.Essence <= 0 then
			return false
		end
	end
	return true
end

function Worlds.RecordVictory(progress: { [string]: any }, worldId: string, stage: number): boolean
	if not byId[worldId] or type(stage) ~= "number" then
		return false
	end
	stage = math.clamp(math.floor(stage), 1, Worlds.BOSS_STAGE)
	local state = progress[worldId]
	if type(state) ~= "table" then
		state = { HighestStage = 0, BossDefeated = false }
		progress[worldId] = state
	end
	local changed = stage > (state.HighestStage or 0) or (stage == Worlds.BOSS_STAGE and state.BossDefeated ~= true)
	state.HighestStage = math.max(state.HighestStage or 0, stage)
	if stage == Worlds.BOSS_STAGE then
		state.BossDefeated = true
	end
	return changed
end

return Worlds
