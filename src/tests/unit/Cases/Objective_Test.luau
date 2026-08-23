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
	end)

	t.test("no teasing before first hatch", function()
		local pick = Objective.Pick(
			{ Quests = { Daily = {} }, Stats = { TotalHatched = 0, TotalEssenceEarned = 10 }, Stars = 0 },
			nil
		)
		expect.truthy(pick)
		expect.equal(pick.Priority, 60)
	end)
end
