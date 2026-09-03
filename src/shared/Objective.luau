local Config = require(script.Parent.Config)
local FeatureUnlocks = require(script.Parent.FeatureUnlocks)
local Rebirth = require(script.Parent.Rebirth)
local Worlds = require(script.Parent.Worlds)

local Objective = {}

function Objective.Tutorial(state, _bridge, now: number?)
	state = state or {}
	if state.TutorialDone then
		return nil
	end
	local stats = state.Stats or {}
	if (stats.TotalHatched or 0) == 0 then
		local incubators = state.Incubators or {}
		if #incubators == 0 then
			return { Text = "Place ton œuf dans la couveuse.", Priority = 100, Need = "PlaceEgg" }
		end
		local currentTime = now or os.time()
		for _, record in incubators do
			if type(record.ReadyAt) == "number" and currentTime >= record.ReadyAt then
				return { Text = "Récupère ta créature dans la couveuse.", Priority = 100, Need = "ClaimHatch" }
			end
		end
		return {
			Text = "L'incubation est en cours. Reviens quand l'œuf sera prêt.",
			Priority = 100,
			Need = "Incubating",
		}
	end
	if (stats.RiftsCompleted or 0) < 1 then
		return {
			Text = "Entre dans le Parcours quand il s'ouvre, puis bats son gardien.",
			Priority = 100,
			Need = "RiftEntered",
		}
	end
	return { Text = "Réclame ta récompense pour terminer.", Priority = 100, Need = "Claim" }
end

function Objective.CanCompleteTutorial(state): boolean
	if not state or state.TutorialDone then
		return false
	end
	local stats = state.Stats or {}
	return (stats.TotalHatched or 0) >= 1 and (stats.RiftsCompleted or 0) >= 1
end

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
		return { Text = "Le Parcours est ouvert ! Direction l'arche.", Priority = 100 }
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
	local stars = state.Stars or 0
	local currentWorld = Worlds.All[math.min(stars + 1, #Worlds.All)]
	local worldState = state.WorldProgress and state.WorldProgress[currentWorld.Id]
	if
		Rebirth.CanRebirth(stats.TotalEssenceEarned or 0, stars, worldState ~= nil and worldState.BossDefeated == true)
	then
		return { Text = "Renaissance disponible ! Ouvre l'onglet Renaissance.", Priority = 40 }
	end
	if (stats.TotalHatched or 0) > 0 then
		local unlocks = FeatureUnlocks.For(state)
		local nextFeature = if not unlocks.More
			then "More"
			elseif not unlocks.SkillTree then "SkillTree"
			elseif not unlocks.Breeding then "Breeding"
			else nil
		if nextFeature then
			return {
				Text = FeatureUnlocks.Reason(state, nextFeature) or "Continue ta progression.",
				Priority = 20,
				Need = "Progress",
				Feature = nextFeature,
			}
		end
		return { Text = "Explore ton prochain œuf et améliore ta collection.", Priority = 20 }
	end
	return nil
end

return Objective
