--!strict

local Players = game:GetService("Players")
local PolicyServiceApi = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)

local PolicyService = {}
local policies: { [Player]: { ArePaidRandomItemsRestricted: boolean, IsPaidItemTradingAllowed: boolean } } = {}
local saveService

local function Query(player: Player)
	local ok, info = pcall(function()
		return PolicyServiceApi:GetPolicyInfoForPlayerAsync(player)
	end)
	local policy = {
		ArePaidRandomItemsRestricted = not ok or info.ArePaidRandomItemsRestricted == true,
		IsPaidItemTradingAllowed = ok and info.IsPaidItemTradingAllowed == true,
	}
	policies[player] = policy
	Net.PolicyState:FireClient(player, policy)
end

function PolicyService:Init(container)
	saveService = container:Get("SaveService")
	saveService.ProfileLoaded.Event:Connect(function(player: Player)
		task.spawn(Query, player)
	end)
end

function PolicyService:Start()
	Players.PlayerRemoving:Connect(function(player)
		policies[player] = nil
	end)
end

function PolicyService:CanUsePaidRandomItems(player: Player): boolean
	local policy = policies[player]
	return policy ~= nil and not policy.ArePaidRandomItemsRestricted
end

function PolicyService:CanTradePaidItems(player: Player): boolean
	local policy = policies[player]
	return policy ~= nil and policy.IsPaidItemTradingAllowed
end

return PolicyService
