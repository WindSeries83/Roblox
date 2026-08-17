local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local function LookAtSpawn()
	local spawn = Workspace:FindFirstChild("SpawnLocation")
	local camera = Workspace.CurrentCamera
	if not spawn or not camera then
		return
	end
	local pos = spawn.Position
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(pos + Vector3.new(9, 5, 9), pos)
	task.delay(1.2, function()
		camera.CameraType = Enum.CameraType.Custom
	end)
end

player.CharacterAdded:Connect(function(character)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if root then
		task.wait(0.3)
		LookAtSpawn()
	end
end)

if player.Character then
	task.wait(0.3)
	LookAtSpawn()
end

return nil
