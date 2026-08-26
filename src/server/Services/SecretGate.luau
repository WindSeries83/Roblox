--!strict
-- Mécanisme du Secret : résolu CÔTÉ SERVEUR uniquement (bible B3.3/B3.7).
-- Ne jamais déplacer en Shared : le client ne doit pas pouvoir décompiler le procédé.
local SecretGate = {}

function SecretGate.Triggered(eggTier: string, eclipseActive: boolean, relicTier: string?, omen: boolean?): boolean
	if eclipseActive ~= true or relicTier ~= "T3" then
		return false
	end
	if eggTier == "RareEgg" then
		return true
	end
	return omen == true and (eggTier == "EpicEgg" or eggTier == "LegendaryEgg")
end

return SecretGate
