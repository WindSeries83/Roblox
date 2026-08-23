local Config = require(script.Parent.Config)
local Equipment = require(script.Parent.Data.Equipment)

local Rebirth = {}

function Rebirth.NextThreshold(stars: number): number?
	return Config.REBIRTH_THRESHOLDS[stars + 1]
end

function Rebirth.CanRebirth(totalEssenceEarned: number, stars: number): (boolean, string?)
	local threshold = Rebirth.NextThreshold(stars)
	if not threshold then
		return false, "toutes les renaissances sont atteintes"
	end
	if totalEssenceEarned < threshold then
		return false, `il manque {threshold - totalEssenceEarned} d'Essence gagnée`
	end
	return true
end

function Rebirth.StarEssenceMult(stars: number): number
	return 1 + stars * Config.STAR_ESSENCE_BONUS
end

function Rebirth.KeepItems(items: { any }): { any }
	local kept = {}
	for _, item in items do
		if item.Type == "Relic" then
			local def = Equipment.Relic.Tiers[item.Tier]
			if def and def.Legendary then
				table.insert(kept, item)
			end
		end
	end
	return kept
end

function Rebirth.KeepBestCreature(creatures: { any }): { any }
	if #creatures == 0 then
		return {}
	end
	local best = creatures[1]
	for _, creature in creatures do
		if creature.Power > best.Power then
			best = creature
		end
	end
	return { best }
end

function Rebirth.ApplyReset(data: any)
	data.Creatures = Rebirth.KeepBestCreature(data.Creatures)
	data.Eggs = {}
	data.SanctuaryLevel = 1
	data.Items = Rebirth.KeepItems(data.Items)
	data.Stars += 1
	data.Rebirths += 1
	data.SkillPoints = (data.SkillPoints or 0) + 1
	data.Essence = Config.STARTER_ESSENCE
end

return Rebirth
