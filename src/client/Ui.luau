local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UiKit = require(script.Parent.UiKit)
local Audio = require(script.Parent.Audio)
local Net = require(ReplicatedStorage.Shared.Net)
local Species = require(ReplicatedStorage.Shared.Data.Species)

local SanctuaryPanel = require(script.Parent.Panels.SanctuaryPanel)
local EggPanel = require(script.Parent.Panels.EggPanel)
local IndexPanel = require(script.Parent.Panels.IndexPanel)
local BreedingPanel = require(script.Parent.Panels.BreedingPanel)
local RebirthPanel = require(script.Parent.Panels.RebirthPanel)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TINTS = UiKit.TINTS

local TIER_NAMES = {
	CommonEgg = "Œuf commun",
	UncommonEgg = "Œuf peu commun",
	RareEgg = "Œuf rare",
}

local ui = UiKit.Create("ScreenGui", {
	Name = "RiftBeastsUi",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	Parent = playerGui,
})

local topBar = UiKit.Create("Frame", {
	BackgroundColor3 = TINTS.PANEL,
	Size = UDim2.fromOffset(300, 64),
	Position = UDim2.fromOffset(12, 12),
	Parent = ui,
})
UiKit.Corner(topBar)
UiKit.Padding(topBar, 12)

local essenceLabel = UiKit.Create("TextLabel", {
	BackgroundTransparency = 1,
	TextColor3 = TINTS.ACCENT,
	Font = Enum.Font.GothamBold,
	TextSize = 24,
	TextXAlignment = Enum.TextXAlignment.Left,
	Size = UDim2.fromScale(1, 0.55),
	Text = "Essence : 0",
	Parent = topBar,
})

local rateLabel = UiKit.Create("TextLabel", {
	BackgroundTransparency = 1,
	TextColor3 = TINTS.WHITE,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0, 0.55),
	Size = UDim2.fromScale(1, 0.45),
	Text = "Rendement : 0 / s",
	Parent = topBar,
})

local content = UiKit.Create("Frame", {
	BackgroundColor3 = TINTS.PANEL,
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.fromScale(0.72, 0.72),
	Visible = false,
	Parent = ui,
})
UiKit.Corner(content)
UiKit.Padding(content, 12)

local tabBar = UiKit.Create("Frame", {
	BackgroundColor3 = TINTS.DARK,
	Size = UDim2.fromScale(0.1, 1),
	Parent = content,
})
UiKit.Corner(tabBar)
UiKit.Padding(tabBar, 6)
UiKit.Create("UIListLayout", {
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = tabBar,
})

local panelsFrame = UiKit.Create("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.fromScale(0.11, 0),
	Size = UDim2.fromScale(0.89, 1),
	Parent = content,
})

local panels = {}
local function AddTab(name: string, panelModule: any)
	local button = UiKit.Create("TextButton", {
		BackgroundColor3 = TINTS.PANEL,
		TextColor3 = TINTS.WHITE,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		Size = UDim2.fromScale(1, 0.09),
		Text = name,
		Parent = tabBar,
	})
	UiKit.Corner(button)

	local frame = panelModule.Create(panelsFrame)
	frame.Visible = false

	button.Activated:Connect(function()
		for _, panel in panels do
			panel.frame.Visible = false
		end
		frame.Visible = true
	end)

	table.insert(panels, { module = panelModule, frame = frame })
end

AddTab("Sanctuaire", SanctuaryPanel)
AddTab("Œufs", EggPanel)
AddTab("Index", IndexPanel)
AddTab("Élevage", BreedingPanel)
AddTab("Renaissance", RebirthPanel)

if panels[1] then
	panels[1].frame.Visible = true
end

local menuButton = UiKit.Create("TextButton", {
	BackgroundColor3 = TINTS.ACCENT,
	TextColor3 = TINTS.WHITE,
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	Size = UDim2.fromOffset(140, 40),
	Position = UDim2.fromOffset(324, 12),
	Text = "Menu",
	Parent = ui,
})
UiKit.Corner(menuButton)

local function SetMenuOpen(open: boolean)
	content.Visible = open
	menuButton.Text = if open then "Fermer" else "Menu"
end

menuButton.Activated:Connect(function()
	SetMenuOpen(not content.Visible)
end)

SetMenuOpen(false)

local riftHud = UiKit.Create("Frame", {
	BackgroundColor3 = TINTS.PANEL,
	Size = UDim2.fromOffset(420, 190),
	Position = UDim2.fromScale(0.5, 1),
	AnchorPoint = Vector2.new(0.5, 1),
	Visible = false,
	Parent = ui,
})
UiKit.Corner(riftHud)
UiKit.Padding(riftHud, 12)

