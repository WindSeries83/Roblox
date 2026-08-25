local Players = game:GetService("Players")

local NestService = {}

local saveService
local container

-- Le tutoriel se déroule sur la couveuse principale (déplacée au spawn par
-- IncubationService) : l'œuf de départ (Source="Nest") est posé dessus
-- automatiquement à l'arrivée, avec son prompt « Éclore ».
function NestService:Init(cont)
	saveService = cont:Get("SaveService")
	container = cont
end

function NestService:Start()
	local incubationService = container:Get("IncubationService")

	local function PlaceStarterEgg(player: Player)
		task.spawn(function()
			local profile
			for _ = 1, 15 do
				profile = saveService:GetProfile(player)
				if profile then
					break
				end
				task.wait(1)
			end
			if not profile or not player:IsDescendantOf(game) then
				return
			end
			for _, egg in profile.Data.Eggs do
				if egg.Source == "Nest" then
					incubationService:Place(player, egg.Id, egg.Tier)
					break
				end
			end
		end)
	end

	Players.PlayerAdded:Connect(PlaceStarterEgg)
	for _, player in Players:GetPlayers() do
		PlaceStarterEgg(player)
	end
end

return NestService
