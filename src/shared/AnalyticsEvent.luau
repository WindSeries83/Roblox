--!strict

local AnalyticsEvent = {}

export type Event = {
	Name: string,
	Version: number,
	Timestamp: number,
	Properties: { [string]: any },
}

export type Properties = { [string]: any }

function AnalyticsEvent.New(name: any, properties: any, now: number?): Event?
	if type(name) ~= "string" or name == "" or type(properties) ~= "table" then
		return nil
	end
	return {
		Name = name,
		Version = 1,
		Timestamp = now or os.time(),
		Properties = properties,
	}
end

function AnalyticsEvent.WithContext(properties: Properties, userId: number, sessionId: string, at: number?): Properties
	local enriched = table.clone(properties)
	enriched.user_id = userId
	enriched.session_id = sessionId
	enriched.at = at or os.time()
	enriched.schema_version = 1
	return enriched
end

function AnalyticsEvent.Validate(event: any): boolean
	return type(event) == "table"
		and type(event.Name) == "string"
		and event.Name ~= ""
		and event.Version == 1
		and type(event.Timestamp) == "number"
		and type(event.Properties) == "table"
end

-- Stable breakdowns only: never put session, player or transaction IDs in custom fields.
function AnalyticsEvent.Dimensions(properties: Properties): { [number]: string }
	local fields = {}
	for index, key in { "Rarity", "Mutation", "Source" } do
		local value = properties[key]
		if type(value) == "string" and value ~= "" then
			fields[index] = value
		end
	end
	return fields
end

return AnalyticsEvent
