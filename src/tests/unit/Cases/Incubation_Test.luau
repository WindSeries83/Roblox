return function(t)
	local expect = t.expect
	local Incubation = require(game.ReplicatedStorage.Shared.Incubation)

	t.test("la V1 ne possede qu'une couveuse active", function()
		expect.equal(Incubation.MAX_PLACED, 1)
	end)

	t.test("le slot reste a rayon constant et a plat", function()
		local origin = Vector3.new(10, 5, -3)
		local positions = {}
		for i = 1, Incubation.MAX_PLACED do
			local pos = Incubation.SlotCFrame(origin, i).Position
			expect.near((pos - origin).Magnitude, Incubation.SLOT_RADIUS, 0.01)
			expect.near(pos.Y, origin.Y, 0.01)
			table.insert(positions, pos)
		end
		expect.equal(#positions, 1)
	end)

	t.test("Duration combine tier, rarete et puissance", function()
		expect.equal(Incubation.Duration("RareEgg", "Rare", 27), 90 + 45 + 10)
		expect.equal(Incubation.Duration("CommonEgg", "Common", 0), 30)
		expect.equal(Incubation.Duration("LegendaryEgg", "Mythic", 10), 360 + 300 + 5)
	end)

	t.test("Duration borne le bonus de puissance", function()
		expect.equal(Incubation.Duration("CommonEgg", "Common", -1), 30)
		expect.equal(Incubation.Duration("CommonEgg", "Common", 1000), 150)
	end)

	t.test("la premiere incubation dure cinq secondes", function()
		expect.equal(Incubation.Duration("CommonEgg", "Rare", 999, true), 5)
	end)

	t.test("State distingue vide, incubation et pret", function()
		expect.equal(Incubation.State(nil, 100), "Empty")
		expect.equal(Incubation.State({ ReadyAt = 150 }, 149), "Incubating")
		expect.equal(Incubation.State({ ReadyAt = 150 }, 150), "Ready")
	end)

	t.test("CanStart refuse une couveuse deja active", function()
		expect.truthy(Incubation.CanStart(nil, "egg-a"))
		expect.falsy(Incubation.CanStart({ EggId = "egg-a" }, "egg-b"))
	end)

	t.test("IsRecord valide une reservation persistable", function()
		local record = {
			IncubatorId = "Incubator-1",
			EggId = "egg-1",
			StartedAt = 100,
			ReadyAt = 130,
			QueueIndex = 1,
			ReservedHatch = { Species = "Emberling", Rarity = "Common", Mutation = nil, Power = 12 },
		}
		expect.truthy(Incubation.IsRecord(record))
		record.ReadyAt = 99
		expect.falsy(Incubation.IsRecord(record))
	end)

	t.test("CanClaim renvoie des raisons francaises stables", function()
		local ok, reason = Incubation.CanClaim(nil, 100, 0, 10)
		expect.falsy(ok)
		expect.equal(reason, "Aucune incubation")

		local okIncubating, reasonIncubating = Incubation.CanClaim({ ReadyAt = 150 }, 100, 0, 10)
		expect.falsy(okIncubating)
		expect.equal(reasonIncubating, "Incubation en cours")

		local okFull, reasonFull = Incubation.CanClaim({ ReadyAt = 100 }, 100, 10, 10)
		expect.falsy(okFull)
		expect.equal(reasonFull, "Sanctuaire plein")

		local okReady, reasonReady = Incubation.CanClaim({ ReadyAt = 100 }, 100, 9, 10)
		expect.truthy(okReady)
		expect.falsy(reasonReady)
	end)
end
