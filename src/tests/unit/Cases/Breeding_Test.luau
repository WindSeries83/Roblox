return function(t)
	local expect = t.expect
	local Breeding = require(game.ReplicatedStorage.Shared.Breeding)
	local Config = require(game.ReplicatedStorage.Shared.Config)

	local function MakeCreature(props)
		local creature = {
			Id = "test",
			SpeciesId = "Moonhowl",
			Rarity = "Rare",
			Mutation = false,
			Generation = 1,
		}
		for key, value in props do
			creature[key] = value
		end
		return creature
	end

	-- Different species cannot breed.
	t.test("different species cannot breed", function()
		local a = MakeCreature({ Id = "a" })
		local b = MakeCreature({ Id = "b", SpeciesId = "Riftling" })
		local ok, reason = Breeding.CanBreed(a, b)
		expect.falsy(ok)
		expect.equal(reason, "espèces différentes")
	end)

	-- A creature cannot breed with itself.
	t.test("a creature cannot breed with itself", function()
		local a = MakeCreature({ Id = "a" })
		local ok, _ = Breeding.CanBreed(a, a)
		expect.falsy(ok)
	end)

	-- Same species creatures can breed.
	t.test("same species creatures can breed", function()
		local a = MakeCreature({ Id = "a" })
		local b = MakeCreature({ Id = "b" })
		expect.truthy(Breeding.CanBreed(a, b))
	end)

	-- The child keeps the species and inherits a parent rarity.
	t.test("child keeps species and inherits a parent rarity", function()
		local a = MakeCreature({ Id = "a", Rarity = "Rare" })
		local b = MakeCreature({ Id = "b", Rarity = "Epic" })
		for _ = 1, 50 do
			local child = Breeding.RollChild(a, b)
			expect.equal(child.SpeciesId, "Moonhowl")
			expect.truthy(child.Rarity == "Rare" or child.Rarity == "Epic" or child.Rarity == "Legendary")
		end
	end)

	-- The generation increments over the parents.
	t.test("generation increments over the parents", function()
		local a = MakeCreature({ Id = "a", Generation = 2 })
		local b = MakeCreature({ Id = "b", Generation = 4 })
		local child = Breeding.RollChild(a, b)
		expect.equal(child.Generation, 5)
		expect.equal(child.Parents.Father, "a")
		expect.equal(child.Parents.Mother, "b")
	end)

	-- Shared mutation is inherited most of the time.
	t.test("shared mutation is inherited most of the time", function()
		local a = MakeCreature({ Id = "a", Mutation = "Frost" })
		local b = MakeCreature({ Id = "b", Mutation = "Frost" })
		local inherited = 0
		for _ = 1, 200 do
			if Breeding.RollChildMutation(a, b) == "Frost" then
				inherited += 1
			end
		end
		expect.truthy(inherited > 100)
	end)

	-- Two mutationless parents cannot inherit a mutation, but may roll a new one.
	t.test("mutationless parents roll from the breeding weights", function()
		local a = MakeCreature({ Id = "a" })
		local b = MakeCreature({ Id = "b" })
		local Mutations = require(game.ReplicatedStorage.Shared.Data.Mutations)
		for _ = 1, 100 do
			local mutation = Breeding.RollChildMutation(a, b)
			expect.truthy(mutation == false or Mutations[mutation] ~= nil)
		end
	end)

	-- The breeding cost and cooldown exist.
	t.test("breeding cost and cooldown exist", function()
		expect.truthy(Config.BREED_COST > 0)
		expect.truthy(Config.BREED_COOLDOWN > 0)
	end)

	t.test("breeding request validation rejects non-string ids", function()
		local ok, reason = Breeding.ValidateRequest(123, "b")
		expect.falsy(ok)
		expect.equal(reason, "parents invalides")
	end)
end
