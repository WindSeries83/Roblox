--!strict

local FeatureUnlocks = {}

local REASONS = {
	Expeditions = "Éclos une première créature pour ouvrir le Parcours.",
	More = "Vaincs le boss du Bosquet du Crépuscule pour révéler les systèmes avancés.",
	Objectives = "Vaincs le boss du Bosquet du Crépuscule pour révéler les Objectifs.",
	Shop = "Vaincs le boss du Bosquet du Crépuscule pour révéler la Boutique.",
	Rebirth = "Vaincs le boss du Bosquet du Crépuscule pour débloquer la Renaissance.",
	World2 = "Une Renaissance est requise pour ouvrir le monde suivant.",
	Index = "Une Renaissance est requise pour ouvrir l'Index.",
	SkillTree = "Une Renaissance est requise pour ouvrir l'Arbre d'Étoiles.",
	Equipment = "Une Renaissance est requise pour utiliser l'équipement.",
	Evolution = "Une Renaissance est requise pour faire évoluer les créatures.",
	Market = "Une Renaissance est requise pour ouvrir le Marché.",
	Social = "Deux Renaissances sont requises pour les fonctions sociales.",
	Leaderboards = "Deux Renaissances sont requises pour les classements.",
	Duels = "Deux Renaissances sont requises pour les duels.",
	Breeding = "Trois Renaissances sont requises pour l'Élevage.",
	Endgame = "Quatre Renaissances et le boss de l'Abîme de Nyx sont requis pour l'endgame.",
}

local function BossDefeated(data: any, worldId: string): boolean
	local progress = if data then data.WorldProgress else nil
	local world = if progress then progress[worldId] else nil
	return world ~= nil and world.BossDefeated == true
end

function FeatureUnlocks.For(data: any)
	local stats = if data then data.Stats else nil
	local stars = if data and type(data.Stars) == "number" then data.Stars else 0
	local hatched = if stats and type(stats.TotalHatched) == "number" then stats.TotalHatched else 0
	local boss1 = BossDefeated(data, "TwilightGrove")
	local boss3 = BossDefeated(data, "GalePeaks")
	local boss4 = BossDefeated(data, "NyxAbyss")

	local sharedSanctuaries = 0
	if stars >= 1 and boss1 then
		sharedSanctuaries = 1
	end
	if stars >= 3 and boss3 then
		sharedSanctuaries = 2
	end
	if stars >= 4 and boss4 then
		sharedSanctuaries = 3
	end

	return {
		Eggs = true,
		Sanctuaries = true,
		Expeditions = hatched > 0,
		More = boss1,
		Objectives = boss1,
		Shop = boss1,
		Rebirth = boss1,
		World2 = stars >= 1 and boss1,
		SkillTree = stars >= 1,
		Index = stars >= 1,
		Equipment = stars >= 1,
		Evolution = stars >= 1,
		Market = stars >= 1,
		Social = stars >= 2,
		Leaderboards = stars >= 2,
		Duels = stars >= 2,
		Breeding = stars >= 3,
		Endgame = stars >= 4 and boss4,
		SharedSanctuaryCount = sharedSanctuaries,
	}
end

function FeatureUnlocks.Reason(data: any, feature: string): string?
	local unlocks = FeatureUnlocks.For(data)
	if unlocks[feature] == true then
		return nil
	end
	return REASONS[feature] or "Cette fonctionnalité n'est pas encore disponible."
end

function FeatureUnlocks.Require(data: any, feature: string): (boolean, string?)
	local unlocks = FeatureUnlocks.For(data)
	if unlocks[feature] == true then
		return true
	end
	return false, FeatureUnlocks.Reason(data, feature)
end

function FeatureUnlocks.Reasons(data: any): { [string]: string }
	local unlocks = FeatureUnlocks.For(data)
	local reasons = {}
	for feature, reason in REASONS do
		if unlocks[feature] ~= true then
			reasons[feature] = reason
		end
	end
	return reasons
end

return FeatureUnlocks
