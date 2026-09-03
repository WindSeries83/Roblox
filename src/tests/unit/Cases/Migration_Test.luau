return function(t)
	local expect = t.expect
	local SaveService = require(game.ServerScriptService.Services.SaveService)

	-- A v1 profile gains every new field through migration.
	t.test("migration v1 to v11 completes creature fields", function()
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
		expect.equal(data.Version, 16)
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
		expect.equal(data.Season.Version, 1)
		expect.equal(data.Season.XP, 0)
		expect.truthy(data.Season.ClaimedFree ~= nil)
		expect.truthy(data.Season.ClaimedPremium ~= nil)
		expect.truthy(data.Titles ~= nil)
		expect.truthy(data.MarketHistory ~= nil)
		expect.truthy(data.EconomyLedger ~= nil)
		expect.truthy(data.MarketLedger ~= nil)
		expect.truthy(data.DuelDefense ~= nil)
		expect.truthy(data.DuelLedger ~= nil)
		expect.equal(data.DuelSeason.Rating, 1000)
		expect.equal(data.VipExpiresAt, 0)
		expect.truthy(data.Incubators ~= nil)
	end)

	-- A v2 profile gains quest fields and keeps its data.
	t.test("migration v2 to v11 keeps data", function()
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
		expect.equal(data.Version, 16)
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
	t.test("migration v3 to v11 keeps data", function()
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
		expect.equal(data.Version, 16)
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
	t.test("migration v4 to v11 keeps data", function()
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
		expect.equal(data.Version, 16)
		expect.equal(data.LoginStreak, 0)
		expect.equal(data.LastLoginDate, "")
		expect.equal(data.Stats.HatchesSinceRare, 0)
		expect.equal(data.Stats.DuelsWon, 3)
		expect.equal(data.Season.Level, 7)
		expect.equal(#data.Titles, 1)
		expect.equal(#data.MarketHistory, 1)
	end)

	-- A v5 profile gains the lot2 fields through migration.
	t.test("migration v5 to v11 adds lot2 fields", function()
		local data = { Version = 5 }
		SaveService.Migrate(data)
		expect.equal(data.Version, 16)
		expect.equal(data.SkillPoints, 0)
		expect.truthy(data.SkillRanks ~= nil)
		expect.equal(data.Offers.FirstPurchaseEligible, false)
		expect.equal(data.Offers.FirstPurchaseClaimed, false)
		expect.equal(data.Stats.Funnel.FirstHatchAt, 0)
		expect.equal(data.Stats.Funnel.FirstPurchaseAt, 0)
		expect.equal(data.VipGiftDate, "")
	end)

	-- A v5 profile keeps its funnels, ranks and companion through migration.
	t.test("migration v6 to v11 preserves funnels ranks and companion", function()
		local data = {
			Version = 5,
			Stats = { TotalHatched = 12 },
			SkillRanks = { FarmRate1 = 2 },
			Offers = { FirstPurchaseClaimed = true },
			CompanionId = "comp_9",
		}
		SaveService.Migrate(data)
		expect.equal(data.Version, 16)
		expect.equal(data.Stats.TotalHatched, 12)
		expect.equal(data.SkillRanks.FarmRate1, 2)
		expect.equal(data.Offers.FirstPurchaseClaimed, true)
		expect.equal(data.Stats.Funnel.FirstHatchAt, 0)
		expect.equal(data.CompanionId, "comp_9")
	end)

	-- Un profil v7 gagne les tables transactionnelles (garde-fou anti double-grant).
	t.test("migration v7 to v11 adds transaction ledgers", function()
		local data = { Version = 7, CompanionId = "comp_1" }
		SaveService.Migrate(data)
		expect.equal(data.Version, 16)
		expect.truthy(data.PurchaseReceipts ~= nil)
		expect.truthy(data.PurchaseReceiptOrder ~= nil)
		expect.truthy(data.MarketLedger ~= nil)
		expect.equal(next(data.PurchaseReceipts), nil)
		expect.equal(data.CompanionId, "comp_1")
	end)

	-- Un profil déjà en v9 garde ses receipts existants.
	t.test("migration v9 to v11 adds incubators and preserves receipts", function()
		local data = { Version = 9, PurchaseReceipts = { ["42_abc"] = true } }
		SaveService.Migrate(data)
		expect.equal(data.Version, 16)
		expect.equal(data.PurchaseReceipts["42_abc"], true)
		expect.truthy(data.Incubators ~= nil)
	end)

	t.test("migration v10 adds an empty incubator list", function()
		local data = { Version = 10 }
		SaveService.Migrate(data)
		expect.equal(data.Version, 16)
		expect.truthy(data.Incubators ~= nil)
		expect.equal(#data.Incubators, 0)
	end)

	t.test("migration v10 ignores invalid and keeps valid incubators", function()
		local valid = {
			IncubatorId = "incubator_1",
			EggId = "egg_1",
			StartedAt = 100,
			ReadyAt = 160,
			QueueIndex = 1,
			ReservedHatch = {
				Species = "Riftling",
				Rarity = "Common",
				Mutation = nil,
				Power = 12,
			},
		}
		local data = {
			Version = 10,
			Incubators = {
				{ EggId = "legacy", ReadyAt = 123 },
				valid,
				{ IncubatorId = "broken", EggId = "egg_2", StartedAt = 200, ReadyAt = 100 },
			},
		}
		SaveService.Migrate(data)
		expect.equal(data.Version, 16)
		expect.equal(#data.Incubators, 1)
		expect.equal(data.Incubators[1].IncubatorId, "incubator_1")
	end)

	t.test("migration v13 purge un incubateur invalide avant reconnexion", function()
		local data = {
			Version = 13,
			Incubators = {
				{ IncubatorId = "broken", EggId = "egg", StartedAt = 200, ReadyAt = 100 },
			},
		}
		SaveService.Migrate(data)
		expect.equal(#data.Incubators, 0)
	end)

	-- La v12 ajoute et normalise la progression des mondes et les affectations AFK.
	t.test("migration v11 adds valid world and sanctuary progress", function()
		local data = {
			Version = 11,
			WorldProgress = {
				TwilightGrove = { HighestStage = 3.8, BossDefeated = true },
				Unknown = { HighestStage = 99, BossDefeated = true },
			},
			SanctuaryAssignments = {
				Sanctuary1 = { CreatureIds = { "a", 4, "b" }, LastCollectedAt = -5 },
			},
		}
		SaveService.Migrate(data)
		expect.equal(data.Version, 16)
		expect.equal(data.WorldProgress.TwilightGrove.HighestStage, 3)
		expect.truthy(data.WorldProgress.TwilightGrove.BossDefeated)
		expect.equal(data.WorldProgress.Unknown, nil)
		expect.equal(#data.SanctuaryAssignments.Sanctuary1.CreatureIds, 2)
		expect.equal(data.SanctuaryAssignments.Sanctuary1.LastCollectedAt, 0)
	end)

	t.test("migration v13 keeps a valid Rush checkpoint and purges an invalid one", function()
		local data = {
			Version = 13,
			Rush = {
				Active = {
					WorldId = "AshForge",
					AttemptId = "attempt-legacy",
					StartedAt = 100,
					EndsAt = 340,
					Completed = true,
					Claimed = false,
				},
			},
		}
		SaveService.Migrate(data)
		expect.equal(data.Version, 16)
		expect.equal(data.Rush.Active.WorldId, "AshForge")
		expect.equal(data.Rush.Active.AttemptId, "attempt-legacy")
		expect.truthy(data.Rush.Active.Completed)

		local invalid = { Version = 14, Rush = { Active = { WorldId = "Unknown", StartedAt = 1, EndsAt = 2 } } }
		SaveService.Migrate(invalid)
		expect.equal(invalid.Rush.Active, nil)
	end)
end
