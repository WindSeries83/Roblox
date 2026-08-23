return function(t)
	local expect = t.expect
	local Pack = require(game.ReplicatedStorage.Shared.Pack)

	t.test("meute mult caps at three friends", function()
		expect.truthy(math.abs(Pack.Mult(0) - 1) < 1e-9)
		expect.truthy(math.abs(Pack.Mult(1) - 1.1) < 1e-9)
		expect.truthy(math.abs(Pack.Mult(2) - 1.2) < 1e-9)
		expect.truthy(math.abs(Pack.Mult(3) - 1.3) < 1e-9)
		expect.truthy(math.abs(Pack.Mult(9) - 1.3) < 1e-9)
	end)

	t.test("negative count clamps to base", function()
		expect.truthy(math.abs(Pack.Mult(-2) - 1) < 1e-9)
	end)
end
