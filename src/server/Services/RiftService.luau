local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Net = require(ReplicatedStorage.Shared.Net)

local RiftService = {}

local log
local saveService
local essenceService
local hatchService
local itemService
local questService

local container

local portal: Model? = nil
local worldActive = false
local worldEndsAt = 0

local Combat = {}
local nextGuardianTick = 0

local function TeamPower(player: Player): number
	local profile = saveService:GetProfile(player)
	if not profile then
		return 0
	end
	local power = 0
	for _, creature in profile.Data.Creatures do
		power += creature.Power
	end
	return power
end

local function BuildPortal()
	local model = Instance.new("Model")
	model.Name = "RiftPortal"

	local ring = Instance.new("Part")
	ring.Name = "Ring"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(10, 14, 10)
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(140, 60, 255)
	ring.Transparency = 0.35
	ring.Anchored = true
	ring.CanCollide = false
	ring.Parent = model

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(160, 90, 255)
	light.Brightness = 3
	light.Range = 30
	light.Parent = ring

	model.PrimaryPart = ring
	model:PivotTo(CFrame.new(Config.RIFT_PORTAL_POSITION))
	model.Parent = Workspace
	return model
end

local function BuildGuardian(owner: Player): Part
	local guardian = Instance.new("Part")
	guardian.Name = `Guardian_{owner.Name}`
	guardian.Size = Vector3.new(8, 12, 6)
	guardian.Material = Enum.Material.Slate
	guardian.Color = Color3.fromRGB(120, 30, 40)
	guardian.Anchored = true
	guardian.CanCollide = false
	guardian.CFrame = CFrame.new(Config.RIFT_PORTAL_POSITION + Vector3.new(0, 4, 14))
	guardian.Parent = Workspace

	local tag = Instance.new("BillboardGui")
	tag.Name = "Tag"
	tag.Size = UDim2.fromOffset(120, 24)
	tag.StudsOffset = Vector3.new(0, 8, 0)
	tag.AlwaysOnTop = true
	tag.Parent = guardian

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "Gardien de faille"
	label.TextColor3 = Color3.fromRGB(255, 90, 90)
	label.TextScaled = true
	label.Parent = tag

	return guardian
end

local function BuildCrystal(owner: Player): Part
	local crystal = Instance.new("Part")
	crystal.Name = `Crystal_{owner.Name}`
	crystal.Shape = Enum.PartType.Ball
	crystal.Size = Vector3.new(4, 6, 4)
	crystal.Material = Enum.Material.Neon
	crystal.Color = Color3.fromRGB(120, 220, 255)
	crystal.Anchored = true
	crystal.CanCollide = false
	crystal.CFrame = CFrame.new(Config.RIFT_PORTAL_POSITION + Vector3.new(0, 6, 14))
	crystal.Parent = Workspace

	local tag = Instance.new("BillboardGui")
	tag.Name = "Tag"
	tag.Size = UDim2.fromOffset(140, 24)
	tag.StudsOffset = Vector3.new(0, 4, 0)
	tag.AlwaysOnTop = true
	tag.Parent = crystal

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "Cristal de faille — touche-le"
	label.TextColor3 = Color3.fromRGB(140, 230, 255)
	label.TextScaled = true
	label.Parent = tag

	return crystal
end

local function SyncPlayer(player: Player)
	local combat = Combat[player]
	if not combat then
		Net.RiftSync:FireClient(player, { InRift = false })
		return
	end
	Net.RiftSync:FireClient(player, {
		InRift = true,
		Phase = combat.Phase,
		GuardianHP = math.max(0, math.floor(combat.GuardianHP)),
		GuardianMaxHP = combat.GuardianMaxHP,
		PlayerHP = math.max(0, math.floor(combat.PlayerHP)),
		PlayerMaxHP = combat.PlayerMaxHP,
	})
end

local function CleanupCombat(player: Player)
	local combat = Combat[player]
	if not combat then
		return
	end
	Combat[player] = nil
	if combat.GuardianPart and combat.GuardianPart.Parent then
		combat.GuardianPart:Destroy()
	end
	if combat.CrystalPart and combat.CrystalPart.Parent then
		combat.CrystalPart:Destroy()
	end
	SyncPlayer(player)
end

local function WinRift(player: Player)
	local combat = Combat[player]
	if not combat then
		return
	end

	local profile = saveService:GetProfile(player)
	local rate = essenceService.GetRate(player)
	local essence =
		math.max(Config.RIFT_MIN_REWARD, math.floor(rate * Config.RIFT_REWARD_SECONDS * Config.RIFT_ESSENCE_MULT))
	essenceService:Add(player, essence, "RiftCrystal")

	local eggTier = Gameplay.WeightedRoll(Config.RIFT_EGG_WEIGHTS)
	hatchService:GrantEgg(player, eggTier, "Rift")

	local relicRoll = Gameplay.WeightedRoll(Config.RIFT_RELIC_WEIGHTS)
	local relicTier = nil
	if relicRoll and relicRoll ~= "None" then
		relicTier = tonumber(relicRoll:sub(2))
		if relicTier then
			itemService:GrantItem(player, "Relic", relicTier, "Rift")
		end
	end

	profile.Data.Stats.RiftsCompleted += 1
	questService:OnRiftWon(player)
	local seasonService = container:Get("SeasonService")
	if seasonService then
		seasonService:OnRiftWon(player)
	end

	Net.RiftEnded:FireClient(player, { Win = true, Essence = essence, EggTier = eggTier, RelicTier = relicTier })
	log:Economy("Rift", "Complete", {
		Player = player.Name,
		Essence = essence,
		EggTier = eggTier,
		RelicTier = relicTier,
		Total = profile.Data.Stats.RiftsCompleted,
	})

	CleanupCombat(player)
