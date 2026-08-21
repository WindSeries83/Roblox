return function(t)
	local expect = t.expect
	local Ascension = require(game.ReplicatedStorage.Shared.Ascension)
	local Breeding = require(game.ReplicatedStorage.Shared.Breeding)
	local Config = require(game.ReplicatedStorage.Shared.Config)

	t.test("RollFrom ascends Common around 3 percent and never beyond Uncommon", function()
		local ascended = 0
		for _ = 1, 10000 do
			local rarity = Ascension.RollFrom("Common")
			expect.truthy(rarity == "Common" or rarity == "Uncommon")
			if rarity == "Uncommon" then
				ascended += 1
			end
		end
		expect.near(ascended / 10000, Config.ASCEND_CHANCE, 0.025)
	end)

	t.test("RollFrom caps UltraRare", function()
		for _ = 1, 100 do
			expect.equal(Ascension.RollFrom("UltraRare"), "UltraRare")
		end
	end)

	t.test("RollFrom never touches Secret", function()
		for _ = 1, 100 do
			expect.equal(Ascension.RollFrom("Secret"), "Secret")
		end
	end)

	t.test("RollFrom saturating luck guarantees next rank", function()
		for _ = 1, 50 do
			expect.equal(Ascension.RollFrom("Rare", 100), "Epic")
		end
	end)

	t.test("SecretTrigger full truth table", function()
		local combos = {
			{ "RareEgg", true, "T3", true },
			{ "RareEgg", true, "T2", false },
			{ "RareEgg", false, "T3", false },
			{ "RareEgg", false, "T2", false },
			{ "UncommonEgg", true, "T3", false },
			{ "UncommonEgg", false, "T3", false },
			{ "CommonEgg", true, "T3", false },
			{ "CommonEgg", false, "T1", false },
		}
		for _, combo in combos do
			expect.equal(Ascension.SecretTrigger(combo[1], combo[2], combo[3]), combo[4])
		end
	end)

	t.test("children of Rare parents never exceed Epic", function()
		local a = { Id = "a", SpeciesId = "Moonhowl", Rarity = "Rare", Mutation = false, Generation = 1 }
		local b = { Id = "b", SpeciesId = "Moonhowl", Rarity = "Rare", Mutation = false, Generation = 1 }
		for _ = 1, 200 do
			local child = Breeding.RollChild(a, b)
			expect.truthy(child.Rarity == "Rare" or child.Rarity == "Epic")
		end
	end)

	t.test("ascension config values exist", function()
		expect.equal(Config.ASCEND_CHANCE, 0.03)
		expect.equal(Config.RIFT_ASCEND_CHANCE, 0.08)
	end)
end
