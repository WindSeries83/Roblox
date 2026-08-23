local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local SkillTree = require(ReplicatedStorage.Shared.SkillTree)

local SkillService = {}

local log
local saveService
local dataSync
local container

-- Effets agrégés d'un joueur ; source unique pour tous les hooks serveur.
function SkillService:EffectsOf(profile)
	return SkillTree.Effects(profile.Data.SkillRanks or {})
end

function SkillService:Init(cont)
	log = cont:Get("Log")
	saveService = cont:Get("SaveService")
	-- DataSync s'initialise après celui-ci (ORDER) :
	-- la référence est résolue au Start, quand toutes les Init sont passées.
	container = cont
end

function SkillService:Start()
	dataSync = container:Get("DataSync")

	Net.SkillBuy.OnServerEvent:Connect(function(player: Player, nodeId: unknown)
		if type(nodeId) ~= "string" then
			return
		end
		local profile = saveService:GetProfile(player)
		if not profile then
			return
		end
		local ok, reason = SkillTree.CanBuy(profile.Data.SkillPoints, profile.Data.SkillRanks, nodeId)
		if not ok then
			log:Economy("SkillTree", "Reject", { Player = player.Name, Node = nodeId, Reason = reason })
			return
		end
		profile.Data.SkillPoints = SkillTree.Buy(profile.Data.SkillPoints, profile.Data.SkillRanks, nodeId)
		profile.Data.LastPlayed = os.time()
		log:Economy("SkillTree", "Bought", {
			Player = player.Name,
			Node = nodeId,
			Rank = SkillTree.Rank(profile.Data.SkillRanks, nodeId),
			PointsLeft = profile.Data.SkillPoints,
		})
		dataSync:Send(player)
	end)
end

return SkillService