UiKit.Create("TextLabel", {
	BackgroundTransparency = 1,
	TextColor3 = TINTS.ACCENT,
	Font = Enum.Font.GothamBold,
	TextSize = 20,
	Size = UDim2.fromScale(1, 0.16),
	Text = "Faille",
	Parent = riftHud,
})

local guardianLabel, guardianFill = UiKit.Bar(riftHud, TINTS.RED)
guardianLabel.Position = UDim2.fromScale(0, 0.2)
guardianLabel.Size = UDim2.fromScale(1, 0.12)

local playerHpLabel, playerHpFill = UiKit.Bar(riftHud, TINTS.GREEN)
playerHpLabel.Position = UDim2.fromScale(0, 0.36)
playerHpLabel.Size = UDim2.fromScale(1, 0.12)

local attackButton = UiKit.Create("TextButton", {
	BackgroundColor3 = TINTS.ACCENT,
	TextColor3 = TINTS.WHITE,
	Font = Enum.Font.GothamBold,
	TextSize = 18,
	Size = UDim2.fromScale(1, 0.2),
	Position = UDim2.fromScale(0, 0.55),
	Text = "Attaquer",
	Parent = riftHud,
})
UiKit.Corner(attackButton)

local riftHint = UiKit.Create("TextLabel", {
	BackgroundTransparency = 1,
	TextColor3 = TINTS.WHITE,
	TextSize = 14,
	Position = UDim2.fromScale(0, 0.78),
	Size = UDim2.fromScale(1, 0.2),
	Text = "",
	Parent = riftHud,
})

local announcement = UiKit.Create("Frame", {
	BackgroundColor3 = TINTS.PANEL,
	Size = UDim2.fromOffset(520, 56),
	Position = UDim2.fromScale(0.5, 0.06),
	AnchorPoint = Vector2.new(0.5, 0),
	Visible = false,
	ZIndex = 10,
	Parent = ui,
})
UiKit.Corner(announcement)

local announcementLabel = UiKit.Create("TextLabel", {
	BackgroundTransparency = 1,
	TextColor3 = TINTS.WHITE,
	Font = Enum.Font.GothamBold,
	TextSize = 18,
	Size = UDim2.fromScale(1, 1),
	Text = "",
	ZIndex = 10,
	Parent = announcement,
})

local flashOverlay = UiKit.Create("Frame", {
	BackgroundColor3 = TINTS.WHITE,
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	ZIndex = 100,
	Parent = ui,
})

local reveal = UiKit.Create("Frame", {
	BackgroundColor3 = TINTS.PANEL,
	Size = UDim2.fromOffset(420, 150),
	Position = UDim2.fromScale(0.5, 0.4),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Visible = false,
	ZIndex = 20,
	Parent = ui,
})
UiKit.Corner(reveal)

local revealLabel = UiKit.Create("TextLabel", {
	BackgroundTransparency = 1,
	TextColor3 = TINTS.WHITE,
	Font = Enum.Font.GothamBold,
	TextSize = 20,
	Size = UDim2.fromScale(1, 0.7),
	Text = "",
	TextWrapped = true,
	ZIndex = 20,
	Parent = reveal,
})

local revealButton = UiKit.Create("TextButton", {
	BackgroundColor3 = TINTS.ACCENT,
	TextColor3 = TINTS.WHITE,
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	Size = UDim2.fromOffset(120, 36),
	Position = UDim2.fromScale(0.5, 0.75),
	AnchorPoint = Vector2.new(0.5, 0),
	Text = "Continuer",
	ZIndex = 20,
	Parent = reveal,
})
UiKit.Corner(revealButton)

local riftStatusLabel = UiKit.Create("TextLabel", {
	BackgroundColor3 = TINTS.PANEL,
	BackgroundTransparency = 0.2,
	TextColor3 = TINTS.ACCENT,
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	Size = UDim2.fromOffset(240, 36),
	Position = UDim2.fromScale(0.5, 0.16),
	AnchorPoint = Vector2.new(0.5, 0),
	Visible = false,
	ZIndex = 10,
	Text = "",
	Parent = ui,
})
UiKit.Corner(riftStatusLabel)

