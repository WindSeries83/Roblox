local HttpService = game:GetService("HttpService")

local Log = {}

Log.Entries = {}

function Log:Init(_) end

function Log:Economy(source: string, event: string, detail: { [string]: any })
	local entry = {
		Time = os.time(),
		Source = source,
		Event = event,
		Detail = detail,
	}
	table.insert(self.Entries, entry)
	if #self.Entries > 500 then
		table.remove(self.Entries, 1)
	end
	print(`[ECON] {source} | {event} | {HttpService:JSONEncode(detail)}`)
end

return Log
