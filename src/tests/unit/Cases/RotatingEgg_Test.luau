return function(t)
	local expect = t.expect
	local Config = require(game.ReplicatedStorage.Shared.Config)
	local RotatingEgg = require(game.ReplicatedStorage.Shared.RotatingEgg)

	t.test("definitions are valid and data-driven", function()
		expect.truthy(#Config.ROTATING_EGGS > 0)
		for _, definition in Config.ROTATING_EGGS do
			expect.truthy(RotatingEgg.ValidateDefinition(definition))
		end
	end)

	t.test("rotation changes exactly at the server window boundary", function()
		local window = Config.ROTATING_EGG_ROTATION_SECONDS
		local before = RotatingEgg.GetActive(window - 1)
		local atBoundary = RotatingEgg.GetActive(window)
		expect.equal(before.WindowIndex, 0)
		expect.equal(atBoundary.WindowIndex, 1)
		expect.truthy(before.Id ~= atBoundary.Id)
		expect.equal(RotatingEgg.GetActive(window - 1).EndsAt, window)
		expect.equal(RotatingEgg.GetActive(window).StartsAt, window)
	end)

	t.test("snapshot exposes authoritative rates pity cap and timing", function()
		local now = 123456
		local snapshot = RotatingEgg.Snapshot(now, 7)
		expect.truthy(RotatingEgg.ValidateSnapshot(snapshot))
		expect.equal(snapshot.SecondsRemaining, snapshot.EndsAt - now)
		expect.equal(snapshot.Pity, 7)
		expect.equal(snapshot.PityMax, Config.PITY_THRESHOLD)
		expect.equal(snapshot.LuckCap, Config.LUCK_HARD_CAP)
		expect.truthy(#snapshot.Rates > 0)
	end)

	t.test("invalid definitions and snapshots never validate", function()
		expect.falsy(RotatingEgg.ValidateDefinition({ Id = "x", Name = "x", Tier = "UnknownEgg" }))
		expect.falsy(RotatingEgg.ValidateSnapshot({ Id = "x", StartsAt = 0, EndsAt = 0 }))
	end)
end
