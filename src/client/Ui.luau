local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UiKit = require(script.Parent.UiKit)
local Audio = require(script.Parent.Audio)
local Net = require(ReplicatedStorage.Shared.Net)
local Species = require(ReplicatedStorage.Shared.Data.Species)
local Config = require(ReplicatedStorage.Shared.Config)

local SanctuaryPanel = require(script.Parent.Panels.SanctuaryPanel)
local EggPanel = require(script.Parent.Panels.EggPanel)
local IndexPanel = require(script.Parent.Panels.IndexPanel)
local BreedingPanel = require(script.Parent.Panels.BreedingPanel)
local RebirthPanel = require(script.Parent.Panels.RebirthPanel)
local QuestsPanel = require(script.Parent.Panels.QuestsPanel)
local TutorialBridge = require(ReplicatedStorage.Shared.TutorialBridge)
local Fx = require(script.Parent.Fx)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
task.spawn(function()
	for _ = 1, 10 do
		local chat = playerGui:FindFirstChild("Chat")
		if chat then
			chat:Destroy()
		end
		task.wait(0.5)
	end
end)

local TINTS = UiKit.TINTS

local viewportWidth = pcall(function()
	return workspace.CurrentCamera.ViewportSize.X
end) and workspace.CurrentCamera.ViewportSize.X or 800
local compact = viewportWidth < 700

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
	Name = "TopBar",
	BackgroundColor3 = TINTS.PANEL,
	Size = UDim2.fromOffset(if compact then 230 else 300, if compact then 56 else 64),
	Position = UDim2.fromOffset(12, 12),
	Parent = ui,
})
UiKit.Corner(topBar)
UiKit.Padding(topBar, 12)

local essenceLabel = UiKit.Create("TextLabel", {
	Name = "EssenceLabel",
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
	Name = "RateLabel",
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
	Name = "Content",
	BackgroundColor3 = TINTS.PANEL,
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.fromScale(if compact then 0.96 else 0.72, if compact then 0.96 else 0.72),
	Visible = false,
	Parent = ui,
})
UiKit.Corner(content)
UiKit.Padding(content, 12)

local tabBar = UiKit.Create("Frame", {
	Name = "TabBar",
	BackgroundColor3 = TINTS.DARK,
	Size = UDim2.fromScale(0.1, 1),
	Parent = content,
})
UiKit.Corner(tabBar)
UiKit.Padding(tabBar, 6)

local panelsFrame = UiKit.Create("Frame", {
	Name = "PanelsFrame",
	BackgroundTransparency = 1,
	Position = UDim2.fromScale(0.11, 0),
	Size = UDim2.fromScale(0.89, 1),
	Parent = content,
})

local panels = {}
local tabCount = 0
local function AddTab(name: string, panelModule: any)
	tabCount += 1
	local button = UiKit.Create("TextButton", {
		Name = `Tab{tabCount}`,
		BackgroundColor3 = TINTS.PANEL,
		TextColor3 = TINTS.WHITE,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		Size = UDim2.fromOffset(112, 60),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(6, 6 + (tabCount - 1) * 12),
		Text = name,
		Parent = tabBar,
	})
	UiKit.Corner(button)

	local frame = panelModule.Create(panelsFrame)
	frame.Name = `Panel{tabCount}`
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
AddTab("Objectifs", QuestsPanel)

local lastTabLayoutHeight = 0
local function LayoutTabs()
	local height = tabBar.AbsoluteSize.Y
	if math.abs(height - lastTabLayoutHeight) <= 1 then
		return
	end
	lastTabLayoutHeight = height
	local tabHeight = 0.09 * math.max(0, height - 12)
	local tabWidth = math.max(0, tabBar.AbsoluteSize.X - 12)
	local i = 0
	for _, tab in tabBar:GetChildren() do
		if tab:IsA("TextButton") then
			i += 1
			tab.Size = UDim2.fromOffset(tabWidth, tabHeight)
			tab.Position = UDim2.fromOffset(6 + tabWidth / 2, 6 + (i - 1) * (tabHeight + 6) + tabHeight / 2)
		end
	end
end
task.spawn(function()
	while tabBar.Parent do
		LayoutTabs()
		task.wait(0.5)
	end
end)

