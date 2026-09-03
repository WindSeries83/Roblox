return function(t)
	local Worlds = require(game.ReplicatedStorage.Shared.Worlds)
	local expect = t.expect

	-- Le lancement contient exactement les quatre régions validées.
	t.test("exposes the four launch worlds", function()
		expect.equal(#Worlds.All, 4)
		expect.equal(Worlds.All[1].Id, "TwilightGrove")
		expect.equal(Worlds.All[4].Id, "NyxAbyss")
	end)

	-- Chaque monde partage cinq étapes puis un boss.
	t.test("uses five stages and one boss per world", function()
		for _, world in Worlds.All do
			expect.equal(#world.Stages, 5)
			expect.truthy(world.Boss.SpeciesId)
			expect.truthy(world.Boss.Reward.Essence > 0)
			expect.truthy(world.Rush.TargetSeconds > 0)
			expect.truthy(world.Rush.Reward.Essence > 0)
		end
	end)

	t.test("matches the shared stage contract and keeps world identities distinct", function()
		expect.truthy(Worlds.Validate())
		expect.equal(Worlds.All[1].Stages[1].Template, "Wave")
		expect.equal(Worlds.All[2].Stages[2].Template, "Choice")
		expect.equal(Worlds.All[3].Stages[3].Template, "Elite")
		expect.falsy(Worlds.All[1].Stages[1].Reward.Essence == Worlds.All[2].Stages[1].Reward.Essence)
		expect.falsy(Worlds.All[2].Boss.SpeciesId == Worlds.All[3].Boss.SpeciesId)
	end)

	-- Le prochain checkpoint avance jusqu'au boss puis s'arrête.
	t.test("advances checkpoints through the boss", function()
		expect.equal(Worlds.NextStage({}, "TwilightGrove"), 1)
		expect.equal(Worlds.NextStage({ TwilightGrove = { HighestStage = 4 } }, "TwilightGrove"), 5)
		expect.equal(Worlds.NextStage({ TwilightGrove = { HighestStage = 5 } }, "TwilightGrove"), Worlds.BOSS_STAGE)
		expect.equal(
			Worlds.NextStage({ TwilightGrove = { HighestStage = 5, BossDefeated = true } }, "TwilightGrove"),
			nil
		)
	end)

	-- Un monde exige les étoiles et le boss du monde précédent.
	t.test("gates later worlds by stars and previous boss", function()
		expect.truthy(Worlds.CanEnter({}, 0, "TwilightGrove"))
		expect.falsy(Worlds.CanEnter({}, 1, "AshForge"))
		expect.truthy(Worlds.CanEnter({ TwilightGrove = { BossDefeated = true } }, 1, "AshForge"))
		expect.falsy(Worlds.CanEnter({ AshForge = { BossDefeated = true } }, 1, "GalePeaks"))
		expect.truthy(Worlds.CanEnter({ AshForge = { BossDefeated = true } }, 2, "GalePeaks"))
	end)

	t.test("records checkpoints and boss victories idempotently", function()
		local progress = {}
		expect.truthy(Worlds.RecordVictory(progress, "TwilightGrove", 1))
		expect.equal(progress.TwilightGrove.HighestStage, 1)
		expect.falsy(progress.TwilightGrove.BossDefeated)
		expect.falsy(Worlds.RecordVictory(progress, "TwilightGrove", 1))
		expect.truthy(Worlds.RecordVictory(progress, "TwilightGrove", Worlds.BOSS_STAGE))
		expect.truthy(progress.TwilightGrove.BossDefeated)
	end)

	t.test("checkpoint rewards are ordered", function()
		for _, world in Worlds.All do
			for index, stage in world.Stages do
				expect.truthy(stage.Reward.Essence > 0)
				expect.truthy(index == stage.Index)
			end
		end
	end)
end
