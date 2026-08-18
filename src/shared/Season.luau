local Config = require(script.Parent.Config)

local Season = {}

function Season.LevelFromXP(xp: number): number
	return math.clamp(math.floor(xp / Config.SEASON_XP_PER_LEVEL) + 1, 1, Config.SEASON_MAX_LEVEL)
end

function Season.XPForLevel(level: number): number
	return math.max(0, level - 1) * Config.SEASON_XP_PER_LEVEL
end

function Season.FreeReward(level: number): { Essence: number }
	local base, perLevel = Config.SEASON_FREE_ESSENCE[1], Config.SEASON_FREE_ESSENCE[2]
	return { Essence = base + perLevel * level }
end

function Season.PremiumReward(level: number): { Essence: number }
	local base, perLevel = Config.SEASON_PREMIUM_ESSENCE[1], Config.SEASON_PREMIUM_ESSENCE[2]
	return { Essence = base + perLevel * level }
end

-- Reward claimable at a level for a given track.
-- Track "free" grants essence; "premium" grants premium essence, and at max level
-- the exclusive creature + title.
function Season.RewardFor(level: number, track: string)
	if track == "premium" then
		local reward = Season.PremiumReward(level)
		if level == Config.SEASON_MAX_LEVEL then
			reward.Creature = Config.SEASON_EXCLUSIVE
			reward.Title = Config.SEASON_EXCLUSIVE_TITLE
		end
		return reward
	end
	local reward = Season.FreeReward(level)
	if level == Config.SEASON_MAX_LEVEL then
		reward.Title = Config.SEASON_FREE_TITLE
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
