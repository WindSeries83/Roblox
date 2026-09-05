--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Net = require(ReplicatedStorage.Shared.Net)
local Offers = require(ReplicatedStorage.Shared.Offers)

local RenameService = {}

local saveService
local dataSync
local container
local pending: { [Player]: { CreatureId: string, Name: string, ExpiresAt: number } } = {}

function RenameService.NormalizeName(value: any): string?
	if type(value) ~= "string" then
		return nil
	end
	local name = string.gsub(value, "^%s*(.-)%s*$", "%1")
	if #name < 1 or #name > 24 or string.find(name, "[%c]") then
		return nil
	end
	return name
end

local function Notify(player: Player, success: boolean, reason: string?, name: string?)
	Net.ActionResult:FireClient(player, {
		Action = "RenameCreature",
		Success = success,
		Reason = reason,
		Name = name,
	})
end

function RenameService:Apply(player: Player, creatureId: string, name: string, consumeTicket: boolean): boolean
	local profile = saveService:GetProfile(player)
	local creature = profile and Gameplay.FindCreature(profile.Data.Creatures, creatureId)
	if not profile or not creature then
		Notify(player, false, "Créature introuvable")
		return false
	end
	if consumeTicket and (type(profile.Data.RenameTickets) ~= "number" or profile.Data.RenameTickets < 1) then
		Notify(player, false, "Aucun ticket de renommage")
		return false
	end

	local previousName = creature.CustomName
	local previousTickets = profile.Data.RenameTickets or 0
	creature.CustomName = name
	if consumeTicket then
		profile.Data.RenameTickets = previousTickets - 1
	end
	local saved = saveService:SaveProfile(player, function(data)
		local current = Gameplay.FindCreature(data.Creatures, creatureId)
		return current
			and current.CustomName == name
			and (not consumeTicket or data.RenameTickets == previousTickets - 1)
	end)
	if not saved then
		creature.CustomName = previousName
		profile.Data.RenameTickets = previousTickets
		Notify(player, false, "Sauvegarde indisponible")
		return false
	end
	dataSync:Send(player)
	Notify(player, true, nil, name)
	return true
end

function RenameService:Request(player: Player, creatureIdValue: any, rawName: any): boolean
	local profile = saveService:GetProfile(player)
	local creatureId = if type(creatureIdValue) == "string" then creatureIdValue else nil
	local name = RenameService.NormalizeName(rawName)
	if not profile or not creatureId or not name then
		Notify(player, false, "Nom invalide (1 à 24 caractères)")
		return false
	end
	if not Gameplay.FindCreature(profile.Data.Creatures, creatureId) then
		Notify(player, false, "Créature introuvable")
		return false
	end

	if (profile.Data.RenameTickets or 0) > 0 then
		return self:Apply(player, creatureId, name, true)
	end
	local offer = Offers.All.RenameTicket
	local sku = Offers.Sku(offer)
	if not Config.PURCHASES_ENABLED or not Offers.IsAvailable(offer) then
		Notify(player, false, "Le ticket de renommage n'est pas encore disponible")
		return false
	end
	pending[player] = { CreatureId = creatureId, Name = name, ExpiresAt = os.clock() + 120 }
	Net.ActionResult:FireClient(player, { Action = "RenamePrompt", Success = false, Sku = sku })
	return true
end

function RenameService:GrantTicket(player: Player): boolean
	local profile = saveService:GetProfile(player)
	if not profile then
		return false
	end
	local request = pending[player]
	if request and request.ExpiresAt > os.clock() then
		local creature = Gameplay.FindCreature(profile.Data.Creatures, request.CreatureId)
		if creature then
			creature.CustomName = request.Name
			dataSync:Send(player)
			Notify(player, true, nil, request.Name)
			return true
		end
	end
	pending[player] = nil
	profile.Data.RenameTickets = math.max(0, math.floor(profile.Data.RenameTickets or 0)) + 1
	return true
end

function RenameService:Init(cont)
	container = cont
end

function RenameService:Start()
	saveService = container:Get("SaveService")
	dataSync = container:Get("DataSync")
	Net.RenameCreature.OnServerEvent:Connect(function(player: Player, creatureId: any, name: any)
		self:Request(player, creatureId, name)
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		pending[player] = nil
	end)
end

return RenameService
