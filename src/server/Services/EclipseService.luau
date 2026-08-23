local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Eclipse = require(ReplicatedStorage.Shared.Eclipse)
local Net = require(ReplicatedStorage.Shared.Net)

local EclipseService = {}

local log
local savedClockTime = nil

function EclipseService:IsActive(): boolean
	return Eclipse.IsActive(os.time(), Config.ECLIPSE_INTERVAL, Config.ECLIPSE_DURATION)
end

function EclipseService:MutationBonus(): number
	return if self:IsActive() then Config.ECLIPSE_MUTATION_BONUS else 0
end

local function Broadcast(active: boolean)
	local now = os.time()
	workspace:SetAttribute("EclipseActive", active)
	workspace:SetAttribute(
		"EclipseUntil",
		if active
			then now - (now % Config.ECLIPSE_INTERVAL) + Config.ECLIPSE_DURATION
			else Eclipse.NextBoundary(now, Config.ECLIPSE_INTERVAL)
	)
	Net.EclipseState:FireAllClients({
		Active = active,
		Until = workspace:GetAttribute("EclipseUntil"),
		Bonus = Config.ECLIPSE_MUTATION_BONUS,
	})
	log:Economy("Eclipse", if active then "Started" else "Ended", {})
end

local function Announce()
	Net.QuestsSync:FireAllClients({
		Notice = { Type = "Eclipse", Name = "Éclipse !", Desc = "Mutations ×10 pendant 10 minutes" },
	})
end

function EclipseService:Apply(active: boolean)
	if active then
		savedClockTime = savedClockTime or Lighting.ClockTime
		Lighting.ClockTime = Config.ECLIPSE_CLOCKTIME
		Broadcast(true)
		Announce()
	else
		if savedClockTime then
			Lighting.ClockTime = savedClockTime
			savedClockTime = nil
		end
		Broadcast(false)
	end
end

function EclipseService:Init(cont)
	log = cont:Get("Log")
end

function EclipseService:Start()
	local service = self
	task.spawn(function()
		local wasActive = service:IsActive()
		service:Apply(wasActive)
		while true do
			local now = os.time()
			local boundary = Eclipse.NextBoundary(now, Config.ECLIPSE_INTERVAL)
			task.wait(math.max(1, boundary - now))
			local active = service:IsActive()
			if active ~= wasActive then
				wasActive = active
				service:Apply(active)
			end
		end
	end)
end

return EclipseService
