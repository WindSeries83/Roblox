--!strict

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Funnel = require(ReplicatedStorage.Shared.Funnel)
local AnalyticsEvent = require(ReplicatedStorage.Shared.AnalyticsEvent)

local AnalyticsService = {}

local analytics = game:GetService("AnalyticsService")
local log

local serverSessionId = if game.JobId ~= "" then game.JobId else "studio"
local sessions: { [Player]: string } = {}
local sessionStartedAt: { [Player]: number } = {}

local FUNNEL_EVENTS = {
	FirstHatchAt = "first_hatch",
	FirstRarePlusAt = "first_rare_plus",
	FirstEpicPlusAt = "first_epic_plus",
	FirstPurchaseAt = "first_purchase",
}

function AnalyticsService:Event(name: string, params: { [string]: any }, player: Player?)
	local sessionId = if player then sessions[player] or serverSessionId else serverSessionId
	local userId = if player then player.UserId else 0
	local properties = AnalyticsEvent.WithContext(params, userId, sessionId)
	local event = AnalyticsEvent.New(name, properties)
	if not event then
		return
	end
	-- L'API analytics est indisponible en Studio : jamais bloquant.
	pcall(function()
		analytics:LogCustomEvent(Enum.AnalyticsCustomFieldKeys.CustomField01, name, 1)
	end)
	log:Economy("Analytics", name, {
		Version = event.Version,
		Timestamp = event.Timestamp,
		Properties = event.Properties,
	})
end

function AnalyticsService:SessionStart(player: Player, daysSinceLast: number)
	if sessions[player] then
		return
	end
	local sessionId = HttpService:GenerateGUID(false)
	sessions[player] = sessionId
	sessionStartedAt[player] = os.time()
	self:Event("session_start", {
		days_since_last = math.max(0, math.floor(daysSinceLast)),
	}, player)
end

function AnalyticsService:SessionEnd(player: Player)
	if not sessions[player] then
		return
	end
	local startedAt = sessionStartedAt[player] or os.time()
	self:Event("session_end", {
		duration = math.max(0, os.time() - startedAt),
	}, player)
	sessions[player] = nil
	sessionStartedAt[player] = nil
end

function AnalyticsService:Funnel(profile, key: string, player: Player?)
	if not profile then
		return
	end
	local funnel = profile.Data.Stats.Funnel
	if (funnel[key] or 0) ~= 0 then
		return
	end
	local timestamp = os.time()
	Funnel.Stamp(funnel, key, timestamp)
	local eventName = FUNNEL_EVENTS[key]
	if eventName then
		self:Event(eventName, { Milestone = key, At = timestamp }, player)
	end
end

function AnalyticsService:Init(container)
	log = container:Get("Log")
end

return AnalyticsService
