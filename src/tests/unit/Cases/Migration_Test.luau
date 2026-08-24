return function(t)
	local expect = t.expect
	local SaveService = require(game.ServerScriptService.Services.SaveService)

	-- A v1 profile gains every new field through migration.
	t.test("migration v1 to v7 completes creature fields", function()
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
		expect.equal(data.Version, 7)
		expect.equal(data.CompanionId, nil)
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
		expect.equal(data.Stats.DuelsWon, 0)
		expect.equal(data.Stats.DuelsLost, 0)
		expect.equal(data.Stats.MarketSales, 0)
		expect.equal(data.LoginStreak, 0)
		expect.equal(data.LastLoginDate, "")
		expect.equal(data.Stats.HatchesSinceRare, 0)
		expect.equal(data.Season.Level, 1)
		expect.equal(data.Season.XP, 0)
		expect.truthy(data.Season.ClaimedFree ~= nil)
		expect.truthy(data.Season.ClaimedPremium ~= nil)
		expect.truthy(data.Titles ~= nil)
		expect.truthy(data.MarketHistory ~= nil)
	end)

	-- A v2 profile gains quest fields and keeps its data.
	t.test("migration v2 to v7 keeps data", function()
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
		expect.equal(data.Version, 7)
		expect.equal(data.Stars, 3)
		expect.equal(data.Rebirths, 2)
		expect.equal(#data.Items, 1)
		expect.equal(data.Stats.TotalBred, 0)
		expect.equal(data.TutorialDone, false)
		expect.truthy(data.Quests ~= nil)
		expect.equal(data.Stats.DuelsWon, 0)
		expect.equal(data.Season.Level, 1)
	end)

	-- A v3 profile gains social/monetization fields and keeps its data.
	t.test("migration v3 to v7 keeps data", function()
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
		expect.equal(data.Version, 7)
		expect.equal(data.Stats.TotalBred, 1)
		expect.equal(data.Quests.Day, "2026-01-01")
		expect.truthy(data.Quests.Achievements.FirstHatch)
		expect.equal(data.TutorialDone, true)
		expect.equal(data.Stats.DuelsWon, 0)
		expect.equal(data.Stats.DuelsLost, 0)
		expect.equal(data.Stats.MarketSales, 0)
		expect.equal(data.Season.Level, 1)
		expect.equal(data.Season.XP, 0)
		expect.truthy(data.Season.ClaimedFree ~= nil)
		expect.truthy(data.Season.ClaimedPremium ~= nil)
		expect.truthy(data.Titles ~= nil)
		expect.truthy(data.MarketHistory ~= nil)
	end)

	-- A v4 profile gains the streak/pity fields and keeps its data.
	t.test("migration v4 to v7 keeps data", function()
		local data = {
			Essence = 50,
			Creatures = {},
			Eggs = {},
			Index = {},
			Items = {},
			Stars = 1,
			Rebirths = 0,
			Stats = {
				TotalHatched = 2,
				TotalEssenceEarned = 60,
				RiftsCompleted = 1,
				TotalBred = 1,
				DuelsWon = 3,
				DuelsLost = 1,
				MarketSales = 2,
			},
			Quests = { Day = "2026-01-01", Daily = {}, Achievements = { FirstHatch = true } },
			Season = { Level = 7, XP = 120, ClaimedFree = { 1, 3 }, ClaimedPremium = {} },
			Titles = { "Éleveur" },
			MarketHistory = { { CreatureId = "c1", Price = 100, SoldAt = 1 } },
			TutorialDone = true,
			Version = 4,
		}
		SaveService.Migrate(data)
		expect.equal(data.Version, 7)
		expect.equal(data.LoginStreak, 0)
		expect.equal(data.LastLoginDate, "")
		expect.equal(data.Stats.HatchesSinceRare, 0)
		expect.equal(data.Stats.DuelsWon, 3)
		expect.equal(data.Season.Level, 7)
		expect.equal(#data.Titles, 1)
		expect.equal(#data.MarketHistory, 1)
	end)

	-- A v5 profile gains the lot2 fields through migration.
	t.test("migration v5 to v7 adds lot2 fields", function()
		local data = { Version = 5 }
		SaveService.Migrate(data)
		expect.equal(data.Version, 7)
		expect.equal(data.SkillPoints, 0)
		expect.truthy(data.SkillRanks ~= nil)
		expect.equal(data.Offers.FirstPurchaseEligible, false)
		expect.equal(data.Offers.FirstPurchaseClaimed, false)
		expect.equal(data.Stats.Funnel.FirstHatchAt, 0)
		expect.equal(data.Stats.Funnel.FirstPurchaseAt, 0)
		expect.equal(data.VipGiftDate, "")
	end)

	-- A v5 profile keeps its funnels, ranks and companion through migration.
	t.test("migration preserves existing funnels ranks and companion", function()
		local data = {
			Version = 5,
			Stats = { TotalHatched = 12 },
			SkillRanks = { FarmRate1 = 2 },
			Offers = { FirstPurchaseClaimed = true },
			CompanionId = "comp_9",
		}
		SaveService.Migrate(data)
		expect.equal(data.Version, 7)
		expect.equal(data.Stats.TotalHatched, 12)
		expect.equal(data.SkillRanks.FarmRate1, 2)
		expect.equal(data.Offers.FirstPurchaseClaimed, true)
		expect.equal(data.Stats.Funnel.FirstHatchAt, 0)
		expect.equal(data.CompanionId, "comp_9")
	end)
end
