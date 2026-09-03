local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)
local Ticker = require(ReplicatedStorage.Shared.Ticker)
local SafeStore = require(script.Parent.SafeStore)

local TickerService = {}

local log
local analyticsService

local queue: { any } = {}
local lastShownAt = 0
local sessionHatches = 0
local knownTotal = 0
local activeWeekKey = Ticker.WeekKey(os.time())

local StatsStore = SafeStore.Get(Config.GLOBAL_STATS_STORE, 0)

local function FlushStats(key: string?): boolean
	local amount = sessionHatches
	if amount == 0 then
		return true
	end
	local targetKey = key or activeWeekKey
	local ok = pcall(function()
		local updated = StatsStore:UpdateAsync(targetKey, function(old)
			return (old or 0) + amount
		end)
		knownTotal = updated or knownTotal + amount
	end)
	if not ok then
		return false
	end
	-- Preserve hatches that arrived while UpdateAsync yielded.
	sessionHatches = math.max(0, sessionHatches - amount)
	log:Economy("Ticker", "StatsFlush", { Key = targetKey, Amount = amount, Total = knownTotal })
	if analyticsService then
		analyticsService:Event("ticker_stats_flush", { Key = targetKey, Amount = amount, Total = knownTotal })
	end
	return true
end

local function LoadStats(key: string)
	task.spawn(function()
		local ok, total = pcall(function()
			return StatsStore:GetAsync(key)
		end)
		if ok and activeWeekKey == key and type(total) == "number" then
			knownTotal = total
		end
	end)
end

local function EnsureWeek(now: number): boolean
	if not Ticker.IsNewWeek(activeWeekKey, now) then
		return true
	end
	if not FlushStats(activeWeekKey) then
		return false
	end
	activeWeekKey = Ticker.WeekKey(now)
	knownTotal = 0
	LoadStats(activeWeekKey)
	if analyticsService then
		analyticsService:Event("ticker_week_reset", { Key = activeWeekKey })
	end
	return true
end

-- Appelé par HatchService à chaque drop Rare+ (local).
function TickerService:Publish(payload)
	EnsureWeek(os.time())
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
	analyticsService = container:Get("AnalyticsService")
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

	activeWeekKey = Ticker.WeekKey(os.time())
	LoadStats(activeWeekKey)

	Net.GlobalStats.OnServerEvent:Connect(function(player)
		EnsureWeek(os.time())
		Net.GlobalStats:FireClient(player, { WeekHatches = knownTotal + sessionHatches })
	end)

	Players.PlayerAdded:Connect(function(player)
		EnsureWeek(os.time())
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
