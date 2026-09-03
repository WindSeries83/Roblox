--!strict

local Config = require(script.Parent.Config)

local RiftDifficulty = {}

function RiftDifficulty.For(power: number, tutorial: boolean)
	if tutorial then
		return {
			GuardianHP = Config.RIFT_TUTORIAL_GUARDIAN_BASE_HP + power * Config.RIFT_TUTORIAL_GUARDIAN_HP_PER_POWER,
			GuardianDamage = Config.RIFT_TUTORIAL_GUARDIAN_DAMAGE,
		}
	end
	return {
		GuardianHP = Config.RIFT_GUARDIAN_BASE_HP + power * Config.RIFT_GUARDIAN_HP_PER_POWER,
		GuardianDamage = Config.RIFT_GUARDIAN_DAMAGE,
	}
end

return RiftDifficulty
