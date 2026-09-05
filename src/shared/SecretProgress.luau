--!strict

local SecretProgress = {}

local WORLD_IDS = { "TwilightGrove", "AshForge", "GalePeaks", "NyxAbyss" }

function SecretProgress.Count(discoveries: any): number
	if type(discoveries) ~= "table" then
		return 0
	end
	local count = 0
	for _, worldId in WORLD_IDS do
		if discoveries[worldId] == true then
			count += 1
		end
	end
	return count
end

function SecretProgress.All(discoveries: any): boolean
	return SecretProgress.Count(discoveries) == #WORLD_IDS
end

return SecretProgress
