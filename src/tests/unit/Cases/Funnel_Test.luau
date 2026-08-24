return function(t)
	local expect = t.expect
	local Funnel = require(game.ReplicatedStorage.Shared.Funnel)

	t.test("stamp is idempotent", function()
		local f = { FirstHatchAt = 0 }
		Funnel.Stamp(f, "FirstHatchAt", 100)
		Funnel.Stamp(f, "FirstHatchAt", 999)
		expect.equal(f.FirstHatchAt, 100)
	end)

	t.test("stamp fills missing keys", function()
		local f = {}
		Funnel.Stamp(f, "FirstPurchaseAt", 42)
		expect.equal(f.FirstPurchaseAt, 42)
	end)
end
