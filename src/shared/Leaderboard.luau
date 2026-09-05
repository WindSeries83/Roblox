--!strict

local Leaderboard = {}

function Leaderboard.IsLightEligible(data: any): boolean
	if type(data) ~= "table" then
		return false
	end
	local entitlements = data.Entitlements
	if type(entitlements) == "table" then
		for key, enabled in entitlements do
			if enabled == true and key ~= "StarterBundle" then
				return false
			end
		end
	end
	local purchases = data.PaidPurchases
	if type(purchases) ~= "table" then
		return true
	end
	for key, enabled in purchases do
		if enabled == true and key ~= "Pass_StarterBundle" then
			return false
		end
	end
	return true
end

return Leaderboard
