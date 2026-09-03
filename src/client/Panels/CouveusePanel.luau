--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiKit = require(script.Parent.Parent.UiKit)
local Net = require(ReplicatedStorage.Shared.Net)
local Incubation = require(ReplicatedStorage.Shared.Incubation)

local CouveusePanel = {}

local frame
local selectedEggId: string?
local selectedEggTier: string?
local state
local statusLabel
local eggLabel
local timerLabel
local actionButton
local openPanel: (() -> ())?
local requestInFlight = false

local function FindActive(currentState)
	for _, record in currentState.Incubators or {} do
		return record
	end
	return nil
end

local function FindSelected(currentState)
	for _, egg in currentState.Eggs or {} do
		if egg.Id == selectedEggId then
			return egg
		end
	end
	return nil
end

local function FormatTime(seconds: number): string
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function Render()
	if not state or not statusLabel then
		return
	end
	local active = FindActive(state)
	local selected = FindSelected(state)
	if selectedEggId and not selected and (not active or active.EggId ~= selectedEggId) then
		selectedEggId = nil
		selectedEggTier = nil
	end
	active = FindActive(state)
	selected = FindSelected(state)
	if active then
		selectedEggId = active.EggId
		selectedEggTier = active.EggTier or selectedEggTier
		local incubationState = Incubation.State(active, os.time())
		statusLabel.Text = if incubationState == "Ready" then "État : Prêt" else "État : En incubation"
		statusLabel.TextColor3 = if incubationState == "Ready" then UiKit.TINTS.GREEN else UiKit.TINTS.ACCENT
		eggLabel.Text = `Œuf : {selectedEggTier or active.EggId}`
		timerLabel.Text = if incubationState == "Ready"
			then "Le résultat est prêt à être récupéré."
			else `Temps restant : {FormatTime(active.ReadyAt - os.time())}`
		actionButton.Text = if incubationState == "Ready" then "Récupérer" else "En incubation"
		actionButton.Active = incubationState == "Ready" and not requestInFlight
		actionButton.AutoButtonColor = actionButton.Active
	elseif selected then
		statusLabel.Text = "État : Vide"
		statusLabel.TextColor3 = UiKit.TINTS.WHITE
		eggLabel.Text = `Œuf sélectionné : {selectedEggTier or selected.Tier}`
		timerLabel.Text = "Durée prévue : calculée au lancement"
		actionButton.Text = "Lancer l'incubation"
		actionButton.Active = not requestInFlight
		actionButton.AutoButtonColor = actionButton.Active
	else
		statusLabel.Text = "État : Vide"
		statusLabel.TextColor3 = UiKit.TINTS.WHITE
		eggLabel.Text = "Aucun œuf sélectionné"
		timerLabel.Text = "Sélectionne un œuf dans l'onglet Œufs."
		actionButton.Text = "Lancer l'incubation"
		actionButton.Active = false
		actionButton.AutoButtonColor = false
	end
end

function CouveusePanel.SetOpenCallback(callback: () -> ())
	openPanel = callback
end

function CouveusePanel.SelectEgg(egg)
	if not egg or not egg.Id then
		return
	end
	selectedEggId = egg.Id
	selectedEggTier = egg.Tier
	if openPanel then
		openPanel()
	end
	Render()
end

function CouveusePanel.Create(parent)
	frame = UiKit.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = parent,
	})
	UiKit.Padding(frame, 10)
	UiKit.Title(frame, "Couveuse")

	eggLabel = UiKit.Create("TextLabel", {
		Name = "EggLabel",
		BackgroundTransparency = 1,
		TextColor3 = UiKit.TINTS.WHITE,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0, 0.12),
		Size = UDim2.fromScale(1, 0.12),
		Text = "Aucun œuf sélectionné",
		Parent = frame,
	})
	statusLabel = UiKit.Create("TextLabel", {
		Name = "StatusLabel",
		BackgroundTransparency = 1,
		TextColor3 = UiKit.TINTS.WHITE,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0, 0.27),
		Size = UDim2.fromScale(1, 0.12),
		Text = "État : Vide",
		Parent = frame,
	})
	timerLabel = UiKit.Create("TextLabel", {
		Name = "TimerLabel",
		BackgroundTransparency = 1,
		TextColor3 = UiKit.TINTS.WHITE,
		TextSize = 14,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0, 0.42),
		Size = UDim2.fromScale(1, 0.2),
		Text = "Sélectionne un œuf dans l'onglet Œufs.",
		Parent = frame,
	})
	actionButton = UiKit.Button(frame, "Lancer l'incubation", UDim2.fromScale(0.55, 0.13), UDim2.fromScale(0.225, 0.72))
	actionButton.Name = "IncubationAction"
	actionButton.Activated:Connect(function()
		if requestInFlight then
			return
		end
		local active = state and FindActive(state)
		requestInFlight = true
		if active and Incubation.State(active, os.time()) == "Ready" then
			Net.ClaimIncubation:FireServer(active.IncubatorId)
		elseif selectedEggId and not active then
			Net.StartIncubation:FireServer(selectedEggId)
		else
			requestInFlight = false
		end
		Render()
	end)

	task.spawn(function()
		while frame and frame.Parent do
			Render()
			task.wait(1)
		end
	end)
	return frame
end

function CouveusePanel.Refresh(newState)
	state = newState
	requestInFlight = false
	Render()
end

Net.ActionResult.OnClientEvent:Connect(function(result)
	if result and (result.Action == "StartIncubation" or result.Action == "ClaimIncubation") then
		requestInFlight = false
		Render()
	end
end)

return CouveusePanel
