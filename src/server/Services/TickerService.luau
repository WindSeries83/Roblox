local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)
local Ticker = require(ReplicatedStorage.Shared.Ticker)

local TickerService = {}

local log

local queue: { any } = {}
local lastShownAt = 0
local sessionHatches = 0
local knownTotal = 0

local StatsStore
local statsOk = pcall(function()
	StatsStore = DataStoreService:GetDataStore(Config.GLOBAL_STATS_STORE)
end)
if not statsOk then
	StatsStore = {
		UpdateAsync = function(_, _, transform)
			return transform(0)
		end,
		GetAsync = function()
			return 0
		end,
	}
end

local function FlushStats()
	local amount = sessionHatches
	if amount == 0 then
		return
	end
	sessionHatches = 0
	local key = Ticker.WeekKey(os.time())
	pcall(function()
		knownTotal = StatsStore:UpdateAsync(key, function(old)
			return (old or 0) + amount
		end) or knownTotal + amount
	end)
	log:Economy("Ticker", "StatsFlush", { Key = key, Amount = amount, Total = knownTotal })
end

-- Appelé par HatchService à chaque drop Rare+ (local).
function TickerService:Publish(payload)
	sessionHatches += 1
	table.insert(queue, payload)
	while #queue > 20 do
		table.remove(queue, 1)
	end
	if RunService:IsStudio() then
		return
	end
	pcall(function()
		MessagingService:PublishAsync(Config.TICKER_TOPIC, payload)
	end)
end

function TickerService:Init(container)
	log = container:Get("Log")
end

function TickerService:Start()
	if not RunService:IsStudio() then
		-- guard Studio : SubscribeAsync bloque indéfiniment non publié (connu)
		pcall(function()
			MessagingService:SubscribeAsync(Config.TICKER_TOPIC, function(message)
				local data = message.Data
				if type(data) == "table" and data.Rarity then
					table.insert(queue, data)
					while #queue > 20 do
						table.remove(queue, 1)
					end
				end
			end)
		end)
	end

	task.spawn(function()
		local ok, total = pcall(function()
			return StatsStore:GetAsync(Ticker.WeekKey(os.time()))
		end)
		if ok and type(total) == "number" then
			knownTotal = total
		end
	end)

	Net.GlobalStats.OnServerEvent:Connect(function(player)
		Net.GlobalStats:FireClient(player, { WeekHatches = knownTotal + sessionHatches })
	end)

	Players.PlayerAdded:Connect(function(player)
		Net.GlobalStats:FireClient(player, { WeekHatches = knownTotal + sessionHatches })
	end)

	task.spawn(function()
		while true do
			task.wait(1)
			local item, newLast = Ticker.NextToDisplay(queue, os.time(), lastShownAt)
			lastShownAt = newLast
			if item then
				Net.GlobalDrop:FireAllClients(item)
			end
		end
	end)

	task.spawn(function()
		while true do
			task.wait(Config.GLOBAL_STATS_FLUSH)
			FlushStats()
		end
	end)
end

return TickerService
