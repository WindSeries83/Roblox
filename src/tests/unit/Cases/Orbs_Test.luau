return function(t)
	local expect = t.expect
	local Orbs = require(game.ReplicatedStorage.Shared.Orbs)
	local Config = require(game.ReplicatedStorage.Shared.Config)

	t.test("NextSpawnAt returns the due time when not reached", function()
		expect.equal(Orbs.NextSpawnAt(100, 120, 45), 145)
	end)

	t.test("NextSpawnAt spawns immediately when overdue", function()
		expect.equal(Orbs.NextSpawnAt(100, 500, 45), 500)
	end)

	t.test("reward is at least 1 even with zero rate", function()
		expect.equal(Orbs.Reward(0), 1)
	end)

	t.test("reward scales with rate and configured seconds", function()
		expect.equal(Orbs.Reward(2), math.floor(2 * Config.ORB_REWARD_SECONDS))
	end)

	t.test("can claim below the hourly cap", function()
		local now = 1000
		local claims = {}
		for i = 1, Config.ORB_MAX_PER_HOUR - 1 do
			table.insert(claims, now - i * 10)
		end
		local ok, reason = Orbs.CanClaim(claims, now, Config.ORB_MAX_PER_HOUR)
		expect.truthy(ok)
		expect.falsy(reason)
	end)

	t.test("cannot claim beyond the hourly cap", function()
		local now = 1000
		local claims = {}
		for _ = 1, Config.ORB_MAX_PER_HOUR do
			table.insert(claims, now - 30)
		end
		local ok, reason = Orbs.CanClaim(claims, now, Config.ORB_MAX_PER_HOUR)
		expect.falsy(ok)
		expect.equal(reason, "RateLimited")
	end)

	t.test("claims older than an hour do not count", function()
		local now = 4000
		local claims = {}
		for _ = 1, Config.ORB_MAX_PER_HOUR do
			table.insert(claims, now - 3700)
		end
		local ok = Orbs.CanClaim(claims, now, Config.ORB_MAX_PER_HOUR)
		expect.truthy(ok)
	end)
end
