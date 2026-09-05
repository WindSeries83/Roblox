--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)
local Vip = require(ReplicatedStorage.Shared.Vip)
local PurchaseLedger = require(ReplicatedStorage.Shared.PurchaseLedger)

local VipService = {}

local saveService
local essenceService
local luckService
local hatchService
local dataSync
local log

local tracked: { [Player]: boolean } = {}
local cooldowns: { [Player]: number } = {}

local function IsVip(_player: Player, profile: any?): boolean
	return profile ~= nil and Vip.CanAccess(profile.Data.VipExpiresAt, os.time())
end

local function ClearCosmetics(player: Player)
	local character = player.Character
	if not character then
		return
	end
	local head = character:FindFirstChild("Head")
	local root = character:FindFirstChild("HumanoidRootPart")
	local badge = head and head:FindFirstChild("VipBadge")
	local sparkles = root and root:FindFirstChild("VipSparkles")
	if badge then
		badge:Destroy()
	end
	if sparkles then
		sparkles:Destroy()
	end
end

local function ApplyCosmetics(player: Player)
	ClearCosmetics(player)
	local character = player.Character
	if not character then
		return
	end
	local head = character:FindFirstChild("Head")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not head or not root then
		return
	end

	local badge = Instance.new("BillboardGui")
	badge.Name = "VipBadge"
	badge.Adornee = head
	badge.Size = UDim2.fromOffset(140, 32)
	badge.StudsOffsetWorldSpace = Vector3.new(0, 2, 0)
	badge.AlwaysOnTop = true
	badge.Parent = head
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = "★ VIP"
	label.TextColor3 = Color3.fromRGB(255, 215, 0)
	label.TextStrokeTransparency = 0.4
	label.Parent = badge

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "VipSparkles"
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
	emitter.Rate = 4
	emitter.Lifetime = NumberRange.new(1, 1.5)
	emitter.Speed = NumberRange.new(0.5)
	emitter.Parent = root
end

function VipService:Refresh(player: Player)
	local profile = saveService:GetProfile(player)
	local active = IsVip(player, profile)
	local previous = player:GetAttribute("VipActive") == true
	player:SetAttribute("VipActive", active)
	if active then
		local character = player.Character
		local head = character and character:FindFirstChild("Head")
		if not previous or not head or not head:FindFirstChild("VipBadge") then
			ApplyCosmetics(player)
		end
	elseif previous then
		ClearCosmetics(player)
	end
end

function VipService:ClaimChest(player: Player): boolean
	local profile = saveService:GetProfile(player)
	if not IsVip(player, profile) then
		Net.ActionResult:FireClient(player, {
			Action = "VipChest",
			Success = false,
			Reason = "Le coffre est reserve aux membres VIP.",
		})
		return false
	end
	local today = os.date("%Y-%m-%d")
	if not Vip.GiftDue(profile.Data.VipGiftDate or "", today) then
		Net.ActionResult:FireClient(player, {
			Action = "VipChest",
			Success = false,
			Reason = "Le coffre VIP a deja ete ouvert aujourd'hui.",
		})
		return false
	end
	local now = os.clock()
	if now - (cooldowns[player] or 0) < 1 then
		return false
	end
	cooldowns[player] = now

	local snapshot = PurchaseLedger.Snapshot(profile.Data)
	profile.Data.VipGiftDate = today
	local essence = essenceService:Add(player, Config.VIP_DAILY_GIFT, "VipDailyGift")
	local potionOk = luckService:GrantPotion(player, "Small", `VipChest_{today}`)
	local eggTier = if Random.new():NextInteger(1, 2) == 1 then "CommonEgg" else "UncommonEgg"
	hatchService:GrantEgg(player, eggTier, "VipChest")
	local saved = essence > 0
		and potionOk
		and saveService:SaveProfile(player, function(data)
			return data.VipGiftDate == today
		end)
	if not saved then
		PurchaseLedger.Restore(profile.Data, snapshot)
		Net.ActionResult:FireClient(
			player,
			{ Action = "VipChest", Success = false, Reason = "Sauvegarde indisponible, reessaie" }
		)
		return false
	end

	dataSync:Send(player)
	Net.ActionResult:FireClient(player, {
		Action = "VipChest",
		Success = true,
		Essence = essence,
		Potion = "Small",
		EggTier = eggTier,
	})
	log:Economy("VIP", "Chest", { Player = player.Name, Essence = essence, EggTier = eggTier })
	return true
