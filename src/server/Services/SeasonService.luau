local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Season = require(ReplicatedStorage.Shared.Season)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Net = require(ReplicatedStorage.Shared.Net)

local SeasonService = {}

local log
local saveService
local essenceService
local dataSync

local function Sync(player: Player)
	local profile = saveService:GetProfile(player)
	if not profile then
		return
	end
	Net.SeasonSync:FireClient(player, {
		Season = profile.Data.Season,
		HasPremium = profile.Data.Entitlements.SeasonPremium,
	})
end

function SeasonService:AddXP(player: Player, amount: number, source: string)
	local profile = saveService:GetProfile(player)
	if not profile then
		return
	end
	local season = profile.Data.Season
	local before = season.Level
	season.XP += amount
	season.Level = Season.LevelFromXP(season.XP)
	profile.Data.LastPlayed = os.time()
	log:Economy("Season", "XP", {
		Player = player.Name,
		Amount = amount,
		Source = source,
		Level = season.Level,
	})
	if season.Level > before then
		log:Economy("Season", "LevelUp", {
			Player = player.Name,
			Level = season.Level,
		})
	end
	Sync(player)
end

-- Called by other services when a tracked action happens.
function SeasonService:OnHatch(player: Player)
	SeasonService:AddXP(player, Config.SEASON_XP.Hatch, "Hatch")
end

function SeasonService:OnRiftWon(player: Player)
	SeasonService:AddXP(player, Config.SEASON_XP.Rift, "Rift")
end

function SeasonService:OnBreed(player: Player)
	SeasonService:AddXP(player, Config.SEASON_XP.Breed, "Breed")
end

function SeasonService:OnRebirth(player: Player)
	SeasonService:AddXP(player, Config.SEASON_XP.Rebirth, "Rebirth")
end

function SeasonService:OnQuestClaim(player: Player)
	SeasonService:AddXP(player, Config.SEASON_XP.Quest, "Quest")
end

function SeasonService:Init(container)
	log = container:Get("Log")
	saveService = container:Get("SaveService")
	essenceService = container:Get("EssenceService")
	dataSync = container:Get("DataSync")
end

function SeasonService:Start()
	Net.SeasonRequest.OnServerEvent:Connect(function(player: Player)
		Sync(player)
	end)

	Net.SeasonClaim.OnServerEvent:Connect(function(player: Player, level: any, track: any)
		if typeof(level) ~= "number" or typeof(track) ~= "string" then
			return
		end
		local profile = saveService:GetProfile(player)
		if not profile then
			return
		end
		if track ~= "free" and track ~= "premium" then
			return
		end
		if track == "premium" and not profile.Data.Entitlements.SeasonPremium then
			log:Economy("Season", "ClaimRejected", { Player = player.Name, Reason = "Pas de piste premium" })
			return
		end
		if not Season.CanClaim(profile.Data.Season, level, track) then
			return
		end

		local claimed = if track == "premium"
			then profile.Data.Season.ClaimedPremium
			else profile.Data.Season.ClaimedFree
		claimed[level] = true
		profile.Data.LastPlayed = os.time()

		local reward = Season.RewardFor(level, track)
		essenceService:Add(player, reward.Essence, `SeasonClaim_{level}_{track}`)
		if reward.Creature then
			local creature =
				Gameplay.CreateCreature(reward.Creature.Rarity, reward.Creature.SpeciesId, reward.Creature.Mutation)
			local maxCreatures = 1e18
			if #profile.Data.Creatures < maxCreatures then
				table.insert(profile.Data.Creatures, creature)
			end
			log:Economy("Season", "Exclusive", {
				Player = player.Name,
				Species = creature.SpeciesId,
				Rarity = creature.Rarity,
				Mutation = tostring(creature.Mutation),
			})
		end
		if reward.Title then
			if not table.find(profile.Data.Titles, reward.Title) then
				table.insert(profile.Data.Titles, reward.Title)
			end
		end

		log:Economy("Season", "Claim", {
			Player = player.Name,
			Level = level,
			Track = track,
			Essence = reward.Essence,
		})
		Sync(player)
		dataSync:Send(player)
	end)

	for _, player in game:GetService("Players"):GetPlayers() do
		Sync(player)
	end
end

return SeasonService
