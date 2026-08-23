local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UiKit = require(script.Parent.UiKit)
local Audio = require(script.Parent.Audio)
local Net = require(ReplicatedStorage.Shared.Net)
local Species = require(ReplicatedStorage.Shared.Data.Species)
local Equipment = require(ReplicatedStorage.Shared.Data.Equipment)
local Config = require(ReplicatedStorage.Shared.Config)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)

local SanctuaryPanel = require(script.Parent.Panels.SanctuaryPanel)
local EggPanel = require(script.Parent.Panels.EggPanel)
local IndexPanel = require(script.Parent.Panels.IndexPanel)
local BreedingPanel = require(script.Parent.Panels.BreedingPanel)
local RebirthPanel = require(script.Parent.Panels.RebirthPanel)
local SkillPanel = require(script.Parent.Panels.SkillPanel)
local QuestsPanel = require(script.Parent.Panels.QuestsPanel)
local MarketPanel = require(script.Parent.Panels.MarketPanel)
local DuelPanel = require(script.Parent.Panels.DuelPanel)
local SeasonPanel = require(script.Parent.Panels.SeasonPanel)
local LeaderboardPanel = require(script.Parent.Panels.LeaderboardPanel)
local ShopPanel = require(script.Parent.Panels.ShopPanel)
local FriendsPanel = require(script.Parent.Panels.FriendsPanel)
local CreaturePortrait = require(script.Parent.CreaturePortrait)
local TutorialBridge = require(ReplicatedStorage.Shared.TutorialBridge)
local Fx = require(script.Parent.Fx)
local Cinematic = require(script.Parent.Cinematic)
local ObjectiveBanner = require(script.Parent.ObjectiveBanner)
local RiftFx = require(script.Parent.RiftFx)
local HatchCinematic = require(script.Parent.HatchCinematic)
local Celebration = require(script.Parent.Celebration)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local tcs = game:GetService("TextChatService")
pcall(function()
	tcs.ChatWindowConfiguration.VerticalAlignment = Enum.VerticalAlignment.Bottom
	tcs.ChatWindowConfiguration.HorizontalAlignment = Enum.HorizontalAlignment.Left
end)
if tcs.ChatVersion == Enum.ChatVersion.LegacyChatService then
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
end

local TINTS = UiKit.TINTS

local viewportWidth = pcall(function()
	return workspace.CurrentCamera.ViewportSize.X
end) and workspace.CurrentCamera.ViewportSize.X or 800
local compact = viewportWidth < 700

local function RatesLine(weights: { [string]: number }, nameOf: (string) -> string): string
	local parts = {}
	for _, rate in Gameplay.DropRates(weights) do
		table.insert(parts, `{nameOf(rate.Id)} {string.format("%g", rate.Percent)} %`)
	end
	return table.concat(parts, " · ")
end

local function RiftEggRatesText(): string
	return `Œufs : {RatesLine(Config.RIFT_EGG_WEIGHTS, function(id)
		return UiKit.EGG_TIER_NAMES[id] or id
	end)}`
end

local function RiftRelicRatesText(): string
	return `Reliques : {RatesLine(Config.RIFT_RELIC_WEIGHTS, function(id)
		if id == "None" then
			return "Aucune"
		end
		local tier = Equipment.Relic.Tiers[tonumber(string.sub(id, 2))]
		return tier and tier.Name or id
	end)}`
end

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
local topBarGradient = Instance.new("UIGradient")
topBarGradient.Name = "Gradient"
topBarGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, TINTS.PANEL),
	ColorSequenceKeypoint.new(1, TINTS.DARK),
})
topBarGradient.Rotation = 90
topBarGradient.Parent = topBar

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
local selectByName: { [string]: (() -> ())? } = {}
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

	local function Select()
		for _, panel in panels do
			panel.frame.Visible = false
		end
		frame.Visible = true
		TutorialBridge.SetActive(name)
	end

	button.Activated:Connect(Select)
	selectByName[name] = Select

	table.insert(panels, { module = panelModule, frame = frame })
end

AddTab("Sanctuaire", SanctuaryPanel)
AddTab("Œufs", EggPanel)
AddTab("Index", IndexPanel)
AddTab("Élevage", BreedingPanel)
AddTab("Renaissance", RebirthPanel)
AddTab("Arbre", SkillPanel)
AddTab("Objectifs", QuestsPanel)
AddTab("Marché", MarketPanel)
AddTab("Boutique", ShopPanel)
AddTab("Amis", FriendsPanel)

