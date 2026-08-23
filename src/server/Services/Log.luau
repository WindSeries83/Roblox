local HttpService = game:GetService("HttpService")

local Log = {}

function Log:Init(_) end

function Log:Economy(source: string, event: string, detail: { [string]: any })
	print(`[ECON] {source} | {event} | {HttpService:JSONEncode(detail)}`)
end

return Log
