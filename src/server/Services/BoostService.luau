local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Luck = require(ReplicatedStorage.Shared.Luck)
local Net = require(ReplicatedStorage.Shared.Net)

local BoostService = {}

local log
local dataSync

local boostUntil = 0
local boostBonus = 0

-- Activer prolonge la duree d'un boost deja en cours (cumul temporel,
-- bonus plafonne par construction : un seul montant serveur).
function BoostService:Activate(player: Player): boolean
	local now = os.time()
	if Luck.Active(boostUntil, now) then
		boostUntil += Config.SERVER_BOOST.Duration
	else
		boostUntil = Luck.Expiry(now, Config.SERVER_BOOST.Duration)
		boostBonus = Config.SERVER_BOOST.Bonus
	end

	workspace:SetAttribute("BoostActiveUntil", boostUntil)
	workspace:SetAttribute("BoostLuckBonus", boostBonus)
	Net.BoostState:FireAllClients({ Bonus = boostBonus, Until = boostUntil })

	log:Economy("Boost", "Activated", {
		Player = player and player.Name or "?",
		Bonus = boostBonus,
		Until = boostUntil,
	})
	return true
end

function BoostService:CurrentBonus(): number
	if not Luck.Active(boostUntil, os.time()) then
		return 0
	end
	return boostBonus
end

function BoostService:Init(container)
	log = container:Get("Log")
	dataSync = container:Get("DataSync")
end

function BoostService:Start() end

return BoostService
