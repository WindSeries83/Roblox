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
			{ "RareEgg", true, "T3", nil, true },
			{ "RareEgg", true, "T2", nil, false },
			{ "RareEgg", false, "T3", nil, false },
			{ "RareEgg", false, "T2", nil, false },
			{ "UncommonEgg", true, "T3", nil, false },
			{ "UncommonEgg", false, "T3", nil, false },
			{ "CommonEgg", true, "T3", nil, false },
			{ "CommonEgg", false, "T1", nil, false },
			-- Cas omen (arbre d'Étoiles) : élargit aux œufs Épiques et Légendaires.
			{ "RareEgg", true, "T3", true, true },
			{ "EpicEgg", true, "T3", true, true },
			{ "EpicEgg", true, "T3", false, false },
			{ "EpicEgg", true, "T3", nil, false },
			{ "LegendaryEgg", true, "T3", true, true },
			{ "LegendaryEgg", true, "T3", false, false },
			{ "LegendaryEgg", true, "T3", nil, false },
			{ "EpicEgg", false, "T3", true, false },
			{ "LegendaryEgg", false, "T3", true, false },
			{ "UncommonEgg", true, "T3", true, false },
		}
		for _, combo in combos do
			expect.equal(Ascension.SecretTrigger(combo[1], combo[2], combo[3], combo[4]), combo[5])
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
