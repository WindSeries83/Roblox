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

	t.test("vip expires from server time and stacks from active expiry", function()
		expect.truthy(Vip.IsActive(130, 100))
		expect.falsy(Vip.IsActive(100, 100))
		expect.equal(Vip.Extend(nil, 100, 30), 130)
		expect.equal(Vip.Extend(120, 100, 30), 150)
	end)
end
