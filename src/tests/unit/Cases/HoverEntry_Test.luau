return function(t)
	local expect = t.expect
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Rarities = require(ReplicatedStorage.Shared.Data.Rarities)
	local Mutations = require(ReplicatedStorage.Shared.Data.Mutations)
	local HoverCard = require(game.StarterPlayer.StarterPlayerScripts.HoverCard)

	t.test("complete creature entry builds four lines", function()
		local lines = HoverCard.BuildLines({
			SpeciesId = "Riftling",
			Rarity = "Epic",
			Mutation = "Golden",
			Level = 7,
			Power = 42.7,
			SuggestedPrice = 1234,
		})
		expect.equal(#lines, 4)
		expect.equal(lines[1].Text, "Riftling · Épique")
		expect.truthy(lines[1].Color == Rarities.Epic.Color)
		expect.equal(lines[2].Text, "Doré ×15")
		expect.truthy(lines[2].Color == Mutations.Golden.Color)
		expect.equal(lines[3].Text, "Niv. 7 · Puissance 42")
		expect.equal(lines[4].Text, "Valeur ≈ 1234 Essence")
	end)

	t.test("entry without mutation has no mutation line", function()
		local lines = HoverCard.BuildLines({
			SpeciesId = "Riftling",
			Rarity = "Rare",
			Mutation = false,
			Level = 3,
			Power = 12,
			SuggestedPrice = 500,
		})
		expect.equal(#lines, 3)
		for _, line in lines do
			expect.falsy(string.find(line.Text, "×", 1, true))
		end
	end)

	t.test("minimal index entry shows species and rarity only", function()
		local lines = HoverCard.BuildLines({ SpeciesId = "Riftling", Rarity = "Secret" })
		expect.equal(#lines, 1)
		expect.equal(lines[1].Text, "Riftling · Secret")
		expect.truthy(lines[1].Color == Rarities.Secret.Color)
	end)

	t.test("mutation false and nil produce identical lines", function()
		local function build(mutation)
			return HoverCard.BuildLines({
				SpeciesId = "Riftling",
				Rarity = "Rare",
				Mutation = mutation,
				Level = 2,
				Power = 9,
			})
		end
		expect.deepEqual(build(false), build(nil))
	end)

	t.test("unknown species and rarity fall back gracefully", function()
		local lines = HoverCard.BuildLines({ SpeciesId = "Inconnu", Rarity = "Bizarre" })
		expect.equal(#lines, 1)
		expect.equal(lines[1].Text, "Inconnu · Bizarre")
		expect.truthy(lines[1].Color == Color3.fromRGB(235, 235, 245))
	end)

	t.test("discovered flag appends a discovered line", function()
		local lines = HoverCard.BuildLines({ SpeciesId = "Riftling", Rarity = "Rare", Discovered = true })
		expect.equal(#lines, 2)
		expect.equal(lines[2].Text, "Découvert")
	end)

	t.test("fractional price is floored", function()
		local lines = HoverCard.BuildLines({ SpeciesId = "Riftling", Rarity = "Rare", SuggestedPrice = 99.9 })
		expect.equal(lines[2].Text, "Valeur ≈ 99 Essence")
	end)
end
