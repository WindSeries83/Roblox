--!strict

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

	t.test("adds the stable session envelope", function()
		local properties = AnalyticsEvent.WithContext({ Name = "FTUE" }, 42, "session-1", 123)
		expect.equal(properties.user_id, 42)
		expect.equal(properties.session_id, "session-1")
		expect.equal(properties.at, 123)
		expect.equal(properties.schema_version, 1)
		expect.equal(properties.Name, "FTUE")
	end)

	t.test("rejects malformed events", function()
		expect.falsy(AnalyticsEvent.New("", {}))
		expect.falsy(AnalyticsEvent.Validate({ Name = "x", Version = 2, Timestamp = 1, Properties = {} }))
	end)

	t.test("exports categorical breakdowns without player or transaction identifiers", function()
		local fields = AnalyticsEvent.Dimensions({
			Rarity = "Rare",
			Mutation = "Shadow",
			Source = "Purchase",
			user_id = 42,
			session_id = "private",
			ListingId = "unique",
		})
		expect.equal(fields[1], "Rare")
		expect.equal(fields[2], "Shadow")
		expect.equal(fields[3], "Purchase")
		local count = 0
		for _ in fields do
			count += 1
		end
		expect.equal(count, 3)
		expect.equal(next(AnalyticsEvent.Dimensions({ Rarity = {}, Source = "" })), nil)
	end)
end