if panels[1] then
	panels[1].frame.Visible = true
end

local questBadge = UiKit.Create("TextLabel", {
	Name = "QuestBadge",
	BackgroundColor3 = TINTS.GREEN,
	BackgroundTransparency = 0.1,
	TextColor3 = TINTS.DARK,
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	Size = UDim2.fromOffset(24, 24),
	Position = UDim2.new(1, -6, 0, -6),
	AnchorPoint = Vector2.new(1, 0),
	ZIndex = 5,
	Text = "",
	Parent = topBar,
})
UiKit.Corner(questBadge)

local function UpdateQuestBadge(quests)
	local ready = 0
	if quests and quests.Daily then
		for _, quest in quests.Daily do
			local def = Config and Config.DAILY_QUESTS[quest.Id]
			if def and not quest.Claimed and quest.Progress >= def.Target then
				ready += 1
			end
		end
	end
	questBadge.Text = if ready > 0 then `{ready}` else ""
	questBadge.Visible = ready > 0
end

local menuButton = UiKit.Create("TextButton", {
	Name = "MenuButton",
	BackgroundColor3 = TINTS.ACCENT,
	TextColor3 = TINTS.WHITE,
	Font = Enum.Font.GothamBold,
	TextSize = if compact then 14 else 16,
	Size = UDim2.fromOffset(if compact then 110 else 140, if compact then 40 else 40),
	Position = UDim2.fromOffset(if compact then 254 else 324, 12),
	Text = "Menu",
	Parent = ui,
})
UiKit.Corner(menuButton)

local function SetMenuOpen(open: boolean)
	content.Visible = open
	menuButton.Text = if open then "Fermer" else "Menu"
	TutorialBridge.Set("MenuOpen", open)
end

menuButton.Activated:Connect(function()
	SetMenuOpen(not content.Visible)
end)

SetMenuOpen(false)

local riftHud = UiKit.Create("Frame", {
	Name = "RiftHud",
	BackgroundColor3 = TINTS.PANEL,
	Size = UDim2.fromOffset(if compact then 330 else 420, if compact then 170 else 190),
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
	Name = "Announcement",
	BackgroundColor3 = TINTS.PANEL,
	Size = UDim2.fromOffset(if compact then 340 else 520, if compact then 56 else 56),
	Position = UDim2.fromScale(0.5, if compact then 0.12 else 0.06),
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
	Name = "FlashOverlay",
	BackgroundColor3 = TINTS.WHITE,
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Visible = false,
	ZIndex = 100,
	Parent = ui,
})

local reveal = UiKit.Create("Frame", {
	Name = "Reveal",
	BackgroundColor3 = TINTS.PANEL,
	Size = UDim2.fromOffset(if compact then 330 else 420, if compact then 140 else 150),
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
	Name = "RevealButton",
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
	Name = "RiftStatusLabel",
	BackgroundColor3 = TINTS.PANEL,
	BackgroundTransparency = 0.2,
	TextColor3 = TINTS.ACCENT,
	Font = Enum.Font.GothamBold,
	TextSize = if compact then 13 else 16,
	Size = UDim2.fromOffset(if compact then 180 else 240, if compact then 32 else 36),
	Position = UDim2.fromScale(0.5, if compact then 0.18 else 0.16),
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
		Fx.Confetti(
			workspace.CurrentCamera.CFrame.Position - workspace.CurrentCamera.CFrame.LookVector * 12,
			TINTS.ACCENT,
			30
		)
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
	UpdateQuestBadge(state.Quests)
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

Net.QuestsSync.OnClientEvent:Connect(function(payload)
	if not payload or not payload.Quests then
		return
	end
	UpdateQuestBadge(payload.Quests)
	for _, panel in panels do
		if panel.module.Refresh then
			panel.module.Refresh(state)
		end
	end
	local notice = payload.Notice
	if notice then
		if notice.Type == "QuestComplete" then
			ShowAnnouncement(`Quête terminée : {notice.Name} !`)
			Flash(0.2)
		elseif notice.Type == "Achievement" then
			ShowAnnouncement(`Succès débloqué : {notice.Name} !`)
			Flash(0.25)
		end
	end
end)

require(script.Parent.CreatureDisplay)

return nil
