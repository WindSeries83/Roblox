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

	-- Free egg sources never bypass the gate.
	t.test("resolve egg tier downgrades locked tiers", function()
		expect.equal(Sanctuary.ResolveEggTier("CommonEgg", 1), "CommonEgg")
		expect.equal(Sanctuary.ResolveEggTier("LegendaryEgg", 1), "CommonEgg")
		expect.equal(Sanctuary.ResolveEggTier("EpicEgg", 2), "UncommonEgg")
		expect.equal(Sanctuary.ResolveEggTier("RareEgg", 3), "RareEgg")
		expect.equal(Sanctuary.ResolveEggTier("EpicEgg", 4), "EpicEgg")
		expect.equal(Sanctuary.ResolveEggTier("LegendaryEgg", 5), "LegendaryEgg")
	end)

	t.test("SortEggs : palier croissant puis ancienneté", function()
		local eggs = {
			{ Id = "b", Tier = "RareEgg", Timestamp = 10 },
			{ Id = "a", Tier = "CommonEgg", Timestamp = 20 },
			{ Id = "c", Tier = "CommonEgg", Timestamp = 5 },
		}
		local sorted = Sanctuary.SortEggs(eggs)
		expect.equal(sorted[1].Id, "c")
		expect.equal(sorted[2].Id, "a")
		expect.equal(sorted[3].Id, "b")
	end)

	t.test("shared sanctuary assignments enforce unlock ownership and cap", function()
		local owned = { a = true, b = true, c = true, d = true }
		expect.truthy(Sanctuary.ValidateAssignment("Sanctuary1", { "a", "b", "c" }, owned, 1))
		expect.falsy(Sanctuary.ValidateAssignment("Sanctuary2", { "a" }, owned, 1))
		expect.falsy(Sanctuary.ValidateAssignment("Sanctuary1", { "a", "missing" }, owned, 1))
		expect.falsy(Sanctuary.ValidateAssignment("Sanctuary1", { "a", "b", "c", "d" }, owned, 1))
		expect.falsy(Sanctuary.ValidateAssignment("Sanctuary1", { "a", "a" }, owned, 1))
	end)

	t.test("offline production is capped and cannot be collected twice", function()
		local amount, collectedAt = Sanctuary.OfflineReward(10, 0, Config.OFFLINE_CAP_SECONDS * 2)
		expect.equal(amount, math.floor(10 * Config.OFFLINE_RATE * Config.OFFLINE_CAP_SECONDS))
		expect.equal(collectedAt, Config.OFFLINE_CAP_SECONDS * 2)
		local replay = Sanctuary.OfflineReward(10, collectedAt, collectedAt)
		expect.equal(replay, 0)
	end)
end
