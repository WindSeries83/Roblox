return function(t)
	local expect = t.expect
	local Config = require(game.ReplicatedStorage.Shared.Config)
	local PurchaseService = require(game.ServerScriptService.Services.PurchaseService)

	t.test("ResolveProduct finds a dev product by id", function()
		for _, def in Config.DEV_PRODUCTS do
			if def.Id ~= 0 then
				expect.equal(PurchaseService.ResolveProduct(def.Id), def)
			end
		end
	end)

	t.test("ResolveProduct returns nil for unknown or unset ids", function()
		expect.falsy(PurchaseService.ResolveProduct(0))
		expect.falsy(PurchaseService.ResolveProduct(123456789))
	end)

	t.test("ReceiptKey is stable per player and purchase", function()
		expect.equal(PurchaseService.ReceiptKey(42, "abc"), "42_abc")
		expect.equal(PurchaseService.ReceiptKey(42, "abc"), PurchaseService.ReceiptKey(42, "abc"))
	end)

	t.test("PassEffect maps every gamepass to its flag", function()
		for key, def in Config.GAMEPASSES do
			local effect = PurchaseService.PassEffect(key)
			expect.truthy(effect)
			expect.truthy(def.Name)
			expect.equal(effect.Flag, key)
		end
	end)

	t.test("PassEffect gives essence only for the starter bundle", function()
		expect.equal(PurchaseService.PassEffect("MoreSlots").Essence, 0)
		expect.equal(PurchaseService.PassEffect("PassiveBoost").Essence, 0)
		expect.equal(PurchaseService.PassEffect("AutoHatch").Essence, 0)
		expect.truthy(PurchaseService.PassEffect("StarterBundle").Essence > 0)
	end)

	t.test("PassEffect maps VIP to its flag", function()
		local effect = PurchaseService.PassEffect("VIP")
		expect.equal(effect.Flag, "VIP")
		expect.equal(effect.Essence, 0)
	end)

	t.test("StarterBundle bundles a mutated Rare creature", function()
		local effect = PurchaseService.PassEffect("StarterBundle")
		expect.equal(effect.Creature.Rarity, "Rare")
		expect.equal(effect.Creature.Mutation, "Shadow")
		expect.equal(effect.Essence, 2000)
	end)

	t.test("PassEffect rejects unknown passes", function()
		expect.falsy(PurchaseService.PassEffect("Nope"))
	end)
end