end

function VipService:TakeEgg(player: Player): boolean
	local profile = saveService:GetProfile(player)
	if not IsVip(player, profile) then
		Net.ActionResult:FireClient(
			player,
			{ Action = "VipEgg", Success = false, Reason = "Le nid VIP est reserve aux membres VIP." }
		)
		return false
	end
	if not essenceService:Spend(player, Config.VIP_EGG_PRICE, "VipEgg") then
		Net.ActionResult:FireClient(player, { Action = "VipEgg", Success = false, Reason = "Essence insuffisante." })
		return false
	end
	hatchService:GrantEgg(player, Config.VIP_EGG_TIER, "VIP")
	dataSync:Send(player)
	Net.ActionResult:FireClient(player, {
		Action = "VipEgg",
		Success = true,
		Tier = Config.VIP_EGG_TIER,
	})
	return true
end

local function Part(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = Enum.Material.Marble
	part.Anchored = true
	part.Parent = parent
	return part
end

local function BuildZone()
	if Workspace:FindFirstChild("VipZone") then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "VipZone"
	folder.Parent = Workspace
	local center = Config.VIP_ZONE_POSITION
	Part(folder, "Platform", Vector3.new(80, 2, 60), center, Color3.fromRGB(180, 145, 70))
	local gate =
		Part(folder, "Gate", Vector3.new(4, 14, 32), center + Vector3.new(-36, 7, 0), Color3.fromRGB(255, 205, 70))
	gate.Transparency = 0.45
	gate.CanCollide = false
	gate.Touched:Connect(function(hit: BasePart)
		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if player and not IsVip(player, saveService:GetProfile(player)) then
			character:PivotTo(CFrame.new(center + Vector3.new(-50, 5, 0)))
		end
	end)
	local chest = Part(
		folder,
		"DailyChest",
		Vector3.new(6, 5, 6),
		center + Vector3.new(-10, 3.5, 0),
		Color3.fromRGB(255, 195, 45)
	)
	local chestPrompt = Instance.new("ProximityPrompt")
	chestPrompt.ActionText = "Ouvrir le coffre"
	chestPrompt.ObjectText = "Coffre VIP quotidien"
	chestPrompt.HoldDuration = 0.75
	chestPrompt.MaxActivationDistance = 10
	chestPrompt.RequiresLineOfSight = false
	chestPrompt.Parent = chest
	chestPrompt.Triggered:Connect(function(player: Player)
		VipService:ClaimChest(player)
	end)
	local egg =
		Part(folder, "VipEggNest", Vector3.new(6, 2, 6), center + Vector3.new(12, 2, 0), Color3.fromRGB(255, 225, 140))
	local eggPrompt = Instance.new("ProximityPrompt")
	eggPrompt.ActionText = `Prendre l'oeuf ({Config.VIP_EGG_PRICE} Essence)`
	eggPrompt.ObjectText = "Nid VIP"
	eggPrompt.HoldDuration = 0.75
	eggPrompt.MaxActivationDistance = 10
	eggPrompt.RequiresLineOfSight = false
	eggPrompt.Parent = egg
	eggPrompt.Triggered:Connect(function(player: Player)
		VipService:TakeEgg(player)
	end)
end

function VipService:Init(container)
	saveService = container:Get("SaveService")
	essenceService = container:Get("EssenceService")
	luckService = container:Get("LuckService")
	hatchService = container:Get("HatchService")
	dataSync = container:Get("DataSync")
	log = container:Get("Log")
end

function VipService:Start()
	BuildZone()
	local function Track(player: Player)
		if tracked[player] then
			return
		end
		tracked[player] = true
		player.CharacterAdded:Connect(function()
			task.defer(function()
				self:Refresh(player)
			end)
		end)
		self:Refresh(player)
	end
	Players.PlayerAdded:Connect(Track)
	Players.PlayerRemoving:Connect(function(player)
		tracked[player] = nil
		cooldowns[player] = nil
	end)
	saveService.ProfileLoaded.Event:Connect(function(player: Player)
		Track(player)
		self:Refresh(player)
	end)
	for _, player in Players:GetPlayers() do
		Track(player)
	end
	task.spawn(function()
		while true do
			task.wait(5)
			for player in tracked do
				if player:IsDescendantOf(Players) then
					self:Refresh(player)
				end
			end
		end
	end)
end

return VipService
