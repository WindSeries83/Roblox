local DuelSim = {}

-- Deterministic static duel resolution.
-- winChance = attack / (attack + defense); seeded roll decides.
function DuelSim.Resolve(attackPower: number, defensePower: number, seed: number): boolean
	local total = attackPower + defensePower
	if total <= 0 then
		return false
	end
	local roll = Random.new(seed):NextNumber()
	return roll < attackPower / total
end

function DuelSim.TeamPower(team: { any }): number
	local total = 0
	for _, creature in team do
		total += creature.Power
	end
	return total
end

return DuelSim
