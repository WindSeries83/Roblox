--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Config = require(ReplicatedStorage.Shared.Config)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local GroupBonus = require(ReplicatedStorage.Shared.GroupBonus)
local Net = require(ReplicatedStorage.Shared.Net)
local WorldProgression = require(ReplicatedStorage.Shared.WorldProgression)

local DepthService = {}
local container: any
local cooldowns: { [Player]: { [string]: number } } = {}
local activeRush: { [Player]: string } = {}

local function sync(player: Player)
	container:Get("DataSync"):Send(player)
end

function DepthService:GroupMult(player: Player): number
	local profile = container:Get("SaveService"):GetProfile(player)
	return GroupBonus.Mult(profile ~= nil and profile.Data.GroupMember == true)
end

function DepthService:OnProfileLoaded(player: Player, profile: any)
	WorldProgression.SyncUnlocks(profile.Data)
	if Config.GROUP_ID > 0 then
		local ok, member = pcall(player.IsInGroupAsync, player, Config.GROUP_ID)
		profile.Data.GroupMember = ok and member == true
	else
		profile.Data.GroupMember = false
	end
	player:SetAttribute("GroupMember", profile.Data.GroupMember)
	player:SetAttribute("EquippedTitle", profile.Data.EquippedTitle)
	player:SetAttribute("CurrentWorld", profile.Data.CurrentWorld)
	local today = os.date("%Y-%m-%d")
	if profile.Data.GroupMember and profile.Data.GroupGiftDate ~= today then
		container:Get("HatchService"):GrantEgg(player, Config.GROUP_DAILY_EGG, "GroupDaily")
		profile.Data.GroupGiftDate = today
	end
end

function DepthService:OnRiftComplete(player: Player, duration: number)
	local worldId = activeRush[player]
	activeRush[player] = nil
	if not worldId then
		return
	end
	local profile = container:Get("SaveService"):GetProfile(player)
	if not profile then
		return
	end
	local completed = duration <= Config.WORLDS[worldId].Rush.TargetSeconds
	local first = WorldProgression.RecordRush(profile.Data, worldId, duration)
	if first then
		local reward = Config.WORLDS[worldId].Rush
		if not table.find(profile.Data.Titles, reward.Title) then
			table.insert(profile.Data.Titles, reward.Title)
		end
		profile.Data.Cosmetics[reward.Cosmetic] = true
	end
	Net.RushSync:FireClient(player, { World = worldId, Duration = duration, Success = completed })
	container:Get("AnalyticsService"):Event("rush_complete", { World = worldId, Duration = duration, Success = completed })
	sync(player)
end

function DepthService:OnRiftFailed(player: Player)
	local worldId = activeRush[player]
	activeRush[player] = nil
	if worldId then
		Net.RushSync:FireClient(player, { World = worldId, Success = false })
	end
end

function DepthService:Init(cont: any)
	container = cont
end

function DepthService:Start()
	Net.WorldSelect.OnServerEvent:Connect(function(player: Player, worldId: unknown)
		if not Gameplay.CheckCooldown(cooldowns, player, "World", 1) then
			return
		end
		local profile = container:Get("SaveService"):GetProfile(player)
		if profile and WorldProgression.CanEnter(profile.Data, worldId) then
			activeRush[player] = nil
			profile.Data.CurrentWorld = worldId
			player:SetAttribute("CurrentWorld", worldId)
			container:Get("AnalyticsService"):Event("world_select", { World = worldId })
			sync(player)
		end
	end)

	Net.RushRequest.OnServerEvent:Connect(function(player: Player)
		if not Gameplay.CheckCooldown(cooldowns, player, "Rush", 2) then
			return
		end
		local profile = container:Get("SaveService"):GetProfile(player)
		local worldId = profile and profile.Data.CurrentWorld
		if profile and Config.WORLDS[worldId] and Config.WORLDS[worldId].Rush then
			activeRush[player] = worldId
			Net.RushSync:FireClient(player, { World = worldId, Active = true, TargetSeconds = Config.WORLDS[worldId].Rush.TargetSeconds })
		end
	end)

	Net.EquipTitle.OnServerEvent:Connect(function(player: Player, title: unknown)
		if type(title) ~= "string" or #title > 80 or not Gameplay.CheckCooldown(cooldowns, player, "Title", 1) then
			return
		end
		local profile = container:Get("SaveService"):GetProfile(player)
		if profile and (title == "" or table.find(profile.Data.Titles, title)) then
			profile.Data.EquippedTitle = title
			player:SetAttribute("EquippedTitle", title)
			sync(player)
		end
	end)

	Net.CustomizeCreature.OnServerEvent:Connect(function(player: Player, action: unknown, creatureId: unknown, value: unknown)
		if type(action) ~= "string" or type(creatureId) ~= "string" or type(value) ~= "string" then
			return
		end
		if #creatureId > 64 or #value > 80 or not utf8.len(value) or not Gameplay.CheckCooldown(cooldowns, player, "Customize", 1) then
			return
		end
		local profile = container:Get("SaveService"):GetProfile(player)
		local creature = profile and Gameplay.FindCreature(profile.Data.Creatures, creatureId)
		if not creature then
			return
		end
		if action == "Cosmetic" then
			if value == "" or (Config.COSMETICS[value] and profile.Data.Cosmetics[value]) then
				creature.Cosmetic = if value == "" then nil else value
				sync(player)
			end
			return
		end
		if action ~= "Rename" then
			return
		end
		local trimmed = string.match(value, "^%s*(.-)%s*$") or ""
		if trimmed == "" then
			creature.CustomName = nil
			sync(player)
			return
		end
		if (utf8.len(trimmed) or 99) > 20 or profile.Data.RenameTickets < 1 then
			return
		end
		local ok, filtered = pcall(function()
			return TextService:FilterStringAsync(trimmed, player.UserId):GetNonChatStringForBroadcastAsync()
		end)
		if ok and filtered ~= "" then
			profile.Data.RenameTickets -= 1
			creature.CustomName = filtered
			sync(player)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		activeRush[player] = nil
		cooldowns[player] = nil
	end)
end

return DepthService
