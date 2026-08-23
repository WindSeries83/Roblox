return function(t)
	local expect = t.expect
	local Luck = require(game.ReplicatedStorage.Shared.Luck)
	local Config = require(game.ReplicatedStorage.Shared.Config)

	-- No bonuses combine to zero.
	t.test("combine with nothing yields zero", function()
		expect.equal(Luck.Combine(nil, nil, nil), 0)
	end)

	-- All sources stack additively.
	t.test("combine stacks all sources", function()
		expect.near(Luck.Combine(0.05, 0.35, 0.25, Config.VIP_LUCK_BONUS), 0.75)
	end)

	-- The hard cap bounds the total.
	t.test("combine respects the hard cap", function()
		expect.equal(Luck.Combine(1, 1, 1, 1), Config.LUCK_HARD_CAP)
	end)

	-- Nil expiry means never active.
	t.test("active with nil expiry is false", function()
		expect.falsy(Luck.Active(nil, 1000))
	end)

	-- Expiry boundary is exclusive.
	t.test("active expires exactly at the timestamp", function()
		expect.falsy(Luck.Active(1000, 1000))
		expect.truthy(Luck.Active(1001, 1000))
	end)

	-- Expiry is now plus duration.
	t.test("expiry adds duration to now", function()
		expect.equal(Luck.Expiry(1000, 600), 1600)
	end)

	-- Potion config values exist and stay sane.
	t.test("luck products are configured within cap", function()
		for _, product in { Config.LUCK_POTION_SMALL, Config.LUCK_POTION_BIG, Config.SERVER_BOOST } do
			expect.truthy(product.Bonus > 0 and product.Bonus < Config.LUCK_HARD_CAP)
			expect.truthy(product.Duration > 0)
		end
	end)
end
