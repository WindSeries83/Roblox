--!strict

local PublicWall = {}

function PublicWall.Upsert(entries: any, item: any, limit: number): { any }
	local result = {}
	local maxEntries = math.max(1, math.floor(limit))
	local itemId = if type(item) == "table" then item.Id else nil
	if type(itemId) ~= "string" or itemId == "" then
		return result
	end

	if type(entries) == "table" then
		for _, entry in entries do
			if type(entry) == "table" and type(entry.Id) == "string" and entry.Id ~= itemId then
				table.insert(result, entry)
			end
		end
	end
	table.insert(result, 1, item)
	while #result > maxEntries do
		table.remove(result)
	end
	return result
end

return PublicWall
