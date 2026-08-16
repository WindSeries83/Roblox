return function(t)
	local expect = t.expect
	local SaveService = require(game.ServerScriptService.Services.SaveService)

	-- A v1 profile gains every new field through migration.
	t.test("migration v1 to v2 completes creature fields", function()
		local data = {
			Essence = 100,
			Creatures = {
				{ Id = "a", SpeciesId = "Riftling", Rarity = "Common", Mutation = false, Level = 1, Power = 8 },
			},
			Eggs = {},
			SanctuaryLevel = 1,
			Stats = { TotalHatched = 0, TotalEssenceEarned = 0, RiftsCompleted = 0 },
			LastPlayed = 0,
			Version = 1,
		}
		SaveService.Migrate(data)
		expect.equal(data.Version, 2)
		expect.truthy(data.Index ~= nil)
		expect.truthy(data.Items ~= nil)
		expect.equal(data.Stars, 0)
		expect.equal(data.Rebirths, 0)
		expect.equal(data.Creatures[1].Stage, 1)
		expect.equal(data.Creatures[1].XP, 0)
		expect.equal(data.Creatures[1].MaxLevel, 10)
		expect.equal(data.Creatures[1].Equipment ~= nil, true)
		expect.equal(data.Creatures[1].Parents ~= nil, true)
		expect.equal(data.Creatures[1].Generation, 1)
	end)

	-- A v2 profile passes through untouched.
	t.test("migration v2 data stays untouched", function()
		local data = {
			Essence = 50,
			Creatures = {},
			Eggs = {},
			Index = { ["x|y|z"] = true },
			Items = { { Id = "i1", Type = "Heart", Tier = 2 } },
			Stars = 3,
			Rebirths = 2,
			Stats = { TotalHatched = 0, TotalEssenceEarned = 0, RiftsCompleted = 0 },
			Version = 2,
		}
		SaveService.Migrate(data)
		expect.equal(data.Stars, 3)
		expect.equal(data.Rebirths, 2)
		expect.equal(#data.Items, 1)
	end)
end
