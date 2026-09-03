return function(t)
	local expect = t.expect
	local Ticker = require(game.ReplicatedStorage.Shared.Ticker)

	-- Empty queue yields nothing and keeps the last shown time.
	t.test("empty queue shows nothing", function()
		local item, last = Ticker.NextToDisplay({}, 1000, 500)
		expect.falsy(item)
		expect.equal(last, 500)
	end)

	-- Below the interval nothing shows unless it bypasses by rank.
	t.test("throttle blocks low ranks before interval", function()
		local queue = { { Rarity = "Rare" } }
		local item, last = Ticker.NextToDisplay(queue, 1000, 998)
		expect.falsy(item)
		expect.equal(last, 998)
	end)

	-- After the interval the highest-rank item comes out first.
	t.test("after interval picks the highest rank", function()
		local queue = { { Rarity = "Rare" }, { Rarity = "Epic" } }
		local item, last = Ticker.NextToDisplay(queue, 1000, 990)
		expect.equal(item.Rarity, "Epic")
		expect.equal(last, 1000)
		expect.equal(#queue, 1)
	end)

	-- Legendary and above bypass the throttle entirely.
	t.test("legendary bypasses the throttle", function()
		local queue = { { Rarity = "Legendary" } }
		local item = Ticker.NextToDisplay(queue, 1000, 999)
		expect.truthy(item)
		expect.equal(item.Rarity, "Legendary")
	end)

	-- Week key is stable within a week and grows over time.
	t.test("week key groups by seven-day buckets", function()
		expect.equal(Ticker.WeekKey(0), "W0")
		expect.equal(Ticker.WeekKey(604800 - 1), "W0")
		expect.equal(Ticker.WeekKey(604800), "W1")
	end)

	t.test("week rollover is detected for persisted global state", function()
		expect.falsy(Ticker.IsNewWeek("W0", 604800 - 1))
		expect.truthy(Ticker.IsNewWeek("W0", 604800))
	end)
end
