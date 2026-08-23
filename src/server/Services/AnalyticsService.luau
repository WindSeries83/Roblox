local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Funnel = require(ReplicatedStorage.Shared.Funnel)

local AnalyticsService = {}

local analytics = game:GetService("AnalyticsService")
local log

function AnalyticsService:Event(name: string, params: { [string]: any })
	-- L'API analytics est indisponible en Studio : jamais bloquant.
	pcall(function()
		analytics:LogCustomEvent(Enum.AnalyticsCustomFieldKeys.CustomField01, name, 1)
	end)
	log:Economy("Analytics", name, params)
end

function AnalyticsService:Funnel(profile, key: string)
	if not profile then
		return
	end
	Funnel.Stamp(profile.Data.Stats.Funnel, key, os.time())
end

function AnalyticsService:Init(container)
	log = container:Get("Log")
end

function AnalyticsService:Start() end

return AnalyticsService
