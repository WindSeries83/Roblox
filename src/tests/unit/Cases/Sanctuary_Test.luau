return function(t)
	local expect = t.expect
	local Sanctuary = require(game.ReplicatedStorage.Shared.Sanctuary)
	local Config = require(game.ReplicatedStorage.Shared.Config)

	-- Base sanctuary holds the base cap.
	t.test("base sanctuary holds base cap", function()
		expect.equal(Sanctuary.MaxCreatures(1), Config.MAX_CREATURES_BASE)
	end)

	-- Each sanctuary level adds slots.
	t.test("each sanctuary level adds slots", function()
		expect.equal(Sanctuary.MaxCreatures(2), Config.MAX_CREATURES_BASE + Config.SANCTUARY_SLOTS_PER_LEVEL)
	end)

	-- Upgrade cost scales with the current level.
	t.test("upgrade cost scales with level", function()
		expect.equal(Sanctuary.UpgradeCost(1), Config.SANCTUARY_UPGRADE_BASE_COST)
		expect.equal(Sanctuary.UpgradeCost(2), Config.SANCTUARY_UPGRADE_BASE_COST * Config.SANCTUARY_UPGRADE_COST_MULT)
	end)

	-- Upgrade requires enough essence.
	t.test("upgrade requires enough essence", function()
		local cost = Sanctuary.UpgradeCost(1)
		expect.falsy(Sanctuary.CanUpgrade(cost - 1, 1))
		expect.truthy(Sanctuary.CanUpgrade(cost, 1))
	end)
end
