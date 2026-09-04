--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Net = require(ReplicatedStorage.Shared.Net)

local Bootstrap = {}

Bootstrap.Services = {}

-- Les modèles d'espèces sont des templates de clonage, pas du décor :
-- on les cache dans ReplicatedStorage pour éviter le doublon visible au spawn.
local function RelocateTemplates()
	if ReplicatedStorage:FindFirstChild("CreatureTemplates") then
		return
	end
	local folder = Workspace:FindFirstChild("Creatures")
	if not folder then
		return
	end
	folder.Name = "CreatureTemplates"
	folder.Parent = ReplicatedStorage
	print("[Bootstrap] Templates d'espèces déplacés vers ReplicatedStorage.CreatureTemplates")
end

local ORDER = {
	"Log",
	"AnalyticsService",
	"SaveService",
	"PolicyService",
	"PackService",
	"FriendRegistry",
	"SkillService",
	"SessionLuck",
	"LuckService",
	"BoostService",
	"DataSync",
	"EssenceService",
	"QuestService",
	"IndexService",
	"EvolutionService",
	"ItemService",
	"IncubationService",
	"HatchService",
	"TickerService",
	"NestService",
	"OrbService",
	"EclipseService",
	"RiftService",
	"BreedingService",
	"RebirthService",
	"SanctuaryService",
	"MarketService",
	"DuelService",
	"SeasonService",
	"LeaderboardService",
	"PurchaseService",
	"PlayerDataService",
}

function Bootstrap:Init()
	Net.EnsureRemotes()
	RelocateTemplates()
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
