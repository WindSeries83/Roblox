return function(t)
	local expect = t.expect
	local PurchaseLedger = require(game.ReplicatedStorage.Shared.PurchaseLedger)

	t.test("receipt replay is a no-op and cache stays bounded", function()
		local receipts = {}
		local order = {}
		expect.truthy(PurchaseLedger.MarkApplied(receipts, order, "a", 2))
		expect.falsy(PurchaseLedger.MarkApplied(receipts, order, "a", 2))
		expect.truthy(PurchaseLedger.MarkApplied(receipts, order, "b", 2))
		expect.truthy(PurchaseLedger.MarkApplied(receipts, order, "c", 2))
		expect.falsy(receipts.a)
		expect.truthy(receipts.b)
		expect.truthy(receipts.c)
	end)

	t.test("save failure rolls back the grant and replay grants once", function()
		local receipts = {}
		local order = {}
		local essence = 0
		local grants = 0
		local saves = 0

		local function process(saveOk)
			local before = essence
			return PurchaseLedger.Apply(receipts, order, "receipt", 10, function()
				grants += 1
				essence += 100
				return true, function()
					essence = before
				end
			end, function()
				saves += 1
				expect.truthy(receipts.receipt)
				return saveOk
			end)
		end

		expect.falsy(process(false))
		expect.equal(essence, 0)
		expect.falsy(receipts.receipt)
		expect.equal(#order, 0)
		expect.equal(saves, 1)

		expect.truthy(process(true))
		expect.equal(essence, 100)
		expect.equal(grants, 2)
		expect.equal(saves, 2)
		expect.truthy(PurchaseLedger.Apply(receipts, order, "receipt", 10, function()
			grants += 1
			return true
		end, function()
			return true
		end))
		expect.equal(essence, 100)
		expect.equal(grants, 2)
	end)
end
