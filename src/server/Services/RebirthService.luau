local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rebirth = require(ReplicatedStorage.Shared.Rebirth)
local Worlds = require(ReplicatedStorage.Shared.Worlds)
local Net = require(ReplicatedStorage.Shared.Net)

local RebirthService = {}

local log
local saveService
local dataSync
local questService
local incubationService

local container

function RebirthService:Init(cont)
	container = cont
	log = cont:Get("Log")
	saveService = cont:Get("SaveService")
	dataSync = cont:Get("DataSync")
	questService = cont:Get("QuestService")
	incubationService = cont:Get("IncubationService")
end

function RebirthService:Start()
	local function canRebirth(data)
		-- Le boss débloque la Renaissance; l'étoile est accordée par son reset.
		-- Le monde requis suit donc le nombre de renaissances déjà effectuées.
		local world = Worlds.All[math.min((data.Rebirths or 0) + 1, #Worlds.All)]
		local progress = data.WorldProgress and data.WorldProgress[world.Id]
		return Rebirth.CanRebirth(
			data.Stats.TotalEssenceEarned,
			data.Stars,
			progress ~= nil and progress.BossDefeated == true
		)
	end
	Net.RebirthRequest.OnServerEvent:Connect(function(player: Player)
		local profile = saveService:GetProfile(player)
		if not profile then
			Net.ActionResult:FireClient(player, { Action = "Rebirth", Success = false, Reason = "Profil indisponible" })
			return
		end
		local ok, reason = canRebirth(profile.Data)
		Net.RebirthPreview:FireClient(player, {
			CanRebirth = ok,
			Reason = reason,
			CurrentStars = profile.Data.Stars,
			NextStars = profile.Data.Stars + 1,
			NextMult = Rebirth.StarEssenceMult(profile.Data.Stars + 1),
			KeptRelics = #Rebirth.KeepItems(profile.Data.Items),
		})
	end)

	Net.RebirthConfirm.OnServerEvent:Connect(function(player: Player)
		local profile = saveService:GetProfile(player)
		if not profile then
			Net.ActionResult:FireClient(player, { Action = "Rebirth", Success = false, Reason = "Profil indisponible" })
			return
		end
		local ok, reason = canRebirth(profile.Data)
		if not ok then
			log:Economy("Rebirth", "Reject", { Player = player.Name, Reason = reason })
			Net.ActionResult:FireClient(player, { Action = "Rebirth", Success = false, Reason = reason })
			return
		end

		local previous = {
			Essence = profile.Data.Essence,
			Creatures = #profile.Data.Creatures,
			Eggs = #profile.Data.Eggs,
			SanctuaryLevel = profile.Data.SanctuaryLevel,
			IndexSize = 0,
		}
		for _ in profile.Data.Index do
			previous.IndexSize += 1
		end

		Rebirth.ApplyReset(profile.Data)
		incubationService:ClearPlayer(player)
		profile.Data.LastPlayed = os.time()
		questService:OnRebirth(player)
		container:Get("SeasonService"):OnRebirth(player)

		log:Economy("Rebirth", "Success", {
			Player = player.Name,
			Stars = profile.Data.Stars,
			Rebirths = profile.Data.Rebirths,
			Previous = previous,
		})
		dataSync:Send(player)
		Net.ActionResult:FireClient(player, { Action = "Rebirth", Success = true, Stars = profile.Data.Stars })
	end)
end

return RebirthService
