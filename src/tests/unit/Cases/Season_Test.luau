return function(t)
	local expect = t.expect
	local Season = require(game.ReplicatedStorage.Shared.Season)
	local Config = require(game.ReplicatedStorage.Shared.Config)

	t.test("version change resets claims exactly once", function()
		local season =
			{ Version = 1, Level = 8, XP = 700, ClaimedFree = { [1] = true }, ClaimedPremium = { [1] = true } }
		expect.truthy(Season.ResetIfVersionChanged(season, 2))
		expect.equal(season.Level, 1)
		expect.equal(season.XP, 0)
		expect.equal(Season.ResetIfVersionChanged(season, 2), false)
	end)

	t.test("fresh season is level 1", function()
		expect.equal(Season.LevelFromXP(0), 1)
		expect.equal(Season.LevelFromXP(99), 1)
	end)

	t.test("level grows linearly with xp", function()
		expect.equal(Season.LevelFromXP(100), 2)
		expect.equal(Season.LevelFromXP(500), 6)
		expect.equal(Season.LevelFromXP(1900), 20)
	end)

	t.test("level is capped at max", function()
		expect.equal(Season.LevelFromXP(100000), Config.SEASON_MAX_LEVEL)
	end)

	t.test("XPForLevel matches level thresholds", function()
		expect.equal(Season.XPForLevel(1), 0)
		expect.equal(Season.XPForLevel(2), 100)
		expect.equal(Season.XPForLevel(6), 500)
	end)

	t.test("free reward scales with level", function()
		expect.truthy(Season.RewardFor(2, "free").Essence > Season.RewardFor(1, "free").Essence)
		expect.equal(Season.RewardFor(1, "free").Essence, Config.SEASON_FREE_ESSENCE[1] + Config.SEASON_FREE_ESSENCE[2])
	end)

	t.test("premium reward scales and exceeds free", function()
		expect.truthy(Season.RewardFor(1, "premium").Essence > Season.RewardFor(1, "free").Essence)
		expect.truthy(Season.RewardFor(2, "premium").Essence > Season.RewardFor(1, "premium").Essence)
	end)

	t.test("max level free grants a title", function()
		local reward = Season.RewardFor(Config.SEASON_MAX_LEVEL, "free")
		expect.truthy(reward.Title ~= nil)
	end)

	t.test("max level premium grants creature and title", function()
		local reward = Season.RewardFor(Config.SEASON_MAX_LEVEL, "premium")
		expect.truthy(reward.Creature ~= nil)
		expect.truthy(reward.Title ~= nil)
		expect.equal(reward.Creature.Rarity, Config.SEASON_EXCLUSIVE.Rarity)
	end)

	t.test("below max premium has no creature", function()
		local reward = Season.RewardFor(Config.SEASON_MAX_LEVEL - 1, "premium")
		expect.falsy(reward.Creature)
	end)

	t.test("CanClaim requires level unlocked and not claimed", function()
		local season = { XP = 250, ClaimedFree = {}, ClaimedPremium = {} }
		expect.truthy(Season.CanClaim(season, 3, "free"))
		expect.falsy(Season.CanClaim(season, 4, "free"))
		season.ClaimedFree[3] = true
		expect.falsy(Season.CanClaim(season, 3, "free"))
	end)

	t.test("CanClaim rejects out of range levels", function()
		local season = { XP = 100000, ClaimedFree = {}, ClaimedPremium = {} }
		expect.falsy(Season.CanClaim(season, 0, "free"))
		expect.falsy(Season.CanClaim(season, Config.SEASON_MAX_LEVEL + 1, "free"))
	end)
end
