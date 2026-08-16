return function(t)
	local expect = t.expect
	local Rebirth = require(game.ReplicatedStorage.Shared.Rebirth)
	local Config = require(game.ReplicatedStorage.Shared.Config)

	-- Thresholds follow the configured curve.
	t.test("thresholds follow the configured curve", function()
		expect.equal(Rebirth.NextThreshold(0), Config.REBIRTH_THRESHOLDS[1])
		expect.equal(Rebirth.NextThreshold(1), Config.REBIRTH_THRESHOLDS[2])
	end)

	-- Rebirth requires enough total essence earned.
	t.test("rebirth requires enough total essence earned", function()
		local threshold = Rebirth.NextThreshold(0)
		expect.falsy(Rebirth.CanRebirth(threshold - 1, 0))
		expect.truthy(Rebirth.CanRebirth(threshold, 0))
	end)

	-- No rebirth beyond the last threshold.
	t.test("no rebirth beyond the last threshold", function()
		local stars = #Config.REBIRTH_THRESHOLDS
		expect.falsy(Rebirth.CanRebirth(1e18, stars))
	end)

	-- Stars multiply essence.
	t.test("stars multiply essence", function()
		expect.near(Rebirth.StarEssenceMult(0), 1)
		expect.near(Rebirth.StarEssenceMult(2), 1 + 2 * Config.STAR_ESSENCE_BONUS)
	end)

	-- Only legendary relics survive a rebirth.
	t.test("only legendary relics survive a rebirth", function()
		local items = {
			{ Id = "h1", Type = "Heart", Tier = 3 },
			{ Id = "c1", Type = "Collar", Tier = 3 },
			{ Id = "r1", Type = "Relic", Tier = 1 },
			{ Id = "r2", Type = "Relic", Tier = 2 },
			{ Id = "r3", Type = "Relic", Tier = 3 },
		}
		local kept = Rebirth.KeepItems(items)
		expect.equal(#kept, 1)
		expect.equal(kept[1].Id, "r3")
	end)

	-- Reset keeps the strongest creature, wipes eggs and essence but keeps the index.
	t.test("reset keeps strongest creature and wipes eggs and essence", function()
		local data = {
			Essence = 99999,
			Creatures = { { Id = "c1", Power = 10 }, { Id = "c2", Power = 50 } },
			Eggs = { { Id = "e1" } },
			SanctuaryLevel = 4,
			Index = { ["Riftling|Common|false"] = true },
			Items = { { Id = "r3", Type = "Relic", Tier = 3 }, { Id = "h1", Type = "Heart", Tier = 1 } },
			Stars = 0,
			Rebirths = 0,
		}
		Rebirth.ApplyReset(data)
		expect.equal(#data.Creatures, 1)
		expect.equal(data.Creatures[1].Id, "c2")
		expect.equal(#data.Eggs, 0)
		expect.equal(data.SanctuaryLevel, 1)
		expect.equal(data.Essence, Config.STARTER_ESSENCE)
		expect.equal(data.Stars, 1)
		expect.equal(data.Rebirths, 1)
		expect.truthy(data.Index["Riftling|Common|false"])
		expect.equal(#data.Items, 1)
		expect.equal(data.Items[1].Id, "r3")
	end)

	-- Reset with no creatures leaves an empty sanctuary.
	t.test("reset with no creatures leaves an empty sanctuary", function()
		local data = {
			Essence = 100,
			Creatures = {},
			Eggs = {},
			SanctuaryLevel = 1,
			Index = {},
			Items = {},
			Stars = 0,
			Rebirths = 0,
		}
		Rebirth.ApplyReset(data)
		expect.equal(#data.Creatures, 0)
	end)
end
