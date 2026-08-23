local Config = require(script.Parent.Config)

-- Bonus meute (bible §4.C) : multiplicateur d'Essence selon les amis présents.
local Pack = {}

function Pack.Mult(count: number): number
	return 1 + Config.PACK_BONUS_PER_FRIEND * math.clamp(count, 0, Config.PACK_MAX_FRIENDS)
end

return Pack
