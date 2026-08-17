local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rebirth = require(ReplicatedStorage.Shared.Rebirth)
local Net = require(ReplicatedStorage.Shared.Net)

local RebirthService = {}

local log
local saveService
local dataSync
local questService

function RebirthService:Init(container)
	log = container:Get("Log")
	saveService = container:Get("SaveService")
	dataSync = container:Get("DataSync")
	questService = container:Get("QuestService")
end

function RebirthService:Start()
	Net.RebirthRequest.OnServerEvent:Connect(function(player: Player)
		local profile = saveService:GetProfile(player)
		if not profile then
			return
		end
		local ok, reason = Rebirth.CanRebirth(profile.Data.Stats.TotalEssenceEarned, profile.Data.Stars)
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
			return
		end
		local ok, reason = Rebirth.CanRebirth(profile.Data.Stats.TotalEssenceEarned, profile.Data.Stars)
		if not ok then
			log:Economy("Rebirth", "Reject", { Player = player.Name, Reason = reason })
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
		profile.Data.LastPlayed = os.time()
		questService:OnRebirth(player)

		log:Economy("Rebirth", "Success", {
			Player = player.Name,
			Stars = profile.Data.Stars,
			Rebirths = profile.Data.Rebirths,
			Previous = previous,
		})
		dataSync:Send(player)
	end)
end

return RebirthService
