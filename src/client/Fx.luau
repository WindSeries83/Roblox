local Fx = {}

function Fx.Burst(part: BasePart, color: Color3, count: number?)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Lifetime = NumberRange.new(0.4, 0.8)
	emitter.Speed = NumberRange.new(4, 10)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate = 0
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 0.6
	emitter.Size = NumberSequence.new(0.4)
	emitter.Transparency = NumberSequence.new(0.4)
	emitter.ZOffset = 0.5
	emitter.Parent = part

	for _ = 1, count or 24 do
		emitter:Emit(1)
	end
	task.delay(1.2, function()
		emitter:Destroy()
	end)
end

function Fx.Confetti(position: Vector3, color: Color3, count: number?)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.new(0.1, 0.1, 0.1)
	part.CFrame = CFrame.new(position)
	part.Parent = game:GetService("Workspace")

	local emitter = Instance.new("ParticleEmitter")
	emitter.Lifetime = NumberRange.new(0.6, 1.2)
	emitter.Speed = NumberRange.new(3, 8)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate = 0
	emitter.Color = ColorSequence.new(color)
	emitter.Size = NumberSequence.new(0.5)
	emitter.Transparency = NumberSequence.new(0.2)
	emitter.Acceleration = Vector3.new(0, -10, 0)
	emitter.LightEmission = 0.4
	emitter.Parent = part

	for _ = 1, count or 16 do
		emitter:Emit(1)
	end
	task.delay(2, function()
		emitter:Destroy()
		part:Destroy()
	end)
end

return Fx
