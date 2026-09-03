--!strict

local BreedingLineage = {}

export type Lineage = {
	FatherId: string,
	MotherId: string,
	Generation: number,
	InheritedMutations: { string },
	Origin: "Breeding",
}

function BreedingLineage.Create(fatherId: any, motherId: any, generation: any, inherited: any): Lineage?
	if type(fatherId) ~= "string" or fatherId == "" or type(motherId) ~= "string" or motherId == "" then
		return nil
	end
	if fatherId == motherId or type(generation) ~= "number" or generation < 2 then
		return nil
	end
	local mutations = {}
	if type(inherited) == "table" then
		for _, mutation in inherited do
			if type(mutation) == "string" and mutation ~= "" and not table.find(mutations, mutation) then
				table.insert(mutations, mutation)
			end
		end
	end
	return {
		FatherId = fatherId,
		MotherId = motherId,
		Generation = math.floor(generation),
		InheritedMutations = mutations,
		Origin = "Breeding",
	}
end

function BreedingLineage.FromCreature(creature: any): Lineage?
	local parents = creature and creature.Parents
	if type(parents) ~= "table" then
		return nil
	end
	return BreedingLineage.Create(
		parents.Father,
		parents.Mother,
		creature.Generation,
		creature.Mutation and { creature.Mutation } or {}
	)
end

function BreedingLineage.Validate(lineage: any, known: { [string]: any }?): boolean
	if
		type(lineage) ~= "table"
		or type(lineage.FatherId) ~= "string"
		or type(lineage.MotherId) ~= "string"
		or lineage.FatherId == lineage.MotherId
		or type(lineage.Generation) ~= "number"
		or lineage.Generation < 2
		or lineage.Origin ~= "Breeding"
	then
		return false
	end
	if not known then
		return true
	end
	local visiting: { [string]: boolean } = {}
	local function reaches(id: string, target: string, depth: number): boolean
		if id == target then
			return true
		end
		if depth > 100 or visiting[id] then
			return false
		end
		local creature = known[id]
		local parents = creature and creature.Parents
		if type(parents) ~= "table" then
			return false
		end
		visiting[id] = true
		local found = (type(parents.Father) == "string" and reaches(parents.Father, target, depth + 1))
			or (type(parents.Mother) == "string" and reaches(parents.Mother, target, depth + 1))
		visiting[id] = nil
		return found
	end
	return not reaches(lineage.FatherId, lineage.MotherId, 0) and not reaches(lineage.MotherId, lineage.FatherId, 0)
end

return BreedingLineage
