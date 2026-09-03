--!strict

local LiveOps = {}

export type Definition = {
	Id: string,
	Kind: "Season" | "Event",
	StartAt: number,
	EndAt: number,
	Variant: string?,
	Modifiers: { [string]: number }?,
	Rewards: { [string]: any }?,
	Text: { [string]: string }?,
	Version: number,
	Enabled: boolean,
}

-- Les dates restent des décisions de lancement : 0/infini signifie "catalogue prêt, inactif par défaut".
local all: { Definition } = {}
LiveOps.All = all

local byId: { [string]: Definition } = {}

function LiveOps.Validate(definition: any): boolean
	return type(definition) == "table"
		and type(definition.Id) == "string"
		and definition.Id ~= ""
		and (definition.Kind == "Season" or definition.Kind == "Event")
		and type(definition.Version) == "number"
		and definition.Version >= 1
		and type(definition.StartAt) == "number"
		and type(definition.EndAt) == "number"
		and definition.EndAt > definition.StartAt
		and type(definition.Enabled) == "boolean"
end

function LiveOps.Register(definition: Definition): boolean
	if not LiveOps.Validate(definition) or byId[definition.Id] then
		return false
	end
	byId[definition.Id] = definition
	table.insert(all, definition)
	return true
end

function LiveOps.Get(id: string): Definition?
	return byId[id]
end

function LiveOps.IsActive(definition: Definition, now: number): boolean
	return definition.Enabled and now >= definition.StartAt and now < definition.EndAt
end

function LiveOps.ActiveAt(now: number): { Definition }
	local active = {}
	for _, definition in all do
		if LiveOps.IsActive(definition, now) then
			table.insert(active, definition)
		end
	end
	return active
end

return LiveOps