-- Tab "Duels & Classements" : wrapper avec sous-onglets Duels / Saison / Classements
do
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
		Text = "Duels & Classements",
		Parent = tabBar,
	})
	UiKit.Corner(button)

	local frame = UiKit.Create("Frame", {
		Name = `Panel{tabCount}`,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = panelsFrame,
	})
	frame.Visible = false

	local subPages = {
		DuelPanel.Create(frame),
		SeasonPanel.Create(frame),
		LeaderboardPanel.Create(frame),
	}
	for _, page in subPages do
		page.Position = UDim2.fromOffset(0, 32)
	end
	UiKit.SubTabs(frame, 30, {
		{ Name = "Duels", Page = subPages[1] },
		{ Name = "Saison", Page = subPages[2] },
		{ Name = "Classements", Page = subPages[3] },
	})

	local function Select()
		for _, panel in panels do
			panel.frame.Visible = false
		end
		frame.Visible = true
		TutorialBridge.SetActive("Duels & Classements")
	end

	button.Activated:Connect(Select)
	selectByName["Duels & Classements"] = Select

	table.insert(panels, {
		module = {
			Create = function()
				return frame
			end,
			Refresh = function(state)
				for _, pageModule in { DuelPanel, SeasonPanel, LeaderboardPanel } do
					if pageModule.Refresh then
						pageModule.Refresh(state)
					end
				end
			end,
		},
		frame = frame,
	})
end

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
tabBar:GetPropertyChangedSignal("AbsoluteSize"):Connect(LayoutTabs)
LayoutTabs()

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

local menuTargetSize = UDim2.fromScale(if compact then 0.96 else 0.72, if compact then 0.96 else 0.72)
local menuTween
local menuOpen = false

local function SetMenuOpen(open: boolean)
	if menuTween then
		menuTween:Cancel()
	end
	menuOpen = open
	if open then
		content.Visible = true
		content.Size = UDim2.fromScale(menuTargetSize.X.Scale * 0.96, menuTargetSize.Y.Scale * 0.96)
		content.BackgroundTransparency = 0.45
		menuTween = TweenService:Create(content, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = menuTargetSize,
			BackgroundTransparency = 0,
		})
		menuTween:Play()
	else
		menuTween = TweenService:Create(content, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.fromScale(menuTargetSize.X.Scale * 0.96, menuTargetSize.Y.Scale * 0.96),
			BackgroundTransparency = 0.45,
		})
		menuTween.Completed:Connect(function()
			if not menuOpen then
				content.Visible = false
			end
		end)
		menuTween:Play()
	end
	TutorialBridge.Set("MenuOpen", open)
end

SetMenuOpen(false)

local ShowAnnouncement: (string) -> ()

-- Barre d'action permanente en bas (bible §4.B) : les 3 gestes du jeu + Plus.
local actionBar = UiKit.Create("Frame", {
	Name = "ActionBar",
	BackgroundTransparency = 1,
	Position = UDim2.new(0.5, 0, 1, -8),
	AnchorPoint = Vector2.new(0.5, 1),
	Size = UDim2.fromOffset(if compact then 336 else 424, 52),
	Parent = ui,
})
UiKit.Create("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = actionBar,
})

local function BarButton(text: string, layoutOrder: number, accent: boolean?): TextButton
	local button = UiKit.Create("TextButton", {
		Name = `Bar_{text}`,
		BackgroundColor3 = if accent then TINTS.ACCENT else TINTS.PANEL,
		TextColor3 = TINTS.WHITE,
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		Size = UDim2.fromOffset(100, 52),
		LayoutOrder = layoutOrder,
		Text = text,
		Parent = actionBar,
	})
	UiKit.Corner(button)
	return button
end

local failleButton = BarButton("Faille", 2)
BarButton("Œufs", 1).Activated:Connect(function()
	SetMenuOpen(true)
	if selectByName["Œufs"] then
		selectByName["Œufs"]()
	end
end)
BarButton("Sanctuaire", 3).Activated:Connect(function()
	SetMenuOpen(true)
	if selectByName["Sanctuaire"] then
		selectByName["Sanctuaire"]()
	end
end)
BarButton("Plus", 4).Activated:Connect(function()
	SetMenuOpen(true)
end)

