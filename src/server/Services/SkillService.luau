local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local SkillTree = require(ReplicatedStorage.Shared.SkillTree)
local FeatureUnlocks = require(ReplicatedStorage.Shared.FeatureUnlocks)

local SkillService = {}

local log
local saveService
local dataSync
local container
local lastSkillBuy: { [Player]: number } = {}

-- Effets agrégés d'un joueur ; source unique pour tous les hooks serveur.
function SkillService:EffectsOf(profile)
	if not FeatureUnlocks.Require(profile.Data, "SkillTree") then
		return SkillTree.Effects({})
	end
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
		local now = os.clock()
		if lastSkillBuy[player] and now - lastSkillBuy[player] < 0.5 then
			return
		end
		lastSkillBuy[player] = now

		local function reject(reason: string)
			Net.ActionResult:FireClient(player, { Action = "SkillBuy", Success = false, Reason = reason })
		end

		if type(nodeId) ~= "string" then
			reject("Talent invalide")
			return
		end
		local profile = saveService:GetProfile(player)
		if not profile then
			reject("Profil indisponible")
			return
		end
		local unlocked, unlockReason = FeatureUnlocks.Require(profile.Data, "SkillTree")
		if not unlocked then
			log:Economy("SkillTree", "Reject", { Player = player.Name, Node = nodeId, Reason = unlockReason })
			reject(unlockReason or "Arbre verrouillé")
			return
		end
		local ok, reason = SkillTree.CanBuy(profile.Data.SkillPoints, profile.Data.SkillRanks, nodeId)
		if not ok then
			log:Economy("SkillTree", "Reject", { Player = player.Name, Node = nodeId, Reason = reason })
			reject(reason)
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
		Net.ActionResult:FireClient(player, {
			Action = "SkillBuy",
			Success = true,
			NodeId = nodeId,
			Rank = SkillTree.Rank(profile.Data.SkillRanks, nodeId),
		})
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		lastSkillBuy[player] = nil
	end)
end

return SkillService
