--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sanctuary = require(ReplicatedStorage.Shared.Sanctuary)
local FeatureUnlocks = require(ReplicatedStorage.Shared.FeatureUnlocks)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Net = require(ReplicatedStorage.Shared.Net)

local SanctuaryService = {}

local log
local saveService
local essenceService
local dataSync
local skillService
local analyticsService
local invitations: { [number]: { [number]: boolean } } = {}

function SanctuaryService:Init(container)
	log = container:Get("Log")
	saveService = container:Get("SaveService")
	essenceService = container:Get("EssenceService")
	dataSync = container:Get("DataSync")
	skillService = container:Get("SkillService")
	analyticsService = container:Get("AnalyticsService")
end

function SanctuaryService:Start()
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		invitations[player.UserId] = nil
		for _, invited in invitations do
			invited[player.UserId] = nil
		end
	end)

	Net.AssignSanctuary.OnServerEvent:Connect(function(player: Player, sanctuaryId: string, creatureIds: { string })
		local profile = saveService:GetProfile(player)
		if not profile or type(sanctuaryId) ~= "string" or type(creatureIds) ~= "table" then
			return
		end
		local owned = {}
		for _, creature in profile.Data.Creatures do
			owned[creature.Id] = true
		end
		local unlocked = FeatureUnlocks.For(profile.Data).SharedSanctuaryCount
		if not Sanctuary.ValidateAssignment(sanctuaryId, creatureIds, owned, unlocked) then
			return
		end
		local previous = profile.Data.SanctuaryAssignments[sanctuaryId]
		profile.Data.SanctuaryAssignments[sanctuaryId] = {
			CreatureIds = table.clone(creatureIds),
			LastCollectedAt = if previous then previous.LastCollectedAt else os.time(),
		}
		dataSync:Send(player)
	end)

	Net.CollectSanctuary.OnServerEvent:Connect(function(player: Player, sanctuaryId: string)
		local profile = saveService:GetProfile(player)
		local record = profile and profile.Data.SanctuaryAssignments[sanctuaryId]
		if not record then
			return
		end
		local assigned = {}
		for _, creature in profile.Data.Creatures do
			if table.find(record.CreatureIds, creature.Id) then
				table.insert(assigned, creature)
			end
		end
		local amount, collectedAt =
			Sanctuary.OfflineReward(Gameplay.ComputeRate(assigned), record.LastCollectedAt, os.time())
		record.LastCollectedAt = collectedAt
		if amount > 0 then
			essenceService:Add(player, amount, "SharedSanctuary")
		end
		dataSync:Send(player)
	end)

	Net.InviteSanctuary.OnServerEvent:Connect(function(player: Player, visitorUserId: number)
		if type(visitorUserId) ~= "number" or not game:GetService("Players"):GetPlayerByUserId(visitorUserId) then
			return
		end
		invitations[player.UserId] = invitations[player.UserId] or {}
		invitations[player.UserId][visitorUserId] = true
	end)

	Net.VisitSanctuary.OnServerEvent:Connect(function(player: Player, ownerUserId: number)
		local allowed = ownerUserId == player.UserId
			or (invitations[ownerUserId] and invitations[ownerUserId][player.UserId] == true)
		Net.ActionResult:FireClient(player, { Action = "VisitSanctuary", Success = allowed })
	end)

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
		analyticsService:Funnel(profile, "FirstOptimizationAt", player)

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
			log:Economy("Companion", "Reject", { Player = player.Name, Reason = "type invalide" })
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
