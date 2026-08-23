local Config = require(script.Parent.Config)

local Luck = {}

-- Combine tous les bonus de chance du joueur en un seul nombre borne.
-- La somme est additive, le plafond global protege l'economie (spec §2.4).
function Luck.Combine(...): number
	local total = 0
	for _, bonus in { ... } do
		total += bonus or 0
	end
	return math.min(total, Config.LUCK_HARD_CAP)
end

function Luck.Active(expiryAt: number?, now: number): boolean
	return expiryAt ~= nil and expiryAt > now
end

function Luck.Expiry(now: number, durationSeconds: number): number
	return now + durationSeconds
end

return Luck
