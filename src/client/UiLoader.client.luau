local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
require(playerScripts:WaitForChild("Tutorial"))
require(playerScripts:WaitForChild("Ui"))
