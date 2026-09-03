local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Funnel = require(ReplicatedStorage.Shared.Funnel)
local AnalyticsEvent = require(ReplicatedStorage.Shared.AnalyticsEvent)

local AnalyticsService = {}

local analytics = game:GetService("AnalyticsService")
local log

local FUNNEL_EVENTS = {
	FirstHatchAt = "first_hatch",
	FirstRarePlusAt = "first_rare_plus",
	FirstEpicPlusAt = "first_epic_plus",
	FirstPurchaseAt = "first_purchase",
}

function AnalyticsService:Event(name: string, params: { [string]: any })
	local event = AnalyticsEvent.New(name, params)
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

function AnalyticsService:Funnel(profile, key: string)
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
		self:Event(eventName, { Milestone = key, At = timestamp })
	end
end

function AnalyticsService:Init(container)
	log = container:Get("Log")
end

return AnalyticsService
