local Players = game:GetService("Players")
local StarterPlayerScripts = game:GetService("StarterPlayer").StarterPlayerScripts

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if not playerGui:FindFirstChild("RiftBeastsUi") then
	require(StarterPlayerScripts:WaitForChild("Tutorial"))
	require(StarterPlayerScripts:WaitForChild("WorldUi"))
	require(StarterPlayerScripts:WaitForChild("Ui"))
end
