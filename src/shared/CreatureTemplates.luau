-- Accès aux templates d'espèces (modèles sources clonés pour l'affichage).
-- Le serveur les déplace de Workspace vers ReplicatedStorage au boot ;
-- le fallback couvre les sessions où le boot serveur n'a pas tourné.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CreatureTemplates = {}

function CreatureTemplates.Get(speciesId: string): Model?
	local folder = ReplicatedStorage:FindFirstChild("CreatureTemplates")
	if folder then
		return folder:FindFirstChild(speciesId)
	end
	folder = Workspace:FindFirstChild("Creatures")
	return if folder then folder:FindFirstChild(speciesId) else nil
end

return CreatureTemplates
