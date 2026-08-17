local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiKit = require(script.Parent.Parent.UiKit)
local Net = require(ReplicatedStorage.Shared.Net)
local Rebirth = require(ReplicatedStorage.Shared.Rebirth)

local RebirthPanel = {}

local progressLabel
local previewLabel
local confirmButton

local function RenderProgress(state)
	local threshold = Rebirth.NextThreshold(state.Stars)
	if not threshold then
		progressLabel.Text = "Toutes les renaissances sont atteintes."
		return
	end
	local earned = state.Stats.TotalEssenceEarned
	progressLabel.Text =
		`Essence gagnée : {math.floor(earned)} / {threshold} — Renaissance {state.Stars + 1} débloquée à {threshold}`
end

function RebirthPanel.Create(parent)
	local frame = UiKit.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = parent,
	})
	UiKit.Padding(frame, 10)

	UiKit.Title(frame, "Renaissance")

	progressLabel = UiKit.Create("TextLabel", {
		Name = "ProgressLabel",
		BackgroundTransparency = 1,
		TextColor3 = UiKit.TINTS.WHITE,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.fromScale(1, 0.08),
		Text = "",
		TextWrapped = true,
		Parent = frame,
	})

	local requestButton = UiKit.Button(frame, "Calculer l'aperçu", UDim2.fromScale(0.3, 0.08), UDim2.fromScale(0, 0.1))
	requestButton.Name = "RequestButton"
	requestButton.Activated:Connect(function()
		Net.RebirthRequest:FireServer()
	end)

	previewLabel = UiKit.Create("TextLabel", {
		Name = "PreviewLabel",
		BackgroundTransparency = 1,
		TextColor3 = UiKit.TINTS.ACCENT,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0, 0.2),
		Size = UDim2.fromScale(1, 0.4),
		Text = "Perdu : œufs, Essence, niveau du sanctuaire.\nConservé : créature la plus forte, Index, Reliques légendaires.",
		TextWrapped = true,
		Parent = frame,
	})

	confirmButton = UiKit.Button(frame, "Renaître", UDim2.fromScale(0.3, 0.08), UDim2.fromScale(0, 0.62))
	confirmButton.Name = "ConfirmButton"
	confirmButton.Visible = false
	confirmButton.Activated:Connect(function()
		Net.RebirthConfirm:FireServer()
	end)

	return frame
end

function RebirthPanel.Refresh(state)
	RenderProgress(state)
end

Net.RebirthPreview.OnClientEvent:Connect(function(preview)
	if preview.CanRebirth then
		previewLabel.Text =
			`Renaissance disponible !\nÉtoiles : {preview.CurrentStars} → {preview.NextStars}\nMultiplicateur : ×{preview.NextMult}\nCréature la plus forte conservée\nReliques légendaires conservées : {preview.KeptRelics}`
		confirmButton.Visible = true
	else
		previewLabel.Text = `Renaissance indisponible : {preview.Reason}`
		confirmButton.Visible = false
	end
end)

return RebirthPanel