local announceTween
local function ShowAnnouncement(text: string)
	announcementLabel.Text = text
	announcement.Visible = true
	announcement.BackgroundTransparency = 0.1
	if announceTween then
		announceTween:Cancel()
	end
	announceTween = TweenService:Create(announcement, TweenInfo.new(0.4), {
		BackgroundTransparency = 0.1,
	})
	announceTween:Play()
	task.delay(5, function()
		local fade = TweenService:Create(announcement, TweenInfo.new(0.4), {
			BackgroundTransparency = 1,
		})
		fade.Completed:Connect(function()
			announcement.Visible = false
		end)
		fade:Play()
	end)
end

local function Flash(intensity: number)
	flashOverlay.BackgroundTransparency = 1 - intensity
	flashOverlay.Visible = true
	TweenService:Create(flashOverlay, TweenInfo.new(0.25), {
		BackgroundTransparency = 1,
	}):Play()
	task.delay(0.5, function()
		flashOverlay.Visible = false
	end)
end

local function ShowRiftSync(state)
	if not state.InRift then
		riftHud.Visible = false
		return
	end
	riftHud.Visible = true
	UiKit.SetBar(guardianFill, guardianLabel, state.GuardianHP, state.GuardianMaxHP)
	UiKit.SetBar(playerHpFill, playerHpLabel, state.PlayerHP, state.PlayerMaxHP)
	if state.Phase == "Crystal" then
		attackButton.Visible = false
		riftHint.Text = "Touche le cristal pour récupérer les récompenses !"
	else
		attackButton.Visible = true
		riftHint.Text = ""
	end
end

local function ShowRiftEnded(result)
	riftHud.Visible = false
	if result.Win then
		Audio.Play("CoinReward")
		local relicText = result.RelicTier and `\nRelique T{result.RelicTier} obtenue !` or ""
		ShowAnnouncement(
			`Faille terminée : +{result.Essence} Essence et {TIER_NAMES[result.EggTier] or result.EggTier}{relicText}`
		)
		Flash(0.35)
	else
		ShowAnnouncement("Défaite face au gardien. Tes créatures n'étaient pas prêtes.")
	end
end

attackButton.Activated:Connect(function()
	Audio.Play("RiftWhoosh", 0.3)
	Net.RiftAttack:FireServer()
end)

revealButton.Activated:Connect(function()
	reveal.Visible = false
end)

local state = nil

local function RefreshAll(newState)
	state = newState
	essenceLabel.Text = `Essence : {state.Essence}`
	rateLabel.Text = `Rendement : {string.format("%.1f", state.Rate)} / s`
	if state.Stars > 0 then
		rateLabel.Text ..= ` — ★{state.Stars}`
	end
	for _, panel in panels do
		if panel.module.Refresh then
			panel.module.Refresh(state)
		end
	end
end

Net.Sync.OnClientEvent:Connect(RefreshAll)

Net.HatchResult.OnClientEvent:Connect(function(result)
	Audio.Play("HatchCrack")
	if result.Announced then
		Audio.Play("RareFanfare")
	end
	local mutationText = result.MutationName and ` {result.MutationName}` or ""
	revealLabel.Text = `Tu as obtenu {result.SpeciesName} !\n{result.RarityName}{mutationText}`
	revealLabel.TextColor3 = result.RarityColor
	reveal.Visible = true
	if result.Announced then
		Flash(0.7)
	end
end)

Net.BreedResult.OnClientEvent:Connect(function(result)
	local species = Species[result.Creature.SpeciesId]
	local name = species and species.Name or result.Creature.SpeciesId
	revealLabel.Text = `Élevage réussi !\n{name} — Génération {result.Creature.Generation}`
	revealLabel.TextColor3 = TINTS.ACCENT
	reveal.Visible = true
end)

Net.RareDrop.OnClientEvent:Connect(function(payload)
	local mutationText = payload.MutationName and ` {payload.MutationName}` or ""
	ShowAnnouncement(`{payload.PlayerName} a obtenu {payload.SpeciesName} ({payload.RarityName}{mutationText}) !`)
end)

Net.RiftSync.OnClientEvent:Connect(ShowRiftSync)

Net.RiftEnded.OnClientEvent:Connect(ShowRiftEnded)

Net.RiftWorld.OnClientEvent:Connect(function(world)
	if world.Active then
		Audio.Play("RiftWhoosh")
		riftStatusLabel.Text = "Une faille s'est ouverte ! Entre dans le portail."
		riftStatusLabel.Visible = true
	else
		riftStatusLabel.Visible = false
	end
end)

require(script.Parent.CreatureDisplay)

return nil
