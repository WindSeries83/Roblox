return function(t)
	local expect = t.expect
	local SessionLuck = require(game.ServerScriptService.Services.SessionLuck)

	t.test("no luck before one hour", function()
		expect.equal(SessionLuck.Compute(0), 0)
	end)

	t.test("one hour grants five percent", function()
		expect.near(SessionLuck.Compute(1), 0.05, 1e-9)
	end)

	t.test("five hours reach the cap", function()
		expect.near(SessionLuck.Compute(5), 0.25, 1e-9)
	end)

	t.test("luck caps at twenty-five percent", function()
		expect.near(SessionLuck.Compute(10), 0.25, 1e-9)
	end)

	t.test("negative elapsed time yields zero", function()
		expect.equal(SessionLuck.Compute(-3), 0)
	end)
end
