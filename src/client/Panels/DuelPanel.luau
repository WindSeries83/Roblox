local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiKit = require(script.Parent.Parent.UiKit)
local Audio = require(script.Parent.Parent.Audio)
local Net = require(ReplicatedStorage.Shared.Net)
local Config = require(ReplicatedStorage.Shared.Config)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)

local DuelPanel = {}

local TINTS = UiKit.TINTS

local myPlayer = Players.LocalPlayer

local targetPage
local teamPage
local wagerBox
local selectedTarget = nil
local selectedTeam = {}
local challengeStatus

local incoming = nil
local incomingFrame
local incomingLabel

local function ResetSelection()
	selectedTarget = nil
	selectedTeam = {}
end

local function RebuildTargets(state)
	UiKit.Clear(targetPage)
	for _, player in Players:GetPlayers() do
		if player ~= myPlayer and player:FindFirstChildOfClass("Humanoid") then
			local cell = UiKit.Cell(targetPage)
			UiKit.Create("TextLabel", {
				BackgroundTransparency = 1,
				TextColor3 = TINTS.WHITE,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Size = UDim2.fromScale(0.62, 1),
				Text = player.Name,
				Parent = cell,
			})
			local button = UiKit.Button(cell, "Défier", UDim2.new(0.3, 0, 0, 28), UDim2.new(0.68, 0, 0.5, -14))
			if player.Name == selectedTarget then
				button.BackgroundColor3 = TINTS.GREEN
			end
			button.Activated:Connect(function()
				selectedTarget = player.Name
				RebuildTargets(state)
			end)
		end
	end
	if selectedTarget then
		UiKit.Title(targetPage, `Cible : {selectedTarget}`)
	end
end

local function RebuildTeam(state)
	UiKit.Clear(teamPage)
	UiKit.Title(teamPage, `Choisis ton équipe ({#selectedTeam}/{Config.DUEL_MAX_TEAM})`)
	for _, creature in state.Creatures or {} do
		local cell = UiKit.Cell(teamPage)
		UiKit.Create("TextLabel", {
			BackgroundTransparency = 1,
			TextColor3 = TINTS.WHITE,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.fromScale(0.62, 1),
			Text = `[{string.upper(creature.Rarity)}] {Gameplay.SpeciesName(creature.SpeciesId)} — Niv. {creature.Level} — {creature.Power}`,
			TextWrapped = true,
			Parent = cell,
		})
		local inTeam = selectedTeam[creature.Id] == true
		local button = UiKit.Button(
			cell,
			if inTeam then "Retirer" else "Choisir",
			UDim2.new(0.3, 0, 0, 28),
			UDim2.new(0.68, 0, 0.5, -14)
		)
		if inTeam then
			button.BackgroundColor3 = TINTS.GREEN
		end
		button.Activated:Connect(function()
			if inTeam then
				selectedTeam[creature.Id] = nil
			elseif #selectedTeam < Config.DUEL_MAX_TEAM then
				selectedTeam[creature.Id] = true
			end
			RebuildTeam(state)
		end)
	end
end

