local DataStoreService = game:GetService("DataStoreService")

local SafeStore = {}

-- Retourne le DataStore réel, ou un stub no-op si l'accès est indisponible
-- (Studio non publié). fallback est la valeur du stub pour GetAsync et le point
-- de départ de UpdateAsync.
function SafeStore.Get(name: string, fallback: any)
	local ok, store = pcall(function()
		return DataStoreService:GetDataStore(name)
	end)
	if ok then
		return store
	end
	return {
		GetAsync = function()
			return fallback
		end,
		SetAsync = function() end,
		UpdateAsync = function(_, _, transform)
			return transform(fallback)
		end,
	}
end

return SafeStore
