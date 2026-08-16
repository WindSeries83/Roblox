local Config = require(script.Parent.Config)
local Gameplay = require(script.Parent.Gameplay)

local Breeding = {}

function Breeding.CanBreed(a: any, b: any): (boolean, string?)
	if not a or not b then
		return false, "créatures manquantes"
	end
	if a.Id == b.Id then
		return false, "même créature"
	end
	if a.SpeciesId ~= b.SpeciesId then
		return false, "espèces différentes"
	end
	return true
end

function Breeding.RollChildRarity(a: any, b: any): string
	return if Random.new():NextNumber() < 0.5 then a.Rarity else b.Rarity
end

function Breeding.RollChildMutation(a: any, b: any)
	local aMut = a.Mutation
	local bMut = b.Mutation

	if aMut ~= false and aMut == bMut then
		if Random.new():NextNumber() < Config.BREED_INHERIT_SAME then
			return aMut
		end
	elseif aMut ~= false and bMut ~= false then
		local roll = Random.new():NextNumber()
		if roll < Config.BREED_INHERIT_ONE then
			return aMut
		end
		if roll < Config.BREED_INHERIT_ONE * 2 then
			return bMut
		end
	elseif aMut ~= false or bMut ~= false then
		local single = if aMut ~= false then aMut else bMut
		if Random.new():NextNumber() < Config.BREED_INHERIT_SINGLE then
			return single
		end
	end

	local newRoll = Gameplay.WeightedRoll(Config.BREED_MUTATION_WEIGHTS)
	return if newRoll == "None" then false else newRoll
end

function Breeding.RollChild(a: any, b: any)
	return {
		SpeciesId = a.SpeciesId,
		Rarity = Breeding.RollChildRarity(a, b),
		Mutation = Breeding.RollChildMutation(a, b),
		Parents = {
			Father = a.Id,
			Mother = b.Id,
		},
		Generation = math.max(a.Generation or 1, b.Generation or 1) + 1,
	}
end

return Breeding
