--!strict

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local SafeStore = {}

-- Cache mémoire par nom de store (Studio non publié : comportement cohérent
-- en session pour tester les flux — claim marché, index — sans DataStore réel).
local memories: { [string]: { [any]: any } } = {}

-- Retourne le DataStore réel hors Studio, ou un stub mémoire en Studio et si
-- l'accès est indisponible. fallback est la valeur initiale du stub.
function SafeStore.Get(name: string, fallback: any)
	if not RunService:IsStudio() then
		local ok, store = pcall(function()
			return DataStoreService:GetDataStore(name)
		end)
		if ok then
			return store
		end
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
		RemoveAsync = function(_, key)
			stored[key] = nil
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
