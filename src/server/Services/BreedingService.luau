--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Breeding = require(ReplicatedStorage.Shared.Breeding)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Sanctuary = require(ReplicatedStorage.Shared.Sanctuary)
local FeatureUnlocks = require(ReplicatedStorage.Shared.FeatureUnlocks)
local Net = require(ReplicatedStorage.Shared.Net)

local BreedingService = {}

local log
local saveService
local essenceService
local indexService
local dataSync
local questService
local sessionLuck
local skillService
local analyticsService

local container

local cooldowns: { [Player]: number } = {}

function BreedingService:Init(cont)
	container = cont
	log = cont:Get("Log")
	saveService = cont:Get("SaveService")
	essenceService = cont:Get("EssenceService")
	indexService = cont:Get("IndexService")
	dataSync = cont:Get("DataSync")
	questService = cont:Get("QuestService")
	sessionLuck = cont:Get("SessionLuck")
	skillService = cont:Get("SkillService")
	analyticsService = cont:Get("AnalyticsService")
end

function BreedingService:Start()
	Net.BreedCreatures.OnServerEvent:Connect(function(player: Player, fatherId: unknown, motherId: unknown)
		local function reject(reason: string)
			Net.ActionResult:FireClient(player, { Action = "BreedCreatures", Success = false, Reason = reason })
		end
		local validRequest, requestReason = Breeding.ValidateRequest(fatherId, motherId)
		if not validRequest then
			reject(requestReason or "Parents invalides")
			return
		end
		local profile = saveService:GetProfile(player)
		if not profile then
			reject("Profil indisponible")
			return
		end
		local unlocked, unlockReason = FeatureUnlocks.Require(profile.Data, "Breeding")
		if not unlocked then
			reject(unlockReason or "Élevage verrouillé")
			return
		end

		local last = cooldowns[player] or 0
		if os.clock() - last < Config.BREED_COOLDOWN then
			reject("Élevage en cooldown")
			return
		end

		local father = Gameplay.FindCreature(profile.Data.Creatures, fatherId :: string)
		local mother = Gameplay.FindCreature(profile.Data.Creatures, motherId :: string)
		local ok, reason = Breeding.CanBreed(father, mother)
		if not ok then
			log:Economy("Breeding", "Reject", { Player = player.Name, Reason = reason })
			reject(reason or "Élevage impossible")
			return
		end

		local bonusSlots = if profile.Data.Entitlements.MoreSlots then Config.GAMEPASSES.MoreSlots.BonusSlots else 0
		local maxCreatures = Sanctuary.MaxCreatures(profile.Data.SanctuaryLevel, bonusSlots)
		if #profile.Data.Creatures >= maxCreatures then
			log:Economy("Breeding", "CapReached", {
				Player = player.Name,
				Creatures = #profile.Data.Creatures,
				MaxCreatures = maxCreatures,
			})
			reject("Sanctuaire plein")
			return
		end

		local eff = skillService:EffectsOf(profile)
		local breedCost = math.max(1, math.floor(Config.BREED_COST * (1 - eff.BreedCostReduction)))
		local rollOk, roll = pcall(Breeding.RollChild, father, mother, sessionLuck.For(player))
		if not rollOk or type(roll) ~= "table" then
			reject("Élevage indisponible")
			return
		end
		local childOk, child = pcall(Gameplay.CreateCreature, roll.Rarity, roll.SpeciesId, roll.Mutation)
		if not childOk or type(child) ~= "table" then
			reject("Élevage indisponible")
			return
		end
		child.Parents = roll.Parents
		child.Generation = roll.Generation
		child.BreedingLineage = roll.BreedingLineage

		local previousEssence = profile.Data.Essence
		local previousTotalBred = profile.Data.Stats.TotalBred
		local previousIndex = table.clone(profile.Data.Index)
		if not essenceService:Spend(player, breedCost, `Breed_{father.SpeciesId}`) then
			reject("Essence insuffisante")
			return
		end

		local commitOk = pcall(function()
			table.insert(profile.Data.Creatures, child)
			indexService:Register(player, child.SpeciesId, child.Rarity, child.Mutation)
			profile.Data.Stats.TotalBred += 1
		end)
		if not commitOk then
			local childIndex = table.find(profile.Data.Creatures, child)
			if childIndex then
				table.remove(profile.Data.Creatures, childIndex)
			end
			profile.Data.Index = previousIndex
			profile.Data.Essence = previousEssence
			profile.Data.Stats.TotalBred = previousTotalBred
			reject("Élevage annulé")
			return
		end
		cooldowns[player] = os.clock()
		profile.Data.LastPlayed = os.time()

		Net.BreedResult:FireClient(player, {
			FatherId = father.Id,
			MotherId = mother.Id,
			Creature = child,
		})

		questService:OnBreed(player)
		container:Get("SeasonService"):OnBreed(player)
		dataSync:Send(player)
		Net.ActionResult:FireClient(player, {
			Action = "BreedCreatures",
			Success = true,
			FatherId = father.Id,
			MotherId = mother.Id,
			CreatureId = child.Id,
		})

		log:Economy("Breeding", "Success", {
			Player = player.Name,
			Father = father.Id,
			Mother = mother.Id,
			Species = child.SpeciesId,
			Rarity = child.Rarity,
			Mutation = tostring(child.Mutation),
			Generation = child.Generation,
			ChildId = child.Id,
		})
		analyticsService:Event("breed", {
			Father = father.Id,
			Mother = mother.Id,
			Species = child.SpeciesId,
			Rarity = child.Rarity,
			Mutation = tostring(child.Mutation),
		}, player)
	end)
end

return BreedingService
