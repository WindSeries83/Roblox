return function(t)
	local expect = t.expect
	local AnalyticsEvent = require(game.ReplicatedStorage.Shared.AnalyticsEvent)

	t.test("creates stable non-empty events", function()
		local event = AnalyticsEvent.New("first_hatch", { Source = "FTUE" }, 123)
		expect.truthy(event)
		expect.equal(event.Version, 1)
		expect.equal(event.Timestamp, 123)
		expect.truthy(AnalyticsEvent.Validate(event))
	end)

	t.test("rejects malformed events", function()
		expect.falsy(AnalyticsEvent.New("", {}))
		expect.falsy(AnalyticsEvent.Validate({ Name = "x", Version = 2, Timestamp = 1, Properties = {} }))
	end)
end