local riftActiveState = false
local riftNextAt = 0

local function UpdateFailleButton()
	if riftActiveState then
		failleButton.Text = "FAILLE !"
	elseif riftNextAt > 0 then
		local remaining = math.max(0, riftNextAt - os.time())
		failleButton.Text = string.format("Faille %d:%02d", math.floor(remaining / 60), remaining % 60)
	else
		failleButton.Text = "Faille"
	end
end

failleButton.Activated:Connect(function()
	Net.RiftRequest:FireServer()
	local msg
	if riftActiveState then
		msg = "Une faille est ouverte ! Rejoins le portail."
	elseif riftNextAt > 0 then
		local remaining = math.max(0, riftNextAt - os.time())
		msg = string.format("Prochaine faille dans %d:%02d", math.floor(remaining / 60), remaining % 60)
	else
		msg = "La faille revient bientôt…"
	end
	ShowAnnouncement(msg)
end)

local riftHud = UiKit.Create("Frame", {
	Name = "RiftHud",
	BackgroundColor3 = TINTS.PANEL,
	Size = UDim2.fromOffset(if compact then 330 else 420, if compact then 190 else 210),
	Position = UDim2.new(0.5, 0, 1, -70),
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
	Size = UDim2.fromScale(1, 0.16),
	Position = UDim2.fromScale(0, 0.5),
	Text = "Attaquer",
	Parent = riftHud,
})
UiKit.Corner(attackButton)

local riftRatesLabel = UiKit.Create("TextLabel", {
	Name = "RiftRates",
	RichText = true,
	BackgroundTransparency = 1,
	TextColor3 = TINTS.WHITE,
	TextSize = if compact then 9 else 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = true,
	Position = UDim2.fromScale(0, 0.67),
	Size = UDim2.fromScale(1, 0.18),
	Text = `{RiftEggRatesText()}\n{RiftRelicRatesText()}`,
	Parent = riftHud,
})

