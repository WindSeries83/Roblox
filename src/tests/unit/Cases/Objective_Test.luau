return function(t)
	local expect = t.expect
	local Objective = require(game.ReplicatedStorage.Shared.Objective)
	local Config = require(game.ReplicatedStorage.Shared.Config)

	t.test("active rift wins over everything", function()
		local pick = Objective.Pick({ Quests = { Daily = {} }, Stats = { TotalHatched = 0 } }, { Active = true })
		expect.truthy(pick)
		expect.equal(pick.Priority, 100)
	end)

	t.test("claimable quest beats first egg", function()
		local state = {
			Quests = {
				Daily = { { Id = "HatchDaily", Progress = Config.DAILY_QUESTS.HatchDaily.Target, Claimed = false } },
			},
			Stats = { TotalHatched = 0 },
		}
		local pick = Objective.Pick(state, { Active = false })
		expect.truthy(pick)
		expect.equal(pick.Priority, 80)
	end)

	t.test("claimed quest does not count", function()
		local pick = Objective.Pick({
			Quests = { Daily = { { Id = "HatchDaily", Progress = 99, Claimed = true } } },
			Stats = { TotalHatched = 3, TotalEssenceEarned = 10 },
			Stars = 0,
		}, nil)
		expect.truthy(pick)
		expect.equal(pick.Priority, 20)
	end)

	t.test("first egg hint before any hatch", function()
		local pick = Objective.Pick({ Quests = { Daily = {} }, Stats = { TotalHatched = 0 } }, nil)
		expect.truthy(pick)
		expect.equal(pick.Priority, 60)
	end)

	t.test("rebirth reachable", function()
		local pick = Objective.Pick({
			Quests = { Daily = {} },
			Stats = { TotalHatched = 1, TotalEssenceEarned = Config.REBIRTH_THRESHOLDS[1] },
			Stars = 0,
			WorldProgress = { TwilightGrove = { BossDefeated = true } },
		}, nil)
		expect.truthy(pick)
		expect.equal(pick.Priority, 40)
	end)

	t.test("teasing when nothing urgent", function()
		local pick = Objective.Pick({
			Quests = { Daily = { { Id = "HatchDaily", Progress = 0, Claimed = false } } },
			Stats = { TotalHatched = 4, TotalEssenceEarned = 10 },
			Stars = 0,
		}, nil)
		expect.truthy(pick)
		expect.equal(pick.Priority, 20)
		expect.equal(pick.Need, "Progress")
		expect.equal(pick.Feature, "More")
	end)

	t.test("progression objective points to the next revealed system", function()
		local pick = Objective.Pick({
			Stats = { TotalHatched = 1, RiftsCompleted = 1, TotalEssenceEarned = 10 },
			Stars = 1,
			SkillPoints = 1,
			WorldProgress = { TwilightGrove = { BossDefeated = true } },
		}, nil)
		expect.equal(pick.Need, "Progress")
		expect.equal(pick.Feature, "Breeding")
	end)

	t.test("no teasing before first hatch", function()
		local pick = Objective.Pick(
			{ Quests = { Daily = {} }, Stats = { TotalHatched = 0, TotalEssenceEarned = 10 }, Stars = 0 },
			nil
		)
		expect.truthy(pick)
		expect.equal(pick.Priority, 60)
	end)

	t.test("tutorial starts in the world with one hatch objective", function()
		local pick = Objective.Tutorial({ TutorialDone = false, Stats = { TotalHatched = 0 } }, {})
		expect.equal(pick.Need, "PlaceEgg")
		expect.equal(pick.Priority, 100)
	end)

	t.test("tutorial asks to claim the incubated creature", function()
		local pick = Objective.Tutorial({
			TutorialDone = false,
			Stats = { TotalHatched = 0 },
			Incubators = { { ReadyAt = os.time() - 1 } },
		}, {})
		expect.equal(pick.Need, "ClaimHatch")
	end)

	t.test("tutorial keeps incubation state until its deadline", function()
		local pick = Objective.Tutorial({
			TutorialDone = false,
			Stats = { TotalHatched = 0 },
			Incubators = { { ReadyAt = 200 } },
		}, {}, 100)
		expect.equal(pick.Need, "Incubating")
	end)

	t.test("tutorial moves to the rift after hatch", function()
		local pick = Objective.Tutorial({ TutorialDone = false, Stats = { TotalHatched = 1 } }, {})
		expect.equal(pick.Need, "RiftEntered")
	end)

	t.test("tutorial exposes claim only after a rift win", function()
		local pick = Objective.Tutorial(
			{ TutorialDone = false, Stats = { TotalHatched = 1, RiftsCompleted = 1 } },
			{ RiftEntered = true }
		)
		expect.equal(pick.Need, "Claim")
	end)

	t.test("tutorial reward requires the server-side rift win", function()
		expect.falsy(Objective.CanCompleteTutorial({ TutorialDone = false, Stats = { TotalHatched = 1 } }))
		expect.truthy(Objective.CanCompleteTutorial({
			TutorialDone = false,
			Stats = { TotalHatched = 1, RiftsCompleted = 1 },
		}))
	end)

	t.test("completed tutorial has no objective", function()
		expect.equal(Objective.Tutorial({ TutorialDone = true, Stats = {} }, {}), nil)
	end)
end
