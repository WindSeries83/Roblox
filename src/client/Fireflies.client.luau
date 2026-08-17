local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local folder = Instance.new("Folder")
folder.Name = "Fireflies"
folder.Parent = Workspace

local fireflies = {}
for i = 1, 20 do
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(0.16, 0.16, 0.16)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(255, 214, 120)
	part.Transparency = 0.35
	part.Parent = folder

	local angle = math.random() * math.pi * 2
	local radius = 14 + math.random() * 44
	fireflies[i] = {
		part = part,
		base = Vector3.new(math.cos(angle) * radius, 9 + math.random() * 5, math.sin(angle) * radius),
		speed = 0.4 + math.random() * 0.7,
		phase = math.random() * math.pi * 2,
	}
end

RunService.RenderStepped:Connect(function(t)
	for _, f in fireflies do
		local x = f.base.X + math.sin(t * f.speed + f.phase) * 6
		local z = f.base.Z + math.cos(t * f.speed * 0.8 + f.phase) * 6
		local y = f.base.Y + math.sin(t * f.speed * 1.5 + f.phase) * 1.6
		f.part.Position = Vector3.new(x, y, z)
	end
end)

return nil