local riftHint = UiKit.Create("TextLabel", {
	BackgroundTransparency = 1,
	TextColor3 = TINTS.WHITE,
	TextSize = 14,
	Position = UDim2.fromScale(0, 0.86),
	Size = UDim2.fromScale(1, 0.12),
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

local revealPortrait = CreaturePortrait.Create(reveal, UDim2.new(0, 6, 0, 6), UDim2.new(0.3, -6, 1, -12))
revealPortrait.vp.ZIndex = 20

local revealLabel = UiKit.Create("TextLabel", {
	BackgroundTransparency = 1,
	TextColor3 = TINTS.WHITE,
	Font = Enum.Font.GothamBold,
	TextSize = 20,
	Position = UDim2.fromScale(0.32, 0),
	Size = UDim2.fromScale(0.68, 0.7),
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
function ShowAnnouncement(text: string)
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

local lastGuardianHP: number? = nil
local lastPlayerHP: number? = nil
local autoOpenedMenu = false
local tutorialDone = false

local function ShowRiftSync(state)
	if not state.InRift then
		riftHud.Visible = false
		lastGuardianHP = nil
		lastPlayerHP = nil
		return
	end
	riftHud.Visible = true
	if not TutorialBridge.state.RiftEntered then
		TutorialBridge.Set("RiftEntered", true)
	end
	UiKit.SetBar(guardianFill, guardianLabel, state.GuardianHP, state.GuardianMaxHP)
	UiKit.SetBar(playerHpFill, playerHpLabel, state.PlayerHP, state.PlayerMaxHP)
	if lastGuardianHP and state.GuardianHP < lastGuardianHP then
		local original = guardianFill.BackgroundColor3
		guardianFill.BackgroundColor3 = Color3.fromRGB(255, 90, 90)
		TweenService:Create(guardianFill, TweenInfo.new(0.3), { BackgroundColor3 = original }):Play()
	end
	if lastPlayerHP and state.PlayerHP < lastPlayerHP then
		RiftFx.OnGuardianHit()
	end
	lastGuardianHP = state.GuardianHP
	lastPlayerHP = state.PlayerHP
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
			`Faille terminée : +{result.Essence} Essence et {UiKit.EGG_TIER_NAMES[result.EggTier] or result.EggTier}{relicText}`
		)
		Flash(0.35)
		Fx.Confetti(
			workspace.CurrentCamera.CFrame.Position - workspace.CurrentCamera.CFrame.LookVector * 12,
			TINTS.ACCENT,
			30
		)
		if not autoOpenedMenu and not tutorialDone then
			autoOpenedMenu = true
			SetMenuOpen(true)
			if selectByName["Œufs"] then
				selectByName["Œufs"]()
			end
		end
	else
		ShowAnnouncement("Défaite face au gardien. Tes créatures n'étaient pas prêtes.")
	end
end

attackButton.Activated:Connect(function()
	Audio.Play("RiftWhoosh", 0.3)
	RiftFx.OnAttack()
	Net.RiftAttack:FireServer()
end)

revealButton.Activated:Connect(function()
	reveal.Visible = false
end)

local state = nil

local function RefreshAll(newState)
	state = newState
	tutorialDone = newState.TutorialDone == true
	essenceLabel.Text = `Essence : {state.Essence}`
	rateLabel.Text = `Rendement : {string.format("%.1f", state.Rate)} / s`
	if state.Stars > 0 then
		rateLabel.Text ..= ` — ★{state.Stars}`
	end
	if state.Luck and state.Luck > 0 then
		rateLabel.Text ..= ` — Chance +{math.floor(state.Luck * 100 + 0.5)} %`
	end
	if state.Meute and state.Meute > 0 then
		rateLabel.Text ..= ` — Meute ×{state.Meute}`
	end
	UpdateQuestBadge(state.Quests)
	ObjectiveBanner.Refresh(state)
	for _, panel in panels do
		if panel.module.Refresh then
			panel.module.Refresh(state)
		end
	end
end

Net.Sync.OnClientEvent:Connect(RefreshAll)

Net.HatchResult.OnClientEvent:Connect(function(result)
	if result.WorldHatch then
		Audio.Play("RareFanfare")
		HatchCinematic.Play(result)
		ShowAnnouncement(`{result.SpeciesName} t'accompagne désormais !`)
		return
	end
	Audio.Play("HatchCrack")
	local mutationText = result.MutationName and ` {result.MutationName}` or ""
	revealLabel.Text = `Tu as obtenu {result.SpeciesName} !\n{result.RarityName}{mutationText}`
	revealLabel.TextColor3 = result.RarityColor
	if result.Creature then
		CreaturePortrait.Show(
			revealPortrait,
			result.Creature.SpeciesId,
			result.Creature.Rarity,
			result.Creature.Mutation
		)
	end
	reveal.Visible = true

	local rank = Gameplay.RarityRank(result.Rarity or "")
	Celebration.Hatch(rank)
	if Celebration.Tier(rank) == "ultra" then
		Flash(0.7)
	end
end)

Net.BreedResult.OnClientEvent:Connect(function(result)
	local species = Species[result.Creature.SpeciesId]
	local name = species and species.Name or result.Creature.SpeciesId
	revealLabel.Text = `Élevage réussi !\n{name} — Génération {result.Creature.Generation}`
	revealLabel.TextColor3 = TINTS.ACCENT
	CreaturePortrait.Show(revealPortrait, result.Creature.SpeciesId, result.Creature.Rarity, result.Creature.Mutation)
	reveal.Visible = true
end)

Net.RareDrop.OnClientEvent:Connect(function(payload)
	Cinematic.Play(payload)
	local mutationText = payload.MutationName and ` {payload.MutationName}` or ""
	ShowAnnouncement(`{payload.PlayerName} a obtenu {payload.SpeciesName} ({payload.RarityName}{mutationText}) !`)
end)

Net.RiftSync.OnClientEvent:Connect(ShowRiftSync)

Net.RiftEnded.OnClientEvent:Connect(ShowRiftEnded)

local riftCountdown: Thread? = nil

local function StartRiftCountdown(nextAt: number)
	if riftCountdown then
		coroutine.close(riftCountdown)
		riftCountdown = nil
	end
	riftNextAt = nextAt
	riftActiveState = false
	riftCountdown = task.spawn(function()
		while riftStatusLabel and riftStatusLabel.Parent do
			local remaining = math.max(0, nextAt - os.time())
			riftStatusLabel.Text =
				`Prochaine faille dans {string.format("%d:%02d", math.floor(remaining / 60), remaining % 60)}`
			riftStatusLabel.Visible = remaining > 0
			UpdateFailleButton()
			if remaining <= 0 then
				break
			end
			task.wait(1)
		end
	end)
end

task.spawn(function()
	-- le serveur peut ne pas avoir connecte RiftRequest au tout debut : retries
	for i = 1, 5 do
		task.wait(1.5 + i * 2)
		Net.RiftRequest:FireServer()
	end
end)

Net.RiftWorld.OnClientEvent:Connect(function(world)
	if world.Active then
		if riftCountdown then
			coroutine.close(riftCountdown)
			riftCountdown = nil
		end
		Audio.Play("RiftWhoosh")
		riftStatusLabel.Text = "Une faille s'est ouverte ! Entre dans le portail."
		riftStatusLabel.Visible = true
		riftActiveState = true
		riftNextAt = 0
		UpdateFailleButton()
	elseif world.NextAt and world.NextAt > 0 then
		StartRiftCountdown(world.NextAt)
	else
		if riftCountdown then
			coroutine.close(riftCountdown)
			riftCountdown = nil
		end
		riftStatusLabel.Visible = false
		riftActiveState = false
		riftNextAt = 0
		UpdateFailleButton()
	end
end)

Net.QuestsSync.OnClientEvent:Connect(function(payload)
	if not payload then
		return
	end
	if payload.Quests then
		UpdateQuestBadge(payload.Quests)
		for _, panel in panels do
			if panel.module.Refresh then
				panel.module.Refresh(state)
			end
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
		elseif notice.Type == "Streak" then
			ShowAnnouncement(`Série de connexion jour {notice.Day} : +{notice.Amount} essence !`)
			Audio.Play("CoinReward")
			Flash(0.3)
		elseif notice.Type == "VipGift" then
			ShowAnnouncement(`Cadeau VIP quotidien : +{notice.Amount} essence !`)
			Audio.Play("CoinReward")
			Flash(0.3)
		elseif notice.Type == "Eclipse" then
			ShowAnnouncement(`{notice.Name} {notice.Desc}`)
			Audio.Play("CoinReward")
			Flash(0.35)
		elseif notice.Type == "FriendJoined" then
			ShowAnnouncement(`{notice.Name} (ami) a rejoint ! Meute +10 %`)
		end
	end
end)

ObjectiveBanner.Mount(ui)

require(script.Parent.CreatureDisplay)
require(script.Parent.CouveusePanel)
require(script.Parent.FollowController).Start()
require(script.Parent.FarmBehaviors).Start()

Net.OrbClaimed.OnClientEvent:Connect(function(payload)
	if payload and payload.Position then
		Fx.FloatText(payload.Position + Vector3.new(0, 2.5, 0), `+{payload.Amount}`, TINTS.ACCENT)
	end
end)

-- Layout réactif au redimensionnement du viewport (bible §4.B).
local function ApplyLayout()
	local camera = workspace.CurrentCamera
	local ok, width = pcall(function()
		return camera.ViewportSize.X
	end)
	compact = if ok then width < 700 else false
	topBar.Size = UDim2.fromOffset(if compact then 230 else 300, if compact then 56 else 64)
	menuTargetSize = UDim2.fromScale(if compact then 0.96 else 0.72, if compact then 0.96 else 0.72)
	if not menuOpen then
		content.Size = menuTargetSize
	end
	actionBar.Size = UDim2.fromOffset(if compact then 336 else 424, 52)
	riftHud.Size = UDim2.fromOffset(if compact then 330 else 420, if compact then 190 else 210)
	riftRatesLabel.TextSize = if compact then 9 else 11
	announcement.Size = UDim2.fromOffset(if compact then 340 else 520, 56)
	announcement.Position = UDim2.fromScale(0.5, if compact then 0.12 else 0.06)
	reveal.Size = UDim2.fromOffset(if compact then 330 else 420, if compact then 140 else 150)
	riftStatusLabel.Size = UDim2.fromOffset(if compact then 180 else 240, if compact then 32 else 36)
	riftStatusLabel.Position = UDim2.fromScale(0.5, if compact then 0.18 else 0.16)
	riftStatusLabel.TextSize = if compact then 13 else 16
end

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(ApplyLayout)
ApplyLayout()

return nil
