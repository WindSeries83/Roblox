local Config = require(script.Parent.Config)

local Season = {}

function Season.LevelFromXP(xp: number): number
	return math.clamp(math.floor(xp / Config.SEASON_XP_PER_LEVEL) + 1, 1, Config.SEASON_MAX_LEVEL)
end

function Season.XPForLevel(level: number): number
	return math.max(0, level - 1) * Config.SEASON_XP_PER_LEVEL
end

function Season.RewardFor(level: number, track: string)
	local essence = if track == "premium" then Config.SEASON_PREMIUM_ESSENCE else Config.SEASON_FREE_ESSENCE
	local reward = { Essence = essence[1] + essence[2] * level }
	if level == Config.SEASON_MAX_LEVEL then
		if track == "premium" then
			reward.Creature = Config.SEASON_EXCLUSIVE
			reward.Title = Config.SEASON_EXCLUSIVE_TITLE
		else
			reward.Title = Config.SEASON_FREE_TITLE
		end
	end
	return reward
end

function Season.CanClaim(season: any, level: number, track: string): boolean
	if level < 1 or level > Config.SEASON_MAX_LEVEL then
		return false
	end
	local claimed = if track == "premium" then season.ClaimedPremium else season.ClaimedFree
	if claimed[level] then
		return false
	end
	return Season.LevelFromXP(season.XP) >= level
end

return Season
