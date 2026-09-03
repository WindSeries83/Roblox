local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Index = require(ReplicatedStorage.Shared.Index)
local FeatureUnlocks = require(ReplicatedStorage.Shared.FeatureUnlocks)

local IndexService = {}

local log
local saveService
local questService

function IndexService:Register(player: Player, speciesId: string, rarity: string, mutation: any): boolean
	local profile = saveService:GetProfile(player)
	if not profile then
		return false
	end
	if Index.Has(profile.Data.Index, speciesId, rarity, mutation) then
		return false
	end
	Index.Register(profile.Data.Index, speciesId, rarity, mutation)
	profile.Data.LastPlayed = os.time()
	log:Economy("Index", "Discover", {
		Player = player.Name,
		Species = speciesId,
		Rarity = rarity,
		Mutation = tostring(mutation),
	})
	questService:OnIndex(player)
	return true
end

function IndexService:GetMult(player: Player): number
	local profile = saveService:GetProfile(player)
	if not profile then
		return 1
	end
	if not FeatureUnlocks.Require(profile.Data, "Index") then
		return 1
	end
	return Index.ComputeMult(profile.Data.Index)
end

function IndexService:Init(container)
	log = container:Get("Log")
	saveService = container:Get("SaveService")
	questService = container:Get("QuestService")
end

return IndexService
