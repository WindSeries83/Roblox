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

	-- Conservation totale actée (rév. 26/08) : seuls les consommables et l'Essence sont perdus.
	t.test("ApplyReset conserve toutes les créatures et tous les objets", function()
		local data = {
			Creatures = { { Id = "a", Power = 10 }, { Id = "b", Power = 50 } },
			Items = { { Type = "Relic", Tier = 1 }, { Type = "Relic", Tier = 3 }, { Type = "Collar", Tier = 2 } },
			CompanionId = "b",
			Eggs = { { Id = "e" } },
			SanctuaryLevel = 4,
			Stars = 1,
			Rebirths = 0,
			SkillPoints = 0,
			Essence = 99999,
		}
		Rebirth.ApplyReset(data)
		expect.equal(#data.Creatures, 2)
		expect.equal(#data.Items, 3)
		expect.equal(data.CompanionId, "b")
		expect.equal(#data.Eggs, 0)
		expect.equal(data.SanctuaryLevel, 1)
		expect.equal(data.Stars, 2)
		expect.equal(data.Rebirths, 1)
		expect.equal(data.SkillPoints, 1)
		expect.equal(data.Essence, Config.STARTER_ESSENCE)
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

	-- Each rebirth grants one skill point.
	t.test("rebirth grants one skill point", function()
		local data = {
			Creatures = {},
			Eggs = {},
			Items = {},
			Stars = 0,
			Rebirths = 0,
			Essence = 0,
			SkillPoints = 0,
		}
		Rebirth.ApplyReset(data)
		expect.equal(data.SkillPoints, 1)
	end)
end
