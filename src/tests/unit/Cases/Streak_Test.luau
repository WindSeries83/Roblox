return function(t)
	local expect = t.expect
	local Streak = require(game.ReplicatedStorage.Shared.Streak)

	t.test("first ever login grants day 1", function()
		local streak, index = Streak.Evaluate("2026-08-23", "", 0)
		expect.equal(streak, 1)
		expect.equal(index, 1)
	end)

	t.test("same day twice grants nothing more", function()
		local streak, index = Streak.Evaluate("2026-08-23", "2026-08-23", 3)
		expect.equal(streak, 3)
		expect.falsy(index)
	end)

	t.test("consecutive day increments the streak", function()
		local streak, index = Streak.Evaluate("2026-08-24", "2026-08-23", 3)
		expect.equal(streak, 4)
		expect.equal(index, 4)
	end)

	t.test("month rollover counts as consecutive", function()
		local streak, _ = Streak.Evaluate("2026-09-01", "2026-08-31", 2)
		expect.equal(streak, 3)
	end)

	t.test("year rollover counts as consecutive", function()
		local streak, _ = Streak.Evaluate("2027-01-01", "2026-12-31", 9)
		expect.equal(streak, 10)
	end)

	t.test("missed day resets the streak to 1", function()
		local streak, index = Streak.Evaluate("2026-08-25", "2026-08-23", 5)
		expect.equal(streak, 1)
		expect.equal(index, 1)
	end)

	t.test("reward cycles back to day 1 after a full week", function()
		local Config = require(game.ReplicatedStorage.Shared.Config)
		expect.equal(#Config.STREAK_REWARDS, 7)
		-- streak 7 -> jour 8 : la récompense repart au début de la table
		local _, index = Streak.Evaluate("2026-09-05", "2026-09-04", 7)
		expect.equal(index, 1)
	end)
end
