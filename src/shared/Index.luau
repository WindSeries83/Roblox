local Config = require(script.Parent.Config)
local Species = require(script.Parent.Data.Species)

local Index = {}

function Index.Key(speciesId: string, rarity: string, mutation: any): string
	return `{speciesId}|{rarity}|{tostring(mutation)}`
end

function Index.Register(entries: { [string]: true }, speciesId: string, rarity: string, mutation: any)
	entries[Index.Key(speciesId, rarity, mutation)] = true
end

function Index.Has(entries: { [string]: true }, speciesId: string, rarity: string, mutation: any): boolean
	return entries[Index.Key(speciesId, rarity, mutation)] == true
end

local function FamiliesBySpecies()
	local families: { [string]: { string } } = {}
	for speciesId, def in Species do
		if not families[def.Family] then
			families[def.Family] = {}
		end
		table.insert(families[def.Family], speciesId)
	end
	return families
end

function Index.FamilyCompletions(entries: { [string]: true }): { [string]: boolean }
	local completions: { [string]: boolean } = {}
	for family, members in FamiliesBySpecies() do
		local complete = true
		for _, speciesId in members do
			local seen = false
			for key in entries do
				if key:match(`^{speciesId}|`) then
					seen = true
					break
				end
			end
			if not seen then
				complete = false
				break
			end
		end
		if complete then
			completions[family] = true
		end
	end
	return completions
end

function Index.ComputeMult(entries: { [string]: true }): number
	local mult = 1
	local count = 0
	for _ in entries do
		count += 1
	end
	mult *= 1 + count * Config.INDEX_ENTRY_BONUS

	for _ in Index.FamilyCompletions(entries) do
		mult *= 1 + Config.INDEX_FAMILY_BONUS
	end

	return mult
end

return Index
