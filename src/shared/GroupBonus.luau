local Config = require(script.Parent.Config)

return {
	Mult = function(isMember: boolean): number
		return if isMember then 1 + Config.GROUP_ESSENCE_BONUS else 1
	end,
}
