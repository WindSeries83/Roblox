local Config = require(script.Parent.Config)
local Gameplay = require(script.Parent.Gameplay)

local Ticker = {}

-- Inbound : sélectionne le prochain payload à afficher. Les rangs hauts
-- passent sans throttle, le reste est limité (TICKER_MIN_INTERVAL).
function Ticker.NextToDisplay(queue: { any }, now: number, lastShownAt: number): (any?, number)
	local bestIndex, bestRank = nil, -1
	for i, item in queue do
		local r = Gameplay.RarityRank(item.Rarity or "")
		if r > bestRank then
			bestRank = r
			bestIndex = i
		end
	end
	if not bestIndex then
		return nil, lastShownAt
	end
	if bestRank >= Config.TICKER_BYPASS_RANK then
		return table.remove(queue, bestIndex), now
	end
	if now - lastShownAt < Config.TICKER_MIN_INTERVAL then
		return nil, lastShownAt
	end
	return table.remove(queue, bestIndex), now
end

-- Clé de semaine monotone (epoch / 7 jours) pour le compteur mondial.
function Ticker.WeekKey(now: number): string
	return "W" .. math.floor(now / 604800)
end

function Ticker.IsNewWeek(previousKey: string, now: number): boolean
	return previousKey ~= Ticker.WeekKey(now)
end

return Ticker
