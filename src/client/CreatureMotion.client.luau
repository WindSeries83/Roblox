local RunService = game:GetService("RunService")

-- ponytail: retry car un require qui échoue (sync rojo partielle au boot)
-- reste en cache erreur pour toujours
local CreatureDisplay
for _ = 1, 20 do
	local ok, result = pcall(function()
		return require(script.Parent:WaitForChild("CreatureDisplay"))
	end)
	if ok then
		CreatureDisplay = result
		break
	end
	task.wait(0.5)
end
if not CreatureDisplay then
	return
end

local function KindOf(name: string): string?
	local n = string.lower(name)
	if string.find(n, "wing", 1, true) then
		return "flap"
	end
	if string.find(n, "tail", 1, true) then
		return "wag"
	end
	if string.find(n, "fin", 1, true) then
		return "sway"
	end
	if string.find(n, "head", 1, true) then
		return "nod"
	end
	return nil
end

local tracked: { [Model]: { { Part: BasePart, Rel: CFrame, Kind: string, Phase: number } } } = {}

local function Track(model: Model)
	local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not primary then
		return nil
	end
	local entries = {}
	local phase = 0
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part ~= primary then
			local kind = KindOf(part.Name)
			if kind then
				table.insert(entries, {
					Part = part,
					Rel = primary.CFrame:ToObjectSpace(part.CFrame),
					Kind = kind,
					Phase = phase,
				})
				phase += 1.7
			end
		end
	end
	if #entries == 0 then
		return nil
	end
	tracked[model] = entries
	return entries
end

RunService.RenderStepped:Connect(function(t)
	for _, model in CreatureDisplay.Models() do
		if not model.Parent then
			tracked[model] = nil
			continue
		end
		local entries = tracked[model] or Track(model)
		if not entries then
			-- Aucune part nommée : FollowController animera le modèle entier en hop.
			model:SetAttribute("HopFallback", true)
			continue
		end
		local primary = model.PrimaryPart
		if not primary then
			continue
		end
		for _, e in entries do
			local angle = 0
			if e.Kind == "flap" then
				angle = math.sin(t * 5 + e.Phase) * 0.45
			elseif e.Kind == "wag" then
				angle = math.sin(t * 2.5 + e.Phase) * 0.3
			elseif e.Kind == "sway" then
				angle = math.sin(t * 3 + e.Phase) * 0.2
			elseif e.Kind == "nod" then
				angle = math.sin(t * 1.8 + e.Phase) * 0.08
			end
			e.Part.CFrame = primary.CFrame * e.Rel * CFrame.Angles(0, 0, angle)
		end
	end
end)
