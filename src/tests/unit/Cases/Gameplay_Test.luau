return function(t)
	local expect = t.expect
	local Gameplay = require(game.ReplicatedStorage.Shared.Gameplay)
	local Species = require(game.ReplicatedStorage.Shared.Data.Species)
	local Rarities = require(game.ReplicatedStorage.Shared.Data.Rarities)
	local Mutations = require(game.ReplicatedStorage.Shared.Data.Mutations)
	local Config = require(game.ReplicatedStorage.Shared.Config)

	-- WeightedRoll returns the only key of a single-key table.
	t.test("single-key weights always return that key", function()
		expect.equal(Gameplay.WeightedRoll({ Only = 5 }), "Only")
	end)

	-- WeightedRoll returns nil for empty weights.
	t.test("empty weights return nil", function()
		expect.equal(Gameplay.WeightedRoll({}), nil)
	end)

	-- WeightedRoll returns nil for non-table input.
	t.test("non-table weights return nil", function()
		expect.equal(Gameplay.WeightedRoll(nil), nil)
	end)

	-- WeightedRoll results always belong to the weights table.
	t.test("result is always a key of the weights", function()
		local weights = { A = 1, B = 1, C = 1 }
		for _ = 1, 100 do
			local key = Gameplay.WeightedRoll(weights)
			expect.truthy(weights[key] ~= nil)
		end
	end)

	-- CommonEgg rolls a rarity that the tier's weight table contains.
	t.test("CommonEgg rolls a known rarity for that tier", function()
		local weights = Config.EGG_RARITY_WEIGHTS.CommonEgg
		for _ = 1, 100 do
			local roll = Gameplay.RollEgg("CommonEgg")
			expect.truthy(weights[roll.Rarity] ~= nil)
		end
	end)

	-- The rolled species belongs to the rolled rarity.
	t.test("rolled species belongs to the rolled rarity", function()
		for _ = 1, 50 do
			local roll = Gameplay.RollEgg("UncommonEgg")
			expect.equal(Species[roll.SpeciesId].Rarity, roll.Rarity)
		end
	end)

	-- Mutation is either false or a configured mutation id.
	t.test("mutation is false or a configured mutation", function()
		for _ = 1, 100 do
			local roll = Gameplay.RollEgg("CommonEgg")
			expect.truthy(roll.Mutation == false or Mutations[roll.Mutation] ~= nil)
		end
	end)

	-- Rolling an unknown tier fails predictably.
	t.test("unknown tier throws", function()
		expect.throws(function()
			Gameplay.RollEgg("NotATier")
		end)
	end)

	-- A forced single-key weight table yields that rarity every time.
	t.test("override weights force a single rarity", function()
		for _ = 1, 50 do
			local roll = Gameplay.RollEgg("CommonEgg", nil, { Common = 100 })
			expect.equal(roll.Rarity, "Common")
		end
	end)

	-- The first-hatch pity weights only produce keys of that table.
	t.test("first hatch weights only roll their own rarities", function()
		local weights = Config.FIRST_HATCH_WEIGHTS
		expect.truthy(weights ~= nil)
		for _ = 1, 100 do
			local roll = Gameplay.RollEgg("CommonEgg", nil, weights)
			expect.truthy(weights[roll.Rarity] ~= nil)
		end
	end)

	-- Power scales with rarity and mutation multipliers (Moonhowl 24 x Rare 2.5 x Frost 5).
	t.test("power scales with rarity and mutation multipliers", function()
		local creature = Gameplay.CreateCreature("Rare", "Moonhowl", "Frost")
		expect.equal(creature.Power, 300)
		expect.equal(creature.Level, 1)
		expect.truthy(type(creature.Id) == "string" and #creature.Id > 0)
	end)

	-- A creature without mutation uses only the rarity multiplier.
	t.test("creature without mutation uses rarity multiplier only", function()
		local creature = Gameplay.CreateCreature("Common", "Riftling", false)
		expect.equal(creature.Power, 8)
	end)

	-- An empty creature list yields zero rate.
	t.test("empty creature list has zero rate", function()
		expect.equal(Gameplay.ComputeRate({}), 0)
	end)

	-- Rate includes the base essence rate (Riftling 1.0 x Common 1 x base 0.5).
	t.test("single common creature rate equals base rate times essence base", function()
		local rate = Gameplay.ComputeRate({ { SpeciesId = "Riftling", Rarity = "Common", Mutation = false } })
		expect.near(rate, 0.5)
	end)

	-- Rate multiplies rarity, mutation and essence base (FrostMite 1.6 x Uncommon 2 x Frost 5 x base 0.5).
	t.test("rate multiplies rarity mutation and essence base", function()
		local rate = Gameplay.ComputeRate({ { SpeciesId = "FrostMite", Rarity = "Uncommon", Mutation = "Frost" } })
		expect.near(rate, 8)
	end)

	-- Unknown species entries are skipped without error.
	t.test("unknown species is skipped without error", function()
		local rate = Gameplay.ComputeRate({ { SpeciesId = "Nope", Rarity = "Common", Mutation = false } })
		expect.equal(rate, 0)
	end)

	-- Rarity ranks follow the declared rarity order.
	t.test("rarity ranks follow the rarity order", function()
		expect.equal(Gameplay.RarityRank("Common"), 1)
		expect.equal(Gameplay.RarityRank("Rare"), 3)
		expect.equal(Gameplay.RarityRank("Secret"), 8)
	end)

	-- Unknown rarities have rank zero.
	t.test("unknown rarity has rank zero", function()
		expect.equal(Gameplay.RarityRank("Nope"), 0)
	end)

	-- Every rarity in the order table has a known definition.
	t.test("rarity order matches definitions", function()
		for _, id in Rarities.ORDER do
			expect.truthy(Rarities[id] ~= nil)
		end
	end)

	t.test("ConsumeOnce : premier appel true, replay false", function()
		local map = {}
		expect.truthy(Gameplay.ConsumeOnce(map, "a_b"))
		expect.falsy(Gameplay.ConsumeOnce(map, "a_b"))
		expect.truthy(Gameplay.ConsumeOnce(map, "a_c"))
	end)
end