end

local function LoseRift(player: Player)
	Net.RiftEnded:FireClient(player, { Win = false })
	log:Economy("Rift", "Defeat", { Player = player.Name })
	CleanupCombat(player)
end

local function JoinRift(player: Player, _character: Model?)
	local profile = saveService:GetProfile(player)
	if not profile then
		return
	end
	if Combat[player] then
		return
	end

	local power = TeamPower(player)
	local maxHp = Config.RIFT_GUARDIAN_BASE_HP + power * Config.RIFT_GUARDIAN_HP_PER_POWER

	Combat[player] = {
		Phase = "Fight",
		GuardianHP = maxHp,
		GuardianMaxHP = maxHp,
		PlayerHP = Config.RIFT_PLAYER_MAX_HP,
		PlayerMaxHP = Config.RIFT_PLAYER_MAX_HP,
		LastAttack = 0,
		NextGuardianHit = os.clock() + 2,
		GuardianPart = BuildGuardian(player),
		CrystalPart = nil,
	}

	log:Economy("Rift", "Enter", { Player = player.Name, Power = power, GuardianHP = maxHp })
	SyncPlayer(player)
end

local function onPortalTouched(part: BasePart)
	if not worldActive then
		return
	end
	local character = part.Parent
	if not character then
		return
	end
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		JoinRift(player, character)
	end
end

local function onCrystalTouched(part: BasePart)
	local character = part.Parent
	if not character then
		return
	end
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end
	local combat = Combat[player]
	if combat and combat.Phase == "Crystal" and combat.CrystalPart == part then
		WinRift(player)
	end
end

function RiftService:Init(cont)
	container = cont
	log = cont:Get("Log")
	saveService = cont:Get("SaveService")
	essenceService = cont:Get("EssenceService")
	hatchService = cont:Get("HatchService")
	itemService = cont:Get("ItemService")
	questService = cont:Get("QuestService")
end

function RiftService:GetStatePayload()
	return { Active = worldActive, EndsAt = worldEndsAt }
end

function RiftService:Start()
	Net.RiftAttack.OnServerEvent:Connect(function(player: Player)
		local combat = Combat[player]
		if not combat or combat.Phase ~= "Fight" then
			return
		end
		if os.clock() - combat.LastAttack < Config.RIFT_ATTACK_COOLDOWN then
			return
		end
		combat.LastAttack = os.clock()

		local power = TeamPower(player)
		local damage = math.floor(power * Config.RIFT_PLAYER_DAMAGE_MULT)
		combat.GuardianHP -= damage

		if combat.GuardianHP <= 0 then
			combat.Phase = "Crystal"
			if combat.GuardianPart then
				combat.GuardianPart:Destroy()
				combat.GuardianPart = nil
			end
			local crystal = BuildCrystal(player)
			crystal.Touched:Connect(onCrystalTouched)
			combat.CrystalPart = crystal
			log:Economy("Rift", "GuardianDown", { Player = player.Name })
		end
		SyncPlayer(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		CleanupCombat(player)
	end)

	task.spawn(function()
		while true do
			local attributeInterval = script:GetAttribute("RiftInterval")
			local interval = if type(attributeInterval) == "number" and attributeInterval > 0
				then attributeInterval
				else Config.RIFT_INTERVAL
			task.wait(interval)

			worldActive = true
			worldEndsAt = os.clock() + Config.RIFT_ACTIVE_SECONDS
			portal = BuildPortal()
			portal.PrimaryPart.Touched:Connect(onPortalTouched)
			Net.RiftWorld:FireAllClients({ Active = true, EndsAt = worldEndsAt })
			log:Economy("Rift", "Opened", { EndsAt = worldEndsAt })

			task.wait(Config.RIFT_ACTIVE_SECONDS)

			worldActive = false
			if portal then
				portal:Destroy()
				portal = nil
			end
			Net.RiftWorld:FireAllClients({ Active = false })
			log:Economy("Rift", "Closed", {})
		end
	end)

	task.spawn(function()
		while true do
			local now = os.clock()
			if now >= nextGuardianTick then
				nextGuardianTick = now + 0.5
				for player, combat in Combat do
					if combat.Phase == "Fight" and now >= combat.NextGuardianHit then
						combat.NextGuardianHit = now + Config.RIFT_GUARDIAN_ATTACK_INTERVAL
						combat.PlayerHP -= Config.RIFT_GUARDIAN_DAMAGE
						if combat.PlayerHP <= 0 then
							LoseRift(player)
						else
							SyncPlayer(player)
						end
					elseif combat.Phase == "Crystal" and combat.CrystalPart then
						local character = player.Character
						if character then
							local root = character:FindFirstChild("HumanoidRootPart")
							if root and (root.Position - combat.CrystalPart.Position).Magnitude < 6 then
								WinRift(player)
							end
						end
					end
				end
			end
			task.wait(0.5)
		end
	end)
end

return RiftService
