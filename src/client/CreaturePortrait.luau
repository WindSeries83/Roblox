local RunService = game:GetService("RunService")

-- Portrait vivant : ViewportFrame qui fait tourner lentement le modèle 3D
-- de l'espèce, teinté rareté/mutation. Réutilisable partout où on affiche
-- un nom de créature (index, révélation d'éclosion, HUD).
local CreaturePortrait = {}

local live: { any } = {}

RunService.Heartbeat:Connect(function(t)
	for _, state in live do
		if state.model and state.vp.Parent then
			state.angle = t * 0.9
			state.model:PivotTo(CFrame.Angles(0, state.angle, 0))
		end
	end
end)

function CreaturePortrait.Create(parent: Instance, position: UDim2, size: UDim2)
	local vp = Instance.new("ViewportFrame")
	vp.Name = "Portrait"
	vp.BackgroundColor3 = Color3.fromRGB(15, 12, 24)
	vp.BackgroundTransparency = 0.2
	vp.Ambient = Color3.fromRGB(150, 150, 175)
	vp.LightColor = Color3.fromRGB(255, 250, 235)
	vp.LightDirection = Vector3.new(-0.6, -1, -0.4)
	vp.Position = position
	vp.Size = size
	vp.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = vp

	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	camera.CFrame = CFrame.new(Vector3.new(0, 0.7, 7.5), Vector3.new(0, 0, 0))
	camera.Parent = vp
	vp.CurrentCamera = camera

	local world = Instance.new("WorldModel")
	world.Parent = vp

	local state = { vp = vp, world = world, camera = camera, model = nil, angle = math.random() * 6 }
	table.insert(live, state)
	vp.Destroying:Connect(function()
		for i, s in live do
			if s == state then
				table.remove(live, i)
				break
			end
		end
	end)
	return state
end

function CreaturePortrait.Show(
	_state: any,
	_speciesId: string?,
	_rarity: string?,
	_mutation: any,
	_silhouette: boolean?
)
	-- ponytail: portraits 3D retirés (assets provisoires jugés moches).
	-- Restaurer l'ancien corps de Show (git log) quand la vraie DA arrive.
	if _state and _state.model then
		_state.model:Destroy()
		_state.model = nil
	end
	if _state and _state.vp then
		_state.vp.BackgroundTransparency = 1
	end
end

return CreaturePortrait
