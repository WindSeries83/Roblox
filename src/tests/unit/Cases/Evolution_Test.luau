return function(t)
	local expect = t.expect
	local Evolution = require(game.ReplicatedStorage.Shared.Evolution)
	local Config = require(game.ReplicatedStorage.Shared.Config)

	local function MakeCreature(props)
		local creature = {
			Id = "test",
			SpeciesId = "Moonhowl",
			Rarity = "Rare",
			Mutation = false,
			Level = 1,
			XP = 0,
			Stage = 1,
			Equipment = {},
			MaxLevel = Config.BASE_MAX_LEVEL,
		}
		for key, value in props do
			creature[key] = value
		end
		return creature
	end

	-- XP to next level scales linearly with the current level.
	t.test("xp to next level scales linearly", function()
		expect.equal(Evolution.XPToNext(1), 60)
		expect.equal(Evolution.XPToNext(5), 300)
	end)

	-- Adding enough XP levels the creature up and recomputes power.
	t.test("adding enough xp levels up", function()
		local creature = MakeCreature({})
		local leveled = Evolution.AddXP(creature, 60)
		expect.truthy(leveled)
		expect.equal(creature.Level, 2)
		expect.equal(creature.XP, 0)
	end)

	-- XP carries over across multiple levels.
	t.test("xp carries over across multiple levels", function()
		local creature = MakeCreature({})
		Evolution.AddXP(creature, 60 + 120 + 30)
		expect.equal(creature.Level, 3)
		expect.equal(creature.XP, 30)
	end)

	-- XP is capped at the max level.
	t.test("xp is capped at max level", function()
		local creature = MakeCreature({})
		Evolution.AddXP(creature, 1e9)
		expect.equal(creature.Level, creature.MaxLevel)
		expect.equal(creature.XP, 0)
	end)

	-- Hearts raise the max level.
	t.test("hearts raise the max level", function()
		local creature = MakeCreature({
			Equipment = {
				{ Id = "h1", Type = "Heart", Tier = 1 },
				{ Id = "h2", Type = "Heart", Tier = 3 },
			},
		})
		expect.equal(Evolution.MaxLevelFor(creature), Config.BASE_MAX_LEVEL + 5 + 50)
	end)

	-- Stage multiplies power.
	t.test("stage multiplies power", function()
		local base = MakeCreature({})
		local evolved = MakeCreature({ Stage = 2 })
		expect.near(Evolution.ComputePower(evolved) / Evolution.ComputePower(base), 2)
	end)

	-- Evolving requires the level threshold.
	t.test("evolving requires the level threshold", function()
		local low = MakeCreature({})
		local ok = Evolution.CanEvolve(low, 1e9)
		expect.falsy(ok)

		local ready = MakeCreature({ Level = 10 })
		expect.truthy(Evolution.CanEvolve(ready, 1e9))
	end)

	-- Evolving requires essence.
	t.test("evolving requires essence", function()
		local creature = MakeCreature({ Level = 10 })
		expect.falsy(Evolution.CanEvolve(creature, 0))
	end)

	-- Stage 4 requires an equipped relic.
	t.test("stage four requires an equipped relic", function()
		local creature = MakeCreature({ Stage = 3, Level = 50 })
		local ok, reason = Evolution.CanEvolve(creature, 1e9)
		expect.falsy(ok)
		expect.truthy(string.find(reason, "Relique") ~= nil)

		table.insert(creature.Equipment, { Id = "r1", Type = "Relic", Tier = 1 })
		expect.truthy(Evolution.CanEvolve(creature, 1e9))
	end)

	-- Consuming a relic removes it from equipment.
	t.test("consume relic removes it from equipment", function()
		local creature = MakeCreature({
			Stage = 3,
			Equipment = { { Id = "r1", Type = "Relic", Tier = 1 }, { Id = "h1", Type = "Heart", Tier = 1 } },
		})
		expect.truthy(Evolution.ConsumeRelic(creature))
		expect.equal(#creature.Equipment, 1)
		expect.equal(creature.Equipment[1].Id, "h1")
	end)
end
