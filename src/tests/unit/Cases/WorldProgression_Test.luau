return function(t)
	local expect = t.expect
	local Config = require(game.ReplicatedStorage.Shared.Config)
	local Gameplay = require(game.ReplicatedStorage.Shared.Gameplay)
	local GroupBonus = require(game.ReplicatedStorage.Shared.GroupBonus)
	local Species = require(game.ReplicatedStorage.Shared.Data.Species)
	local WorldProgression = require(game.ReplicatedStorage.Shared.WorldProgression)

	t.test("rebirth unlocks World2 and Rush grants once", function()
		local data = { Rebirths = 1, CurrentWorld = "World1", WorldUnlocks = { World1 = true } }
		WorldProgression.SyncUnlocks(data)
		expect.equal(WorldProgression.CanEnter(data, "World2"), true)
		expect.equal(WorldProgression.RecordRush(data, "World2", Config.WORLDS.World2.Rush.TargetSeconds + 1), false)
		expect.equal(data.RushRewards, nil)
		expect.equal(WorldProgression.RecordRush(data, "World2", Config.WORLDS.World2.Rush.TargetSeconds), true)
		expect.equal(WorldProgression.RecordRush(data, "World2", 60), false)
		expect.equal(data.RushBest.World2, 60)
	end)

	t.test("world pools respect exclusive species", function()
		for _ = 1, 50 do
			local roll = Gameplay.RollEgg("CommonEgg", 0, { Uncommon = 100 }, "World1")
			expect.equal(Species[roll.SpeciesId].World, nil)
		end
	end)

	t.test("catalog contains thirty species", function()
		local count = 0
		for _ in Species do
			count += 1
		end
		expect.equal(count, 30)
	end)

	t.test("group bonus is bounded to ten percent", function()
		expect.equal(GroupBonus.Mult(false), 1)
		expect.equal(GroupBonus.Mult(true), 1.1)
	end)
end
