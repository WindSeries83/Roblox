return function(t)
	local expect = t.expect
	local Config = require(game.ReplicatedStorage.Shared.Config)
	local QuestService = require(game.ServerScriptService.Services.QuestService)

	t.test("RollDaily is deterministic and picks distinct quests", function()
		local a = QuestService.RollDaily("2026-08-17", 11510578955)
		local b = QuestService.RollDaily("2026-08-17", 11510578955)
		expect.equal(#a, Config.DAILY_QUESTS_COUNT)
		expect.equal(#b, Config.DAILY_QUESTS_COUNT)
		local seen = {}
		for _, id in a do
			expect.truthy(Config.DAILY_QUESTS[id] ~= nil)
			expect.truthy(seen[id] == nil)
			seen[id] = true
		end
		local same = true
		for i = 1, #a do
			if a[i] ~= b[i] then
				same = false
				break
			end
		end
		expect.truthy(same)
	end)

	t.test("RollDaily varies with the day and the user", function()
		local dayA = QuestService.RollDaily("2026-08-17", 1)
		local dayB = QuestService.RollDaily("2026-08-18", 1)
		local userB = QuestService.RollDaily("2026-08-17", 2)
		local diffDay = false
		local diffUser = false
		for i = 1, #dayA do
			if dayA[i] ~= dayB[i] then
				diffDay = true
			end
			if dayA[i] ~= userB[i] then
				diffUser = true
			end
		end
		expect.truthy(diffDay)
		expect.truthy(diffUser)
	end)

	t.test("EvaluateAchievements unlocks nothing on a fresh profile", function()
		local data = {
			Stats = { TotalHatched = 0, TotalEssenceEarned = 0, RiftsCompleted = 0, TotalBred = 0 },
			Creatures = {},
			Index = {},
			Rebirths = 0,
		}
		local met = QuestService.EvaluateAchievements(data)
		local count = 0
		for _ in met do
			count += 1
		end
		expect.equal(count, 0)
	end)

	t.test("EvaluateAchievements unlocks matching milestones", function()
		local data = {
			Stats = {
				TotalHatched = 12,
				TotalEssenceEarned = 12000,
				RiftsCompleted = 3,
				TotalBred = 1,
			},
			Creatures = {
				{ Id = "1", Mutation = false },
				{ Id = "2", Mutation = false },
				{ Id = "3", Mutation = false },
				{ Id = "4", Mutation = false },
				{ Id = "5", Mutation = false },
			},
			Index = {},
			Rebirths = 1,
		}
		local met = QuestService.EvaluateAchievements(data)
		expect.truthy(met.FirstHatch)
		expect.truthy(met.TenHatch)
		expect.falsy(met.HundredHatch)
		expect.truthy(met.FiveCreatures)
		expect.truthy(met.FirstRift)
		expect.falsy(met.RiftMaster)
		expect.truthy(met.FirstBreed)
		expect.falsy(met.Breeder)
		expect.truthy(met.FirstRebirth)
		expect.truthy(met.Essence10k)
		expect.falsy(met.FirstMutation)
		expect.falsy(met.Dex10)
		expect.falsy(met.Dex50)
	end)

	t.test("EvaluateAchievements handles mutation and index entries", function()
		local data = {
			Stats = { TotalHatched = 1, TotalEssenceEarned = 0, RiftsCompleted = 0, TotalBred = 0 },
			Creatures = { { Id = "1", Mutation = "Crystal" } },
			Index = {
				["a|c|false"] = true,
				["b|c|false"] = true,
				["c|c|false"] = true,
				["d|c|false"] = true,
				["e|c|false"] = true,
				["f|c|false"] = true,
				["g|c|false"] = true,
				["h|c|false"] = true,
				["i|c|false"] = true,
				["j|c|false"] = true,
			},
			Rebirths = 0,
		}
		local met = QuestService.EvaluateAchievements(data)
		expect.truthy(met.FirstHatch)
		expect.truthy(met.FirstMutation)
		expect.truthy(met.Dex10)
		expect.falsy(met.Dex50)
	end)

	t.test("achievement definitions reference valid quest ids", function()
		for id, def in Config.ACHIEVEMENTS do
			expect.truthy(def.Name ~= nil and def.Name ~= "")
			expect.truthy(def.Desc ~= nil and def.Desc ~= "")
			expect.truthy(def.Reward > 0)
			expect.equal(typeof(id), "string")
		end
	end)

	t.test("daily quest definitions reference valid targets", function()
		for id, def in Config.DAILY_QUESTS do
			expect.truthy(def.Target > 0)
			expect.truthy(def.Reward > 0)
			expect.truthy(def.Name ~= "")
			expect.truthy(def.Desc ~= "")
			expect.equal(typeof(id), "string")
		end
	end)

	t.test("daily reset clears progress and replay ledger", function()
		local quests = {
			Day = "2026-08-16",
			Daily = { { Id = "HatchDaily", Progress = 1, Claimed = false } },
			ProcessedEvents = { old_hatch = true },
		}
		expect.truthy(QuestService.ResetDaily(quests, "2026-08-17", 11510578955))
		expect.equal(quests.Day, "2026-08-17")
		expect.equal(#quests.Daily, Config.DAILY_QUESTS_COUNT)
		expect.equal(next(quests.ProcessedEvents), nil)
		expect.falsy(QuestService.ResetDaily(quests, "2026-08-17", 11510578955))
	end)

	t.test("daily progress ignores the same event replay", function()
		local quests = {
			Day = "2026-08-17",
			Daily = { { Id = "HatchDaily", Progress = 0, Claimed = false } },
		}
		local changed, completed = QuestService.ApplyDailyProgress(quests, "HatchDaily", 1, "egg:incubator")
		expect.truthy(changed)
		expect.falsy(completed)
		expect.equal(quests.Daily[1].Progress, 1)
		local replayed = QuestService.ApplyDailyProgress(quests, "HatchDaily", 1, "egg:incubator")
		expect.falsy(replayed)
		expect.equal(quests.Daily[1].Progress, 1)
		local _, completedNext = QuestService.ApplyDailyProgress(quests, "HatchDaily", 1, "egg:incubator-2")
		expect.truthy(completedNext)
		expect.equal(quests.Daily[1].Progress, 2)
	end)
end
