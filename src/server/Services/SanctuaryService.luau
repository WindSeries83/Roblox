local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sanctuary = require(ReplicatedStorage.Shared.Sanctuary)
local Net = require(ReplicatedStorage.Shared.Net)

local SanctuaryService = {}

local log
local saveService
local essenceService
local dataSync
local skillService

function SanctuaryService:Init(container)
	log = container:Get("Log")
	saveService = container:Get("SaveService")
	essenceService = container:Get("EssenceService")
	dataSync = container:Get("DataSync")
	skillService = container:Get("SkillService")
end

function SanctuaryService:Start()
	Net.UpgradeSanctuary.OnServerEvent:Connect(function(player: Player)
		local profile = saveService:GetProfile(player)
		if not profile then
			return
		end

		local level = profile.Data.SanctuaryLevel
		local eff = skillService:EffectsOf(profile)
		local cost = math.max(1, math.floor(Sanctuary.UpgradeCost(level) * (1 - eff.UpgradeCostReduction)))
		if profile.Data.Essence < cost then
			log:Economy("Sanctuary", "Reject", { Player = player.Name, Reason = "Essence insuffisante" })
			return
		end

		if not essenceService:Spend(player, cost, "SanctuaryUpgrade") then
			return
		end
		profile.Data.SanctuaryLevel += 1
		profile.Data.LastPlayed = os.time()

		log:Economy("Sanctuary", "Upgrade", {
			Player = player.Name,
			Level = profile.Data.SanctuaryLevel,
			Cost = cost,
			MaxCreatures = Sanctuary.MaxCreatures(profile.Data.SanctuaryLevel),
		})
		dataSync:Send(player)
	end)

	-- Le joueur désigne son compagnon (nil = rappel à la grille).
	Net.SetCompanion.OnServerEvent:Connect(function(player: Player, creatureId: string?)
		local profile = saveService:GetProfile(player)
		if not profile then
			return
		end

		if creatureId ~= nil and type(creatureId) ~= "string" then
			return
		end
		if creatureId ~= nil then
			local exists = false
			for _, creature in profile.Data.Creatures do
				if creature.Id == creatureId then
					exists = true
					break
				end
			end
			if not exists then
				log:Economy("Companion", "Reject", {
					Player = player.Name,
					CreatureId = creatureId,
					Reason = "Créature introuvable",
				})
				return
			end
		end

		profile.Data.CompanionId = creatureId
		dataSync:Send(player)
	end)
end

return SanctuaryService
