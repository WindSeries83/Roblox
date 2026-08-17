return function(t)
	local expect = t.expect
	local SaveService = require(game.ServerScriptService.Services.SaveService)

	-- A v1 profile gains every new field through migration.
	t.test("migration v1 to v3 completes creature fields", function()
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
		expect.equal(data.Version, 3)
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
		expect.equal(data.Stats.TotalBred, 0)
		expect.equal(data.TutorialDone, false)
		expect.truthy(data.Quests ~= nil)
		expect.equal(data.Quests.Day, "")
		expect.truthy(data.Quests.Daily ~= nil)
		expect.truthy(data.Quests.Achievements ~= nil)
	end)

	-- A v2 profile gains quest fields and keeps its data.
	t.test("migration v2 to v3 keeps data", function()
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
		expect.equal(data.Version, 3)
		expect.equal(data.Stars, 3)
		expect.equal(data.Rebirths, 2)
		expect.equal(#data.Items, 1)
		expect.equal(data.Stats.TotalBred, 0)
		expect.equal(data.TutorialDone, false)
		expect.truthy(data.Quests ~= nil)
	end)

	-- A v3 profile passes through untouched.
	t.test("migration v3 data stays untouched", function()
		local data = {
			Essence = 50,
			Creatures = {},
			Eggs = {},
			Index = {},
			Items = {},
			Stars = 1,
			Rebirths = 0,
			Stats = { TotalHatched = 2, TotalEssenceEarned = 60, RiftsCompleted = 1, TotalBred = 1 },
			Quests = { Day = "2026-01-01", Daily = {}, Achievements = { FirstHatch = true } },
			TutorialDone = true,
			Version = 3,
		}
		SaveService.Migrate(data)
		expect.equal(data.Version, 3)
		expect.equal(data.Stats.TotalBred, 1)
		expect.equal(data.Quests.Day, "2026-01-01")
		expect.truthy(data.Quests.Achievements.FirstHatch)
		expect.equal(data.TutorialDone, true)
	end)
end
