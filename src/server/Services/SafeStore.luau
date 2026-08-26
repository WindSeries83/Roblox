local DataStoreService = game:GetService("DataStoreService")

local SafeStore = {}

-- Cache mémoire par nom de store (Studio non publié : comportement cohérent
-- en session pour tester les flux — claim marché, index — sans DataStore réel).
local memories: { [string]: { [any]: any } } = {}

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
	local stored = memories[name]
	if not stored then
		stored = {}
		memories[name] = stored
	end
	return {
		GetAsync = function(_, key)
			return stored[key] or fallback
		end,
		SetAsync = function(_, key, value)
			stored[key] = value -- value nil supprime la clé
		end,
		UpdateAsync = function(_, key, transform)
			local old = stored[key] or fallback
			local new = transform(old)
			if new ~= nil then
				stored[key] = new
			end
			return new
		end,
	}
end

return SafeStore
