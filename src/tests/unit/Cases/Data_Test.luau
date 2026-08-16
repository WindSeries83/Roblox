return function(t)
	local expect = t.expect
	local Species = require(game.ReplicatedStorage.Shared.Data.Species)
	local Rarities = require(game.ReplicatedStorage.Shared.Data.Rarities)
	local Mutations = require(game.ReplicatedStorage.Shared.Data.Mutations)
	local Config = require(game.ReplicatedStorage.Shared.Config)

	-- The P1 roster has exactly ten species.
	t.test("species list has exactly the P1 count", function()
		local count = 0
		for _ in Species do
			count += 1
		end
		expect.equal(count, 10)
	end)

	-- Every species references a known rarity with positive stats.
	t.test("every species references a known rarity with positive stats", function()
		for _, def in Species do
			expect.truthy(Rarities[def.Rarity] ~= nil)
			expect.truthy(def.BaseRate > 0)
			expect.truthy(def.BasePower > 0)
			expect.truthy(type(def.Name) == "string" and #def.Name > 0)
		end
	end)

	-- Each of the three P1 rarities has at least one species.
	t.test("every P1 rarity has at least one species", function()
		local present = { Common = 0, Uncommon = 0, Rare = 0 }
		for _, def in Species do
			if present[def.Rarity] ~= nil then
				present[def.Rarity] += 1
			end
		end
		expect.truthy(present.Common > 0)
		expect.truthy(present.Uncommon > 0)
		expect.truthy(present.Rare > 0)
	end)

	-- Rarity order lists every rarity exactly once.
	t.test("rarity order lists all rarities exactly once", function()
		expect.equal(#Rarities.ORDER, 8)
		local seen = {}
		for _, id in Rarities.ORDER do
			expect.truthy(Rarities[id] ~= nil)
			expect.falsy(seen[id])
			seen[id] = true
		end
		for id, value in Rarities do
			if type(id) == "string" and type(value) == "table" and id ~= "ORDER" then
				expect.truthy(seen[id])
			end
		end
	end)

	-- Mutation order lists every mutation exactly once.
	t.test("mutation order lists all mutations exactly once", function()
		expect.equal(#Mutations.ORDER, 6)
		local seen = {}
		for _, id in Mutations.ORDER do
			expect.truthy(Mutations[id] ~= nil)
			expect.falsy(seen[id])
			seen[id] = true
		end
		for id, value in Mutations do
			if type(id) == "string" and type(value) == "table" and id ~= "ORDER" then
				expect.truthy(seen[id])
			end
		end
	end)

	-- Egg rarity tables use positive weights on known rarities.
	t.test("egg rarity tables use positive weights on known rarities", function()
		for tier, weights in Config.EGG_RARITY_WEIGHTS do
			expect.truthy(Config.EGG_PRICES[tier] ~= nil)
			for rarity, weight in weights do
				expect.truthy(Rarities[rarity] ~= nil)
				expect.truthy(weight > 0)
			end
		end
	end)

	-- Mutation weights use known mutations or None.
	t.test("mutation weights use known mutations or None", function()
		for mutation, weight in Config.MUTATION_WEIGHTS do
			expect.truthy(mutation == "None" or Mutations[mutation] ~= nil)
			expect.truthy(weight > 0)
		end
	end)

	-- Rift egg weights use purchasable tiers.
	t.test("rift egg weights use purchasable tiers", function()
		for tier, weight in Config.RIFT_EGG_WEIGHTS do
			expect.truthy(Config.EGG_PRICES[tier] ~= nil)
			expect.truthy(weight > 0)
		end
	end)

	-- The announce threshold is a known rarity.
	t.test("announce threshold is a known rarity", function()
		expect.truthy(Rarities[Config.ANNOUNCE_MIN_RARITY] ~= nil)
	end)
end
