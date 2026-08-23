local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)
local Orbs = require(ReplicatedStorage.Shared.Orbs)

local OrbService = {}

local log
local essenceService

-- Centre de l'enclos : grille sanctuaire rendue par CreatureDisplay.GridPosition.
local ENCLOSURE_CENTER = Vector3.new(-26, 11, -15)

local activeCount = 0
local claims: { [Player]: { number } } = {}
local rng = Random.new(42)

local function TryClaim(player: Player, orb: BasePart)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - orb.Position).Magnitude > 30 then
		return
	end

	local now = os.time()
	local list = claims[player] or {}
	local ok, reason = Orbs.CanClaim(list, now, Config.ORB_MAX_PER_HOUR)
	if not ok then
		log:Economy("Orb", "Rejected", { Player = player.Name, Reason = reason })
		return
	end

	local amount = essenceService:Add(player, Orbs.Reward(essenceService.GetRate(player)), "Orb")
	table.insert(list, now)
	claims[player] = list

	log:Economy("Orb", "Claimed", { Player = player.Name, Amount = amount })
	Net.OrbClaimed:FireAllClients({ Position = orb.Position, Amount = amount })
	orb:Destroy()
end

local function SpawnOrb()
	activeCount += 1
	local angle = rng:NextNumber(0, math.pi * 2)
	local dist = rng:NextNumber(4, 11)

	local orb = Instance.new("Part")
	orb.Name = "EssenceOrb"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(1.2, 1.2, 1.2)
	orb.Material = Enum.Material.Neon
	orb.Color = Color3.fromRGB(255, 205, 80)
	orb.Anchored = true
	orb.CanCollide = false
	orb.Position = ENCLOSURE_CENTER + Vector3.new(math.cos(angle) * dist, 1.2, math.sin(angle) * dist)

	local light = Instance.new("PointLight")
	light.Color = orb.Color
	light.Brightness = 1
	light.Range = 8
	light.Parent = orb

	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 24
	click.Parent = orb
	click.MouseClick:Connect(function(player: Player)
		TryClaim(player, orb)
	end)

	orb.Destroying:Connect(function()
		activeCount -= 1
	end)
	orb.Parent = Workspace
end

function OrbService:Init(cont)
	log = cont:Get("Log")
	essenceService = cont:Get("EssenceService")
end

function OrbService:Start()
	task.spawn(function()
		local lastAt = os.clock()
		while true do
			lastAt = Orbs.NextSpawnAt(lastAt, os.clock(), Config.ORB_INTERVAL)
			if lastAt > os.clock() then
				task.wait(lastAt - os.clock())
			end
			if activeCount < Config.ORB_MAX_CONCURRENT then
				SpawnOrb()
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		claims[player] = nil
	end)
end

return OrbService