function DuelPanel.Create(parent: Instance): Frame
	local panel = UiKit.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = parent,
	})
	UiKit.Padding(panel, 10)

	local header = UiKit.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 44),
		Parent = panel,
	})
	challengeStatus = UiKit.Create("TextLabel", {
		BackgroundTransparency = 1,
		TextColor3 = TINTS.WHITE,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Size = UDim2.fromScale(0.55, 1),
		Text = "",
		Parent = header,
	})
	wagerBox = UiKit.Create("TextBox", {
		BackgroundColor3 = TINTS.DARK,
		TextColor3 = TINTS.WHITE,
		PlaceholderColor3 = Color3.fromRGB(150, 150, 160),
		Font = Enum.Font.Gotham,
		TextSize = 14,
		Text = "",
		PlaceholderText = `Mise (min {Config.DUEL_MIN_WAGER})`,
		Size = UDim2.new(0.28, 0, 0, 30),
		Position = UDim2.new(0.02, 0, 0.5, -15),
		Parent = header,
	})
	UiKit.Corner(wagerBox)
	local challengeButton =
		UiKit.Button(header, "Lancer le défi", UDim2.new(0.3, 0, 0, 30), UDim2.new(0.68, 0, 0.5, -15))
	challengeButton.Name = "ChallengeButton"
	challengeButton.Activated:Connect(function()
		if not selectedTarget then
			challengeStatus.Text = "Choisis un adversaire."
			challengeStatus.TextColor3 = TINTS.RED
			return
		end
		local teamIds = {}
		for id in selectedTeam do
			table.insert(teamIds, id)
		end
		if #teamIds == 0 then
			challengeStatus.Text = "Choisis au moins une créature."
			challengeStatus.TextColor3 = TINTS.RED
			return
		end
		local wager = tonumber(wagerBox.Text)
		if not wager or wager < Config.DUEL_MIN_WAGER or wager > Config.DUEL_MAX_WAGER then
			challengeStatus.Text = `Mise invalide ({Config.DUEL_MIN_WAGER}-{Config.DUEL_MAX_WAGER})`
			challengeStatus.TextColor3 = TINTS.RED
			return
		end
		Audio.Play("CoinReward")
		Net.DuelChallenge:FireServer(selectedTarget, wager, teamIds)
		challengeStatus.Text = `Défi envoyé à {selectedTarget}…`
		challengeStatus.TextColor3 = TINTS.GREEN
		ResetSelection()
		RebuildTargets(DuelPanel.lastState)
		RebuildTeam(DuelPanel.lastState)
	end)

	targetPage = UiKit.Scroller(panel, UDim2.fromOffset(0, 50), UDim2.new(0.5, 0, 1, -56))
	targetPage.Name = "TargetPage"
	teamPage = UiKit.Scroller(panel, UDim2.new(0.52, 0, 0, 50), UDim2.new(0.48, 0, 1, -56))
	teamPage.Name = "TeamPage"
	UiKit.Title(targetPage, "Adversaires en ligne")
	UiKit.Title(teamPage, "Ton équipe")

	incomingFrame = UiKit.Create("Frame", {
		Name = "IncomingDuel",
		BackgroundColor3 = TINTS.PANEL,
		Size = UDim2.fromOffset(320, 140),
		Position = UDim2.fromScale(0.5, 0.4),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Visible = false,
		ZIndex = 30,
		Parent = panel,
	})
	UiKit.Corner(incomingFrame)
	UiKit.Padding(incomingFrame, 12)
	incomingLabel = UiKit.Create("TextLabel", {
		BackgroundTransparency = 1,
		TextColor3 = TINTS.WHITE,
		TextSize = 14,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 0.5),
		Text = "",
		Parent = incomingFrame,
	})
	local acceptButton = UiKit.Button(incomingFrame, "Accepter", UDim2.new(0.45, 0, 0, 32), UDim2.fromScale(0.02, 0.6))
	acceptButton.BackgroundColor3 = TINTS.GREEN
	acceptButton.Activated:Connect(function()
		if incoming then
			Audio.Play("CoinReward")
			Net.DuelAccept:FireServer(incoming.Id)
			incoming = nil
			incomingFrame.Visible = false
		end
	end)
	local declineButton = UiKit.Button(incomingFrame, "Refuser", UDim2.new(0.45, 0, 0, 32), UDim2.fromScale(0.53, 0.6))
	declineButton.BackgroundColor3 = TINTS.DARK
	declineButton.Activated:Connect(function()
		if incoming then
			Audio.Play("UiClick")
			Net.DuelDecline:FireServer(incoming.Id)
			incoming = nil
			incomingFrame.Visible = false
		end
	end)

	Net.DuelRequest.OnClientEvent:Connect(function(payload)
		incoming = payload
		incomingLabel.Text =
			`{payload.ChallengerName} te défie !\nMise : {payload.Wager} Essence\nPuissance : {payload.AttackPower}`
		incomingFrame.Visible = true
		Audio.Play("UiClick")
	end)

	Net.DuelResult.OnClientEvent:Connect(function(payload)
		incomingFrame.Visible = false
		if payload.Reason == "declined" then
			challengeStatus.Text = `${payload.OpponentName} a refusé ton défi. Mise remboursée.`
			challengeStatus.TextColor3 = TINTS.WHITE
			return
		end
		local outcome = if payload.Won
			then `Victoire ! Tu remportes {payload.Wager * 2} Essence`
			else `Défaite face à {payload.OpponentName} ({payload.Wager} Essence perdues)`
		challengeStatus.Text = `${outcome} — {payload.AttackPower} vs {payload.DefensePower}`
		challengeStatus.TextColor3 = if payload.Won then TINTS.GREEN else TINTS.RED
		Audio.Play(if payload.Won then "RareFanfare" else "UiClick")
	end)

	return panel
end

function DuelPanel.Refresh(state)
	DuelPanel.lastState = state
	RebuildTargets(state)
	RebuildTeam(state)
end

return DuelPanel
