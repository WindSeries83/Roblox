local Config = require(script.Parent.Config)

local Orbs = {}

-- Prochaine apparition d'orbe : due time, ou immédiatement si déjà dépassé.
function Orbs.NextSpawnAt(lastAt: number, now: number, interval: number): number
	local due = lastAt + interval
	return if now >= due then now else due
end

-- Un orbe vaut ORB_REWARD_SECONDS de rendement, minimum 1.
function Orbs.Reward(rate: number): number
	return math.max(1, math.floor(rate * Config.ORB_REWARD_SECONDS))
end

-- Plafond horaire : les claims vieux de plus d'une heure ne comptent plus.
function Orbs.CanClaim(claims: { number }, now: number, maxPerHour: number): (boolean, string?)
	local recent = 0
	for _, at in claims do
		if now - at < 3600 then
			recent += 1
		end
	end
	if recent >= maxPerHour then
		return false, "RateLimited"
	end
	return true, nil
end

return Orbs
