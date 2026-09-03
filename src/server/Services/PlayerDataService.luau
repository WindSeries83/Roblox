local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)
local Offers = require(ReplicatedStorage.Shared.Offers)
local Streak = require(ReplicatedStorage.Shared.Streak)
local Vip = require(ReplicatedStorage.Shared.Vip)

local PlayerDataService = {}

-- Cosmétiques VIP : tag doré au-dessus de la tête + particules dorées.
local function ApplyVipCosmetics(player: Player)
	local function Decorate(character: Model)
		local head = character:WaitForChild("Head", 10)
		if not head then
			return
		end
		local billboard = Instance.new("BillboardGui")
		billboard.Adornee = head
		billboard.Size = UDim2.fromOffset(140, 32)
		billboard.StudsOffsetWorldSpace = Vector3.new(0, 2, 0)
		billboard.AlwaysOnTop = true
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.Text = "★ VIP"
		label.TextColor3 = Color3.fromRGB(255, 215, 0)
		label.TextStrokeTransparency = 0.4
		label.Parent = billboard
		billboard.Parent = head

		local root = character:WaitForChild("HumanoidRootPart", 10)
		if not root then
			return
		end
		local emitter = Instance.new("ParticleEmitter")
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		emitter.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
		emitter.Rate = 4
		emitter.Lifetime = NumberRange.new(1, 1.5)
		emitter.Speed = NumberRange.new(0.5)
		emitter.Parent = root
	end

	player.CharacterAdded:Connect(Decorate)
	if player.Character then
		Decorate(player.Character)
	end
end

local log
local saveService
local essenceService
local riftService
local dataSync
local skillService
local depthService

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
		depthService:OnProfileLoaded(player, profile)

		local elapsed = os.time() - profile.Data.LastPlayed
		if profile.Data.LastPlayed > 0 and elapsed > 60 then
			local eff = skillService:EffectsOf(profile)
			local rate = essenceService.GetRate(player)
			local capped = math.min(elapsed, Config.OFFLINE_CAP_SECONDS)
			local offline = math.floor(rate * capped * (Config.OFFLINE_RATE + eff.OfflineRate))
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
				Source = "Nest",
			})
			log:Economy("Players", "Starter", { Player = player.Name })
		end
		local lastSeen = profile.Data.LastPlayed
		profile.Data.LastPlayed = os.time()

		local today = os.date("%Y-%m-%d")
		local streak, dayIndex = Streak.Evaluate(today, profile.Data.LastLoginDate, profile.Data.LoginStreak or 0)
		if dayIndex then
			profile.Data.LoginStreak = streak
			profile.Data.LastLoginDate = today
			local amount = Config.STREAK_REWARDS[dayIndex]
			profile.Data.Essence += amount
			profile.Data.Stats.TotalEssenceEarned += amount
			log:Economy("Essence", "Streak", { Player = player.Name, Day = streak, Amount = amount })
			-- delai : laisse l'UI client finir de monter avant d'afficher le toast
			task.delay(5, function()
				if not player:IsDescendantOf(game) then
					return
				end
				Net.QuestsSync:FireClient(player, {
					Quests = profile.Data.Quests,
					Notice = { Type = "Streak", Name = `jour {streak}`, Day = streak, Amount = amount },
				})
			end)
		end

		-- VIP : le re-grant des passes (PurchaseService:Start) tourne en parallele,
		-- ordre non garanti -> delai de 5 s avant le check cadeau + cosmétiques.
		task.delay(5, function()
			if not player:IsDescendantOf(game) then
				return
			end
			if profile.Data.Entitlements.VIP then
				if Vip.GiftDue(profile.Data.VipGiftDate or "", today) then
					essenceService:Add(player, Config.VIP_DAILY_GIFT, "VipDailyGift")
					profile.Data.VipGiftDate = today
					Net.QuestsSync:FireClient(player, {
						Quests = profile.Data.Quests,
						Notice = { Type = "VipGift", Name = "VIP", Amount = Config.VIP_DAILY_GIFT },
					})
				end
				ApplyVipCosmetics(player)
			end
		end)

		-- Retours J2/J7 : cadeau d'essence une seule fois par palier.
		-- Garde lastSeen > 0 : sinon un nouveau joueur (0) aurait un elapsed énorme.
		local returnDay = if lastSeen > 0 then Offers.ReturnDay(elapsed) else nil
		if returnDay then
			if Offers.ReturnGiftDue(profile.Data, returnDay) then
				local amount = Config.RETURN_GIFTS[returnDay]
				essenceService:Add(player, amount, `ReturnGift_{returnDay}`)
				profile.Data.Offers.ReturnGifts[returnDay] = true
				task.delay(5, function()
					if not player:IsDescendantOf(game) then
						return
					end
					Net.QuestsSync:FireClient(player, {
						Quests = profile.Data.Quests,
						Notice = { Type = "ReturnGift", Name = returnDay, Amount = amount },
					})
				end)
			end
			-- Déclencheur offre 1er achat : retour après ≥ 1 jour d'absence.
			profile.Data.Offers.FirstPurchaseEligible = true
		end

		dataSync:Send(player)
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
	dataSync = container:Get("DataSync")
	skillService = container:Get("SkillService")
	depthService = container:Get("DepthService")
end

function PlayerDataService:Start()
	Players.PlayerAdded:Connect(OnPlayerAdded)
	Players.PlayerRemoving:Connect(OnPlayerRemoving)

	for _, player in Players:GetPlayers() do
		OnPlayerAdded(player)
	end
end

return PlayerDataService
