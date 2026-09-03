return function(t)
	local LiveOps = require(game.ReplicatedStorage.Shared.LiveOps)
	local expect = t.expect

	t.test("registers and resolves a bounded event", function()
		local id = "TestEvent_" .. tostring(os.clock())
		local event = {
			Id = id,
			Kind = "Event",
			StartAt = 100,
			EndAt = 200,
			Variant = "Aurora",
			Version = 1,
			Enabled = true,
		}
		expect.truthy(LiveOps.Register(event))
		expect.equal(LiveOps.Get(id), event)
		expect.falsy(LiveOps.IsActive(event, 99))
		expect.truthy(LiveOps.IsActive(event, 100))
		expect.falsy(LiveOps.IsActive(event, 200))
	end)

	t.test("rejects duplicate or inverted definitions", function()
		local id = "TestDuplicate_" .. tostring(os.clock())
		local event = { Id = id, Kind = "Event", StartAt = 1, EndAt = 2, Version = 1, Enabled = true }
		expect.truthy(LiveOps.Register(event))
		expect.falsy(LiveOps.Register(event))
		expect.falsy(
			LiveOps.Register({ Id = id .. "_bad", Kind = "Event", StartAt = 2, EndAt = 2, Version = 1, Enabled = true })
		)
	end)

	t.test("disabled catalog entries never activate", function()
		local event = {
			Id = "Disabled_" .. tostring(os.clock()),
			Kind = "Event",
			StartAt = 1,
			EndAt = 2,
			Version = 1,
			Enabled = false,
		}
		expect.truthy(LiveOps.Register(event))
		expect.falsy(LiveOps.IsActive(event, 1))
	end)
end
