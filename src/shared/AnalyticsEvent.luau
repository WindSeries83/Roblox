--!strict

local AnalyticsEvent = {}

export type Event = {
	Name: string,
	Version: number,
	Timestamp: number,
	Properties: { [string]: any },
}

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

function AnalyticsEvent.Validate(event: any): boolean
	return type(event) == "table"
		and type(event.Name) == "string"
		and event.Name ~= ""
		and event.Version == 1
		and type(event.Timestamp) == "number"
		and type(event.Properties) == "table"
end

return AnalyticsEvent
