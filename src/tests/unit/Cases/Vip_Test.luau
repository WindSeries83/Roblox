return function(t)
	local expect = t.expect
	local Vip = require(game.ReplicatedStorage.Shared.Vip)

	t.test("vip daily gift due when last date differs", function()
		expect.truthy(Vip.GiftDue("", "2026-08-23"))
		expect.truthy(Vip.GiftDue("2026-08-22", "2026-08-23"))
	end)

	t.test("vip daily gift not due on same calendar day", function()
		expect.falsy(Vip.GiftDue("2026-08-23", "2026-08-23"))
	end)
end
