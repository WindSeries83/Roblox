local Config = require(script.Parent.Config)
local Rebirth = require(script.Parent.Rebirth)

local Objective = {}

local function ClaimableQuests(quests): number
	local ready = 0
	if quests and quests.Daily then
		for _, quest in quests.Daily do
			local def = Config.DAILY_QUESTS[quest.Id]
			if def and not quest.Claimed and quest.Progress >= def.Target then
				ready += 1
			end
		end
	end
	return ready
end

-- Priorité : faille active (100) > quêtes réclamables (80) > premier œuf (60) > renaissance (40) > teasing (20)
function Objective.Pick(state, world)
	state = state or {}
	world = world or {}
	if world.Active then
		return { Text = "La faille est ouverte ! Direction l'arche.", Priority = 100 }
	end
	local ready = ClaimableQuests(state.Quests)
	if ready > 0 then
		return {
			Text = `{ready} quête{if ready > 1 then "s" else ""} prête{if ready > 1 then "s" else ""} à réclamer !`,
			Priority = 80,
		}
	end
	local stats = state.Stats or {}
	if (stats.TotalHatched or 0) == 0 then
		return { Text = "Éclos ton premier œuf : ouvre le menu Œufs.", Priority = 60 }
	end
	if Rebirth.CanRebirth(stats.TotalEssenceEarned or 0, state.Stars or 0) then
		return { Text = "Renaissance disponible ! Ouvre l'onglet Renaissance.", Priority = 40 }
	end
	if (stats.TotalHatched or 0) > 0 then
		return { Text = "Œuf rare verrouillé — Rang de sanctuaire 3", Priority = 20 }
	end
	return nil
end

function Objective.FormatCountdown(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

return Objective
