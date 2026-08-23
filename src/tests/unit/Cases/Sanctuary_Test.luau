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

	-- Egg gate locks both purchasable upgrades at rank 1.
	t.test("egg gate at rank 1 locks uncommon and rare", function()
		local gate = Sanctuary.EggGate(1)
		expect.equal(gate.UncommonEgg, 2)
		expect.equal(gate.RareEgg, 3)
		expect.equal(Sanctuary.EggLocked("UncommonEgg", 1), 2)
		expect.equal(Sanctuary.EggLocked("RareEgg", 1), 3)
	end)

	-- At rank 2 only the rare egg stays locked.
	t.test("egg gate at rank 2 keeps only rare locked", function()
		local gate = Sanctuary.EggGate(2)
		expect.falsy(gate.UncommonEgg)
		expect.equal(gate.RareEgg, 3)
		expect.falsy(Sanctuary.EggLocked("UncommonEgg", 2))
		expect.equal(Sanctuary.EggLocked("RareEgg", 2), 3)
	end)

	-- Rank 3 keeps epic and legendary locked.
	t.test("egg gate at rank 3 keeps epic and legendary locked", function()
		local gate = Sanctuary.EggGate(3)
		expect.falsy(gate.UncommonEgg)
		expect.falsy(gate.RareEgg)
		expect.equal(gate.EpicEgg, 4)
		expect.equal(gate.LegendaryEgg, 5)
		expect.falsy(Sanctuary.EggLocked("UncommonEgg", 3))
		expect.falsy(Sanctuary.EggLocked("RareEgg", 9))
		expect.equal(Sanctuary.EggLocked("EpicEgg", 3), 4)
	end)

	-- Rank 4 unlocks epic, not legendary.
	t.test("egg gate at rank 4 unlocks epic only", function()
		local gate = Sanctuary.EggGate(4)
		expect.falsy(gate.EpicEgg)
		expect.equal(gate.LegendaryEgg, 5)
	end)

	-- Rank 5 and beyond unlocks everything.
	t.test("egg gate at rank 5 plus unlocks everything", function()
		local gate = Sanctuary.EggGate(5)
		expect.falsy(gate.EpicEgg)
		expect.falsy(gate.LegendaryEgg)
		expect.falsy(Sanctuary.EggLocked("LegendaryEgg", 9))
	end)

	-- Common egg is never gated.
	t.test("common egg never locked", function()
		expect.falsy(Sanctuary.EggLocked("CommonEgg", 1))
	end)
end
