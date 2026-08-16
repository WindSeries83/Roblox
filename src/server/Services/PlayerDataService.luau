local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)

local PlayerDataService = {}

local log
local saveService
local essenceService
local riftService

local function SendSync(player: Player)
	local profile = saveService:GetProfile(player)
	if not profile then
		return
	end
	Net.Sync:FireClient(player, {
		Essence = math.floor(profile.Data.Essence),
		Creatures = profile.Data.Creatures,
		Eggs = profile.Data.Eggs,
		Rate = essenceService:GetRate(player),
		SanctuaryLevel = profile.Data.SanctuaryLevel,
	})
end

local function OnPlayerAdded(player: Player)
	task.spawn(function()
		local profile = nil
		for _ = 1, 5 do
			profile = saveService:LoadProfileAsync(player)
			if profile then
				break
			end
			task.wait(2)
		end

		if not profile then
			player:Kick("Sauvegarde indisponible, réessaie.")
			return
		end

		local elapsed = os.time() - profile.Data.LastPlayed
		if profile.Data.LastPlayed > 0 and elapsed > 60 then
			local rate = essenceService.ComputeRate(profile.Data.Creatures)
			local capped = math.min(elapsed, Config.OFFLINE_CAP_SECONDS)
			local offline = math.floor(rate * capped * Config.OFFLINE_RATE)
			if offline > 0 then
				profile.Data.Essence += offline
				profile.Data.Stats.TotalEssenceEarned += offline
				log:Economy("Essence", "Offline", {
					Player = player.Name,
					Elapsed = elapsed,
					Capped = capped,
					Amount = offline,
				})
			end
		end

		local isNewPlayer = profile.Data.LastPlayed == 0
		if isNewPlayer then
			profile.Data.Essence += Config.STARTER_ESSENCE
			profile.Data.Stats.TotalEssenceEarned += Config.STARTER_ESSENCE
			table.insert(profile.Data.Eggs, {
				Id = HttpService:GenerateGUID(false),
				Tier = "CommonEgg",
				Timestamp = os.time(),
			})
			log:Economy("Players", "Starter", { Player = player.Name })
		end
		profile.Data.LastPlayed = os.time()

		SendSync(player)
		Net.RiftWorld:FireClient(player, riftService:GetStatePayload())

		log:Economy("Players", "Joined", { Player = player.Name })
	end)
end

local function OnPlayerRemoving(player: Player)
	saveService:ReleaseProfile(player)
	log:Economy("Players", "Left", { Player = player.Name })
end

function PlayerDataService:Init(container)
	log = container:Get("Log")
	saveService = container:Get("SaveService")
	essenceService = container:Get("EssenceService")
	riftService = container:Get("RiftService")
end

function PlayerDataService:Start()
	Players.PlayerAdded:Connect(OnPlayerAdded)
	Players.PlayerRemoving:Connect(OnPlayerRemoving)

	for _, player in Players:GetPlayers() do
		OnPlayerAdded(player)
	end
end

return PlayerDataService
