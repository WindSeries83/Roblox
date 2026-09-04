--!strict

local Players = game:GetService("Players")
local PolicyServiceApi = game:GetService("PolicyService")
local PolicyService = {}
PolicyService.PolicyLoaded = Instance.new("BindableEvent")
local DataSync
local restrictive = {
	Loaded = false,
	ArePaidRandomItemsRestricted = true,
	IsPaidItemTradingAllowed = false,
}
local policies: { [Player]: typeof(restrictive) } = {}

local function Query(player: Player)
	local ok, info = pcall(function()
		return PolicyServiceApi:GetPolicyInfoForPlayerAsync(player)
	end)
	if not player:IsDescendantOf(Players) then
		return
	end
	local policy = {
		Loaded = ok and type(info) == "table",
		ArePaidRandomItemsRestricted = not ok or type(info) ~= "table" or info.ArePaidRandomItemsRestricted == true,
		IsPaidItemTradingAllowed = ok and type(info) == "table" and info.IsPaidItemTradingAllowed == true,
	}
	policies[player] = policy
	DataSync:Send(player)
	PolicyService.PolicyLoaded:Fire(player)
end

function PolicyService:Init(container)
	local saveService = container:Get("SaveService")
	DataSync = container:Get("DataSync")
	saveService.ProfileLoaded.Event:Connect(function(player: Player)
		task.spawn(Query, player)
	end)
end

function PolicyService:GetState(player: Player)
	return policies[player] or restrictive
end

function PolicyService:Start()
	Players.PlayerRemoving:Connect(function(player)
		policies[player] = nil
	end)
end

function PolicyService:CanUsePaidRandomItems(player: Player): boolean
	local policy = self:GetState(player)
	return policy.Loaded and not policy.ArePaidRandomItemsRestricted
end

function PolicyService:CanTradePaidItems(player: Player): boolean
	local policy = self:GetState(player)
	return policy.Loaded and policy.IsPaidItemTradingAllowed
end

return PolicyService
