return function(t)
	local expect = t.expect
	local Species = require(game.ReplicatedStorage.Shared.Data.Species)
	local Rarities = require(game.ReplicatedStorage.Shared.Data.Rarities)
	local Mutations = require(game.ReplicatedStorage.Shared.Data.Mutations)
	local Config = require(game.ReplicatedStorage.Shared.Config)
	local Worlds = require(game.ReplicatedStorage.Shared.Worlds)
	local validFamilies = { Feral = true, Wild = true, Mystic = true }
	local validRoles = { Digger = true, Gatherer = true, Guardian = true }

	t.test("species catalogue has exactly 30 entries", function()
		local count = 0
		for _ in Species do
			count += 1
		end
		expect.equal(count, 30)
	end)

	t.test("every species has valid identity, stats, family, role and world", function()
		local concepts = {}
		local worlds = {}
		for speciesId, def in Species do
			expect.truthy(type(speciesId) == "string" and speciesId ~= "")
			expect.truthy(Rarities[def.Rarity] ~= nil)
			expect.truthy(def.BaseRate > 0)
			expect.truthy(def.BasePower > 0)
			expect.truthy(type(def.Name) == "string" and #def.Name > 0)
			expect.truthy(validFamilies[def.Family] == true)
			expect.truthy(validRoles[def.Role] == true)
			expect.truthy(Worlds.Get(def.World) ~= nil)
			expect.truthy(type(def.Concept) == "string" and #def.Concept > 0)
			expect.falsy(concepts[def.Concept])
			concepts[def.Concept] = true
			worlds[def.World] = (worlds[def.World] or 0) + 1
		end
		for _, world in Worlds.All do
			expect.truthy((worlds[world.Id] or 0) > 0)
		end
	end)

	t.test("world bosses reference compatible catalogue species", function()
		for _, world in Worlds.All do
			local boss = Species[world.Boss.SpeciesId]
			expect.truthy(boss ~= nil)
			expect.equal(boss.World, world.Id)
		end
	end)

	t.test("species stats progress by rarity without an outlier", function()
		local previousMaxRate = 0
		local previousMaxPower = 0
		for _, rarity in Rarities.ORDER do
			local minRate, maxRate, minPower, maxPower
			for _, def in Species do
				if def.Rarity == rarity then
					minRate = math.min(minRate or def.BaseRate, def.BaseRate)
					maxRate = math.max(maxRate or def.BaseRate, def.BaseRate)
					minPower = math.min(minPower or def.BasePower, def.BasePower)
					maxPower = math.max(maxPower or def.BasePower, def.BasePower)
				end
			end
			if minRate then
				expect.truthy(minRate > previousMaxRate)
				expect.truthy(minPower > previousMaxPower)
				previousMaxRate = maxRate
				previousMaxPower = maxPower
			end
		end
	end)

	-- Every hatchable rarity has at least one species (UltraRare/Secret come from ascension, not species).
	t.test("every hatchable rarity has at least one species", function()
		local present = {}
		for _, def in Species do
			present[def.Rarity] = (present[def.Rarity] or 0) + 1
		end
		for rarity in Rarities do
			if type(rarity) == "string" and rarity ~= "ORDER" and rarity ~= "UltraRare" and rarity ~= "Secret" then
				expect.truthy((present[rarity] or 0) > 0)
			end
		end
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

	-- Egg rarity tables sum to 100 and only roll hatchable rarities.
	t.test("egg rarity tables sum to 100 and roll hatchable rarities", function()
		for _, weights in Config.EGG_RARITY_WEIGHTS do
			local total = 0
			for rarity, weight in weights do
				total += weight
				local found = false
				for _, def in Species do
					if def.Rarity == rarity then
						found = true
						break
					end
				end
				expect.truthy(found)
			end
			expect.near(total, 100, 0.01)
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

	-- Aucune table d'œuf achetable ne doit proposer Mythic (exclusif Faille).
	t.test("aucune table d'œuf achetable ne propose Mythic", function()
		for _tier, weights in Config.EGG_RARITY_WEIGHTS do
			expect.equal(weights.Mythic, nil)
		end
	end)

	-- The announce threshold is a known rarity.
	t.test("announce threshold is a known rarity", function()
		expect.truthy(Rarities[Config.ANNOUNCE_MIN_RARITY] ~= nil)
	end)
end
