--!strict

local Config = require(script.Parent.Config)
local Gameplay = require(script.Parent.Gameplay)

local RotatingEgg = {}

local function WindowSeconds(): number
	return Config.ROTATING_EGG_ROTATION_SECONDS
end

local function Definitions(): { any }
	return Config.ROTATING_EGGS
end

function RotatingEgg.ValidateDefinition(definition: any): boolean
	return type(definition) == "table"
		and type(definition.Id) == "string"
		and definition.Id ~= ""
		and type(definition.Name) == "string"
		and definition.Name ~= ""
		and type(definition.Tier) == "string"
		and Config.EGG_PRICES[definition.Tier] ~= nil
		and Config.EGG_RARITY_WEIGHTS[definition.Tier] ~= nil
end

function RotatingEgg.RotationIndex(now: number): number
	return math.floor(now / WindowSeconds())
end

function RotatingEgg.GetActive(now: number): any?
	if type(now) ~= "number" or #Definitions() == 0 or WindowSeconds() <= 0 then
		return nil
	end
	local index = RotatingEgg.RotationIndex(now)
	local definition = Definitions()[index % #Definitions() + 1]
	if not RotatingEgg.ValidateDefinition(definition) then
		return nil
	end
	return {
		Id = definition.Id,
		Name = definition.Name,
		Tier = definition.Tier,
		WindowIndex = index,
		StartsAt = index * WindowSeconds(),
		EndsAt = (index + 1) * WindowSeconds(),
	}
end

function RotatingEgg.Snapshot(now: number, pity: number?): any?
	local active = RotatingEgg.GetActive(now)
	if not active then
		return nil
	end
	local rates = Config.EGG_RARITY_WEIGHTS[active.Tier]
	return {
		Id = active.Id,
		Name = active.Name,
		Tier = active.Tier,
		WindowIndex = active.WindowIndex,
		StartsAt = active.StartsAt,
		EndsAt = active.EndsAt,
		SecondsRemaining = math.max(0, active.EndsAt - now),
		Price = Config.EGG_PRICES[active.Tier],
		Rates = Gameplay.DropRates(rates),
		Pity = math.max(0, math.floor(pity or 0)),
		PityMax = Config.PITY_THRESHOLD,
		LuckCap = Config.LUCK_HARD_CAP,
	}
end

function RotatingEgg.ValidateSnapshot(snapshot: any): boolean
	return type(snapshot) == "table"
		and type(snapshot.Id) == "string"
		and snapshot.Id ~= ""
		and type(snapshot.Name) == "string"
		and snapshot.Name ~= ""
		and type(snapshot.Tier) == "string"
		and RotatingEgg.ValidateDefinition({ Id = snapshot.Id, Name = snapshot.Name, Tier = snapshot.Tier })
		and type(snapshot.WindowIndex) == "number"
		and snapshot.WindowIndex == math.floor(snapshot.WindowIndex)
		and type(snapshot.StartsAt) == "number"
		and type(snapshot.EndsAt) == "number"
		and snapshot.EndsAt > snapshot.StartsAt
		and type(snapshot.SecondsRemaining) == "number"
		and snapshot.SecondsRemaining >= 0
		and snapshot.SecondsRemaining <= snapshot.EndsAt - snapshot.StartsAt
		and type(snapshot.Price) == "number"
		and snapshot.Price >= 1
		and type(snapshot.Rates) == "table"
		and type(snapshot.Pity) == "number"
		and snapshot.Pity >= 0
		and type(snapshot.PityMax) == "number"
		and snapshot.Pity <= snapshot.PityMax
		and type(snapshot.LuckCap) == "number"
end

return RotatingEgg
