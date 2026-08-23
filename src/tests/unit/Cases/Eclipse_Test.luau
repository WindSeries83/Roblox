return function(t)
	local expect = t.expect
	local Eclipse = require(game.ReplicatedStorage.Shared.Eclipse)

	t.test("window is active during first duration seconds", function()
		for now = 0, 599 do
			expect.truthy(Eclipse.IsActive(now, 7200, 600))
		end
		expect.falsy(Eclipse.IsActive(600, 7200, 600))
		expect.falsy(Eclipse.IsActive(7199, 7200, 600))
	end)

	t.test("next boundary is exact", function()
		expect.equal(Eclipse.NextBoundary(0, 7200), 7200)
		expect.equal(Eclipse.NextBoundary(1, 7200), 7200)
		expect.equal(Eclipse.NextBoundary(7200, 7200), 14400)
		expect.equal(Eclipse.NextBoundary(10000, 7200), 14400)
	end)

	t.test("wraps across intervals", function()
		expect.truthy(Eclipse.IsActive(7300, 7200, 600))
	end)
end
