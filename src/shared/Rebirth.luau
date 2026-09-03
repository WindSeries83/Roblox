local Config = require(script.Parent.Config)

local Rebirth = {}

function Rebirth.NextThreshold(stars: number): number?
	return Config.REBIRTH_THRESHOLDS[stars + 1]
end

function Rebirth.CanRebirth(totalEssenceEarned: number, stars: number, bossDefeated: boolean): (boolean, string?)
	local threshold = Rebirth.NextThreshold(stars)
	if not threshold then
		return false, "toutes les renaissances sont atteintes"
	end
	if not bossDefeated then
		return false, "le boss du monde doit être vaincu"
	end
	if totalEssenceEarned < threshold then
		return false, `il manque {math.ceil(threshold - totalEssenceEarned)} d'Essence gagnée`
	end
	return true
end

function Rebirth.StarEssenceMult(stars: number): number
	return 1 + stars * Config.STAR_ESSENCE_BONUS
end

function Rebirth.KeepItems(items: { any }): { any }
	-- Tout l'équipement est permanent (bible §3.8) : reliques, cœurs, colliers.
	return table.clone(items or {})
end

function Rebirth.ApplyReset(data: any)
	-- Conservation actée (rév. 26/08) : TOUTES les créatures, tous les objets,
	-- compagnon inclus. Perte limitée : Essence, sanctuaire, œufs (consommables).
	data.Eggs = {}
	data.Incubators = {}
	data.SanctuaryLevel = 1
	data.Items = Rebirth.KeepItems(data.Items)
	data.Stars += 1
	data.Rebirths += 1
	data.SkillPoints = (data.SkillPoints or 0) + 1
	data.Essence = Config.STARTER_ESSENCE
end

return Rebirth
