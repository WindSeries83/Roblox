return function(t)
	local expect = t.expect
	local Lineage = require(game.ReplicatedStorage.Shared.BreedingLineage)

	t.test("creates and validates a lineage", function()
		local lineage = Lineage.Create("father", "mother", 2, { "Shadow", "Shadow", 4 })
		expect.truthy(lineage)
		expect.equal(#lineage.InheritedMutations, 1)
		expect.truthy(Lineage.Validate(lineage))
	end)

	t.test("keeps legacy parents compatible and rejects cycles", function()
		local lineage =
			Lineage.FromCreature({ Parents = { Father = "a", Mother = "b" }, Generation = 2, Mutation = false })
		expect.truthy(lineage)
		expect.falsy(Lineage.Validate(Lineage.Create("a", "b", 2, {}), {
			a = { Parents = { Father = "b" } },
			b = { Parents = { Father = "a" } },
		}))
	end)
end
