local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gameplay = require(ReplicatedStorage.Shared.Gameplay)

-- Pyramide de célébration (bible §4.B) :
-- Épic = burst + son · Légendaire+ = slow-mo · UltraRare+ = plein écran (flash côté Ui) + annonce.
local Celebration = {}

function Celebration.Tier(rank: number): string
	if rank >= Gameplay.RarityRank("UltraRare") then
		return "ultra"
	elseif rank >= Gameplay.RarityRank("Legendary") then
		return "legendary"
	elseif rank >= Gameplay.RarityRank("Epic") then
		return "epic"
	end
	return "none"
end

function Celebration.Hatch(rank: number)
	local tier = Celebration.Tier(rank)
	if tier == "none" then
		return
	end
	local camera = workspace.CurrentCamera
	local pos = camera.CFrame.Position - camera.CFrame.LookVector * 12

	local Fx = require(script.Parent.Fx)
	local Audio = require(script.Parent.Audio)
	Fx.Confetti(pos, Color3.fromRGB(255, 215, 94), if tier == "epic" then 24 else 40)

	if tier == "epic" then
		Audio.Play("RareFanfare")
		return
	end

	-- Légendaire+ : slow-mo cinématique.
	require(script.Parent.Cinematic).Play({ Rarity = nil, Rank = rank })
end

return Celebration
