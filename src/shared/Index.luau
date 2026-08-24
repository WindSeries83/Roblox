local Config = require(script.Parent.Config)
local Species = require(script.Parent.Data.Species)
local Gameplay = require(script.Parent.Gameplay)

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

-- Catalogue pokédex : toutes les espèces, triées par famille puis rang desc puis nom.
-- Futur-proof : toute espèce ajoutée à Species apparaît seule ici.
function Index.Catalog(): { any }
	local catalog = {}
	for speciesId, def in Species do
		table.insert(catalog, {
			SpeciesId = speciesId,
			Name = def.Name,
			Rarity = def.Rarity,
			Family = def.Family,
		})
	end
	table.sort(catalog, function(a, b)
		if a.Family ~= b.Family then
			return a.Family < b.Family
		end
		local ra, rb = Gameplay.RarityRank(a.Rarity), Gameplay.RarityRank(b.Rarity)
		if ra ~= rb then
			return ra > rb
		end
		return a.Name < b.Name
	end)
	return catalog
end

-- État pokédex d'une espèce : owned si le joueur possède la créature,
-- sinon discovered si au moins une entrée d'index existe, sinon unknown.
function Index.EntryState(entries: { [string]: true }, speciesId: string, creatures: { any }?): string
	if creatures then
		for _, creature in creatures do
			if creature.SpeciesId == speciesId then
				return "owned"
			end
		end
	end
	local prefix = `{speciesId}|`
	for key in entries do
		if key:sub(1, #prefix) == prefix then
			return "discovered"
		end
	end
	return "unknown"
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
