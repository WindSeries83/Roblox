--!strict

local PurchaseLedger = {}

local function Clone(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, item in pairs(value) do
		copy[key] = Clone(item)
	end
	return copy
end

function PurchaseLedger.Snapshot(data: { [any]: any }): { [any]: any }
	return Clone(data)
end

function PurchaseLedger.Restore(data: { [any]: any }, snapshot: { [any]: any })
	for key in pairs(data) do
		data[key] = nil
	end
	for key, value in pairs(snapshot) do
		data[key] = Clone(value)
	end
end

function PurchaseLedger.MarkApplied(
	receipts: { [string]: boolean },
	order: { string },
	key: string,
	maxEntries: number
): boolean
	if maxEntries < 1 then
		return false
	end
	if receipts[key] then
		return false
	end
	receipts[key] = true
	table.insert(order, key)
	while #order > maxEntries do
		local oldest = table.remove(order, 1)
		if oldest then
			receipts[oldest] = nil
		end
	end
	return true
end

function PurchaseLedger.RemoveApplied(receipts: { [string]: boolean }, order: { string }, key: string): boolean
	if not receipts[key] then
		return false
	end
	receipts[key] = nil
	for index = #order, 1, -1 do
		if order[index] == key then
			table.remove(order, index)
			break
		end
	end
	return true
end

-- Stages the receipt marker before SaveProfile so the confirmed save contains it.
-- The rollback callback restores all grant mutations when either stage fails.
function PurchaseLedger.Apply(
	receipts: { [string]: boolean },
	order: { string },
	key: string,
	maxEntries: number,
	grant: any,
	save: any
): boolean
	if receipts[key] then
		return true
	end

	local okGrant, granted, rollback = pcall(grant)
	local function undo()
		if type(rollback) == "function" then
			pcall(rollback)
		end
	end
	if not okGrant or not granted then
		undo()
		return false
	end

	if not PurchaseLedger.MarkApplied(receipts, order, key, maxEntries) then
		undo()
		return false
	end
	local okSave, saved = pcall(save)
	if not okSave or not saved then
		PurchaseLedger.RemoveApplied(receipts, order, key)
		undo()
		return false
	end
	return true
end

return PurchaseLedger
