local Bootstrap = {}

Bootstrap.Services = {}

local ORDER = {
	"Log",
	"SaveService",
	"EssenceService",
	"HatchService",
	"RiftService",
	"PlayerDataService",
}

function Bootstrap:Init()
	for _, name in ORDER do
		local service = require(script.Parent.Services[name])
		self.Services[name] = service
		if service.Init then
			service:Init(self)
		end
	end
end

function Bootstrap:Start()
	for _, name in ORDER do
		local service = self.Services[name]
		if service.Start then
			service:Start()
		end
	end
	print("[Bootstrap] Services démarrés:", table.concat(ORDER, ", "))
end

function Bootstrap:Get(name)
	return self.Services[name]
end

return Bootstrap
