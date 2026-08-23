local Config = require(script.Parent.Config)

local Streak = {}

function Streak.ToDayNumber(dateStr: string): number
	local year = tonumber(string.sub(dateStr, 1, 4))
	local month = tonumber(string.sub(dateStr, 6, 7))
	local day = tonumber(string.sub(dateStr, 9, 10))
	assert(year and month and day, `Invalid date string: {dateStr}`)
	return math.floor(os.time({ year = year, month = month, day = day, hour = 12 }) / 86400)
end

-- Retourne le nouveau streak et l'index de récompense (1..#STREAK_REWARDS) si une
-- récompense est due ; index nil si le joueur est déjà venu aujourd'hui.
function Streak.Evaluate(today: string, lastDate: string?, currentStreak: number): (number, number?)
	if lastDate == today then
		return currentStreak, nil
	end
	local consecutive = false
	if lastDate ~= nil and lastDate ~= "" then
		consecutive = Streak.ToDayNumber(today) - Streak.ToDayNumber(lastDate) == 1
	end
	local streak = if consecutive then currentStreak + 1 else 1
	return streak, ((streak - 1) % #Config.STREAK_REWARDS) + 1
end

return Streak
