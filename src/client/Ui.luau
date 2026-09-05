local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local UiKit = require(script.Parent:WaitForChild("UiKit"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local Net = require(ReplicatedStorage.Shared.Net)
local Species = require(ReplicatedStorage.Shared.Data.Species)
local Equipment = require(ReplicatedStorage.Shared.Data.Equipment)
local Config = require(ReplicatedStorage.Shared.Config)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Sanctuary = require(ReplicatedStorage.Shared.Sanctuary)

local panelModules = script.Parent:WaitForChild("Panels")
local SanctuaryPanel = require(panelModules:WaitForChild("SanctuaryPanel"))
local EggPanel = require(panelModules:WaitForChild("EggPanel"))
local CouveusePanel = require(panelModules:WaitForChild("CouveusePanel"))
local IndexPanel = require(panelModules:WaitForChild("IndexPanel"))
local BreedingPanel = require(panelModules:WaitForChild("BreedingPanel"))
local RebirthPanel = require(panelModules:WaitForChild("RebirthPanel"))
local SkillPanel = require(panelModules:WaitForChild("SkillPanel"))
local QuestsPanel = require(panelModules:WaitForChild("QuestsPanel"))
local MarketPanel = require(panelModules:WaitForChild("MarketPanel"))
local DuelPanel = require(panelModules:WaitForChild("DuelPanel"))
local SeasonPanel = require(panelModules:WaitForChild("SeasonPanel"))
local LeaderboardPanel = require(panelModules:WaitForChild("LeaderboardPanel"))
local ShopPanel = require(panelModules:WaitForChild("ShopPanel"))
local FriendsPanel = require(panelModules:WaitForChild("FriendsPanel"))
local CreaturePortrait = require(script.Parent:WaitForChild("CreaturePortrait"))
local TutorialBridge = require(ReplicatedStorage.Shared.TutorialBridge)
local Fx = require(script.Parent:WaitForChild("Fx"))
local Cinematic = require(script.Parent:WaitForChild("Cinematic"))
local ObjectiveBanner = require(script.Parent:WaitForChild("ObjectiveBanner"))
local RiftFx = require(script.Parent:WaitForChild("RiftFx"))
local HatchCinematic = require(script.Parent:WaitForChild("HatchCinematic"))
local Celebration = require(script.Parent:WaitForChild("Celebration"))

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

local function RiftEggRatesText(): string
	return `Œufs : {UiKit.DropRatesText(Config.RIFT_EGG_WEIGHTS, function(rate)
		return `{UiKit.EGG_TIER_NAMES[rate.Id] or rate.Id} {string.format("%g", rate.Percent)} %`
	end)}`
end

local function RiftRelicRatesText(): string
	return `Reliques : {UiKit.DropRatesText(Config.RIFT_RELIC_WEIGHTS, function(rate)
		local name = "Aucune"
		if rate.Id ~= "None" then
			local tier = Equipment.Relic.Tiers[tonumber(string.sub(rate.Id, 2))]
			name = tier and tier.Name or rate.Id
		end
		return `{name} {string.format("%g", rate.Percent)} %`
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
	Size = UDim2.fromOffset(if compact then 240 else 320, if compact then 76 else 84),
	Position = UDim2.fromOffset(12, 64), -- sous les boutons Roblox du topbar (IgnoreGuiInset = true)
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
	TextSize = 22,
	TextXAlignment = Enum.TextXAlignment.Left,
	Size = UDim2.fromScale(1, 0.38),
	Text = "Essence : 0",
	Parent = topBar,
})

local rateLabel = UiKit.Create("TextLabel", {
	Name = "RateLabel",
	BackgroundTransparency = 1,
	TextColor3 = TINTS.WHITE,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0, 0.38),
	Size = UDim2.fromScale(1, 0.28),
	Text = "Rendement : 0 / s",
	Parent = topBar,
})

-- Possessions permanentes : places occupées, étoiles et points d'arbre visibles sans ouvrir le menu.
local possessionsLabel = UiKit.Create("TextLabel", {
	Name = "PossessionsLabel",
	BackgroundTransparency = 1,
	TextColor3 = TINTS.WHITE,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0, 0.66),
	Size = UDim2.fromScale(1, 0.34),
	Text = "🐾 0/0   ★ 0   🌟 0",
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
local tabButtons: { [string]: TextButton } = {}
-- Onglet actuellement affiché : permet au bouton de barre d'action de refermer le menu.
local activeTabName = ""
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
		activeTabName = name
		TutorialBridge.SetActive(name)
	end

	button.Activated:Connect(Select)
	selectByName[name] = Select
	tabButtons[name] = button

	table.insert(panels, { module = panelModule, frame = frame, name = name, button = button })
end

AddTab("Sanctuaire", SanctuaryPanel)
AddTab("Œufs", EggPanel)
AddTab("Couveuse", CouveusePanel)
AddTab("Index", IndexPanel)
AddTab("Élevage", BreedingPanel)
AddTab("Renaissance", RebirthPanel)
AddTab("Arbre", SkillPanel)
AddTab("Objectifs", QuestsPanel)
if Config.MARKET_ENABLED then
	AddTab("Marché", MarketPanel)
end
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
		activeTabName = "Duels & Classements"
		TutorialBridge.SetActive("Duels & Classements")
	end

	button.Activated:Connect(Select)
	selectByName["Duels & Classements"] = Select
	tabButtons["Duels & Classements"] = button

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
		name = "Duels & Classements",
		button = button,
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
	activeTabName = panels[1].name
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
local previousSelectedObject: GuiObject? = nil

local function IsFocusable(target: GuiObject?): GuiObject?
	if not target or not target:IsDescendantOf(playerGui) or not target.Visible or not target.Selectable then
		return nil
	end
	local ancestor = target.Parent
	while ancestor and ancestor ~= playerGui do
		if ancestor:IsA("GuiObject") and not ancestor.Visible then
			return nil
		end
		if ancestor:IsA("ScreenGui") and not ancestor.Enabled then
			return nil
		end
		ancestor = ancestor.Parent
	end
	return target
end

local function FirstFocusable(root: Instance): GuiObject?
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("GuiObject") then
			local target = IsFocusable(descendant)
			if target then
				return target
			end
		end
	end
	return nil
end

local function SetMenuOpen(open: boolean, focusTarget: GuiObject?, returnTarget: GuiObject?)
	if menuTween then
		menuTween:Cancel()
	end
	if open and not menuOpen then
		previousSelectedObject = IsFocusable(GuiService.SelectedObject) or IsFocusable(returnTarget)
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
		GuiService.SelectedObject = IsFocusable(focusTarget)
			or IsFocusable(tabButtons[activeTabName])
			or FirstFocusable(content)
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
		local restore = previousSelectedObject
		previousSelectedObject = nil
		GuiService.SelectedObject = IsFocusable(restore)
	end
	TutorialBridge.Set("MenuOpen", open)
end

-- Bouton fermer : coin haut-droit du menu, au-dessus des panneaux (même ancrage que questBadge).
local closeButton = UiKit.Create("TextButton", {
	Name = "CloseMenu",
	BackgroundColor3 = TINTS.RED,
	TextColor3 = TINTS.WHITE,
	Font = Enum.Font.GothamBold,
	TextSize = 18,
	Size = UDim2.fromOffset(32, 32),
	Position = UDim2.new(1, -6, 0, -6),
	AnchorPoint = Vector2.new(1, 0),
	ZIndex = 5,
	Text = "✕",
	Parent = content,
})
UiKit.Corner(closeButton)
closeButton.Activated:Connect(function()
	SetMenuOpen(false)
end)

SetMenuOpen(false)

-- Badge points d'arbre : même pattern que questBadge, ouvre l'onglet Arbre au clic.
local skillBadge = UiKit.Create("TextButton", {
	Name = "SkillBadge",
	BackgroundColor3 = TINTS.ACCENT,
	BackgroundTransparency = 0.1,
	TextColor3 = TINTS.DARK,
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	Size = UDim2.fromOffset(24, 24),
	Position = UDim2.new(1, -34, 0, -6),
	AnchorPoint = Vector2.new(1, 0),
	ZIndex = 5,
	Text = "🌟",
	Visible = false,
	Parent = topBar,
})
UiKit.Corner(skillBadge)
skillBadge.Activated:Connect(function()
	SetMenuOpen(true, tabButtons["Arbre"], skillBadge)
	if selectByName["Arbre"] then
		selectByName["Arbre"]()
	end
end)

local settingsPanel = UiKit.Create("Frame", {
	Name = "SettingsPanel",
	BackgroundColor3 = TINTS.PANEL,
	Size = UDim2.fromOffset(if compact then 300 else 340, 284),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Visible = false,
	ZIndex = 40,
	Parent = ui,
})
UiKit.Corner(settingsPanel)
UiKit.Padding(settingsPanel, 12)
local settingsTitle = UiKit.Title(settingsPanel, "Réglages", 18)
settingsTitle.ZIndex = 40
UiKit.Create("TextLabel", {
	BackgroundTransparency = 1,
	TextColor3 = TINTS.WHITE,
	TextSize = 12,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	Size = UDim2.new(1, 0, 0, 30),
	Position = UDim2.fromOffset(0, 28),
	Text = "Les textes, taux et récompenses restent toujours visibles.",
	ZIndex = 40,
	Parent = settingsPanel,
})
local settingsSfx = UiKit.Button(settingsPanel, "Sons : activés", UDim2.new(1, 0, 0, 44), UDim2.fromOffset(0, 62))
settingsSfx.ZIndex = 41
local settingsMusic =
	UiKit.Button(settingsPanel, "Musique : activée", UDim2.new(1, 0, 0, 44), UDim2.fromOffset(0, 112))
settingsMusic.ZIndex = 41
local settingsEffects =
	UiKit.Button(settingsPanel, "Effets réduits : désactivés", UDim2.new(1, 0, 0, 44), UDim2.fromOffset(0, 162))
settingsEffects.ZIndex = 41
local ownedTitles: { string } = {}
local selectedTitle: string? = nil
local settingsTitleButton =
	UiKit.Button(settingsPanel, "Titre : aucun", UDim2.new(1, 0, 0, 44), UDim2.fromOffset(0, 212))
settingsTitleButton.ZIndex = 41

local function RefreshSettings()
	settingsSfx.Text = `Sons : {if Audio.IsSfxEnabled() then "activés" else "désactivés"}`
	settingsMusic.Text = `Musique : {if Audio.IsMusicEnabled() then "activée" else "désactivée"}`
	settingsEffects.Text = `Effets réduits : {if Audio.AreEffectsReduced() then "activés" else "désactivés"}`
	settingsTitleButton.Text = if selectedTitle then `Titre : {selectedTitle}` else "Titre : aucun"
end

settingsSfx.Activated:Connect(function()
	Audio.SetSfxEnabled(not Audio.IsSfxEnabled())
	RefreshSettings()
end)
settingsMusic.Activated:Connect(function()
	Audio.SetMusicEnabled(not Audio.IsMusicEnabled())
	RefreshSettings()
end)
settingsEffects.Activated:Connect(function()
	Audio.SetReducedEffects(not Audio.AreEffectsReduced())
	RefreshSettings()
end)
settingsTitleButton.Activated:Connect(function()
	if #ownedTitles == 0 then
		return
	end
	local currentIndex = if selectedTitle then table.find(ownedTitles, selectedTitle) or 0 else 0
	selectedTitle = if currentIndex >= #ownedTitles then nil else ownedTitles[currentIndex + 1]
	Net.SetTitle:FireServer(selectedTitle)
	RefreshSettings()
end)

local settingsButton = UiKit.Create("TextButton", {
	Name = "SettingsButton",
	BackgroundColor3 = TINTS.PANEL,
	TextColor3 = TINTS.WHITE,
	Font = Enum.Font.GothamBold,
	TextSize = 18,
	Size = UDim2.fromOffset(24, 24),
	Position = UDim2.new(1, -62, 0, -6),
	AnchorPoint = Vector2.new(1, 0),
	ZIndex = 5,
	Text = "⚙",
	Parent = topBar,
})
UiKit.Corner(settingsButton)
settingsButton.Activated:Connect(function()
	if menuOpen then
		SetMenuOpen(false)
	end
	settingsPanel.Visible = not settingsPanel.Visible
	RefreshSettings()
	if settingsPanel.Visible then
		GuiService.SelectedObject = settingsSfx
	end
end)

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

-- Re-cliquer le bouton de l'onglet déjà affiché referme le menu ; sinon ouvre et sélectionne.
local function ToggleOrSelect(name: string, origin: GuiObject?)
	if menuOpen and activeTabName == name then
		SetMenuOpen(false)
	else
		SetMenuOpen(true, tabButtons[name], origin)
		if selectByName[name] then
			selectByName[name]()
		end
	end
end

CouveusePanel.SetOpenCallback(function()
	ToggleOrSelect("Couveuse")
end)

local parcoursButton = BarButton("Parcours", 2)
parcoursButton.Visible = false
local eggsButton = BarButton("Œufs", 1)
eggsButton.Activated:Connect(function()
	ToggleOrSelect("Œufs", eggsButton)
end)
local sanctuariesButton = BarButton("Sanctuaires", 3)
sanctuariesButton.Activated:Connect(function()
	ToggleOrSelect("Sanctuaire", sanctuariesButton)
end)
local moreButton = BarButton("Plus", 4)
moreButton.Visible = false
moreButton.Activated:Connect(function()
	SetMenuOpen(not menuOpen, tabButtons[activeTabName], moreButton)
end)

-- La couveuse utilise le menu Œufs unique ; aucun doublon flottant illisible.
task.spawn(function()
	local model = workspace:WaitForChild("Couveuse", 30)
	local prompt = model and model:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then
		prompt.Triggered:Connect(function()
			ToggleOrSelect("Couveuse")
		end)
	end
end)

-- Manette (B) et Échap referment le menu ouvert.
UserInputService.InputBegan:Connect(function(input, _gameProcessedEvent)
	if input.KeyCode == Enum.KeyCode.ButtonB or input.KeyCode == Enum.KeyCode.Escape then
		if settingsPanel.Visible then
			settingsPanel.Visible = false
		end
		if menuOpen then
			SetMenuOpen(false)
		end
	end
end)

local riftActiveState = false
local riftNextAt = 0
local worldPicker

local function UpdateFailleButton()
	if riftActiveState then
		parcoursButton.Text = "PARCOURS !"
	elseif riftNextAt > 0 then
		local remaining = math.max(0, riftNextAt - os.time())
		parcoursButton.Text = string.format("Parcours %d:%02d", math.floor(remaining / 60), remaining % 60)
	else
		parcoursButton.Text = "Parcours"
	end
end

parcoursButton.Activated:Connect(function()
	Net.RiftRequest:FireServer()
	local msg
	if riftActiveState then
		msg = "Un parcours est ouvert ! Rejoins le portail."
	elseif riftNextAt > 0 then
		local remaining = math.max(0, riftNextAt - os.time())
		msg = string.format("Prochain parcours dans %d:%02d", math.floor(remaining / 60), remaining % 60)
	else
		msg = "Le parcours revient bientôt…"
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
	Text = "Parcours",
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
	Text = "Posture : Balanced",
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

local revealPortrait = CreaturePortrait.Create(reveal, UDim2.fromOffset(6, 6), UDim2.new(0.3, -6, 1, -12))
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

worldPicker = UiKit.Create("Frame", {
	Name = "WorldPicker",
	BackgroundColor3 = TINTS.PANEL,
	Size = UDim2.fromOffset(if compact then 330 else 380, if compact then 260 else 280),
	Position = UDim2.fromScale(0.5, 0.24),
	AnchorPoint = Vector2.new(0.5, 0),
	Visible = false,
	ZIndex = 12,
	Parent = ui,
})
UiKit.Corner(worldPicker)
UiKit.Padding(worldPicker, 10)

local function RenderWorldPicker(worlds)
	if not worldPicker then
		return
	end
	UiKit.Clear(worldPicker)
	UiKit.Title(worldPicker, "Choisis une région", 16).ZIndex = 12
	local list = UiKit.Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 30),
		Size = UDim2.new(1, 0, 1, -30),
		ZIndex = 12,
		Parent = worldPicker,
	})
	UiKit.Create("UIListLayout", {
		Padding = UDim.new(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = list,
	})
	for index, world in ipairs(worlds or {}) do
		local button = UiKit.Button(list, world.Name or world.Id or "Région", UDim2.new(1, 0, 0, 44))
		button.LayoutOrder = index
		button.ZIndex = 12
		button.Text = `{world.Name or world.Id} — étape suivante`
		button.Activated:Connect(function()
			worldPicker.Visible = false
			Net.ExpeditionRequest:FireServer(world.Id)
			ShowAnnouncement(`Entrée demandée : {world.Name or world.Id}`)
		end)
	end
	worldPicker.Visible = true
end

function ShowAnnouncement(text: string)
	announcementLabel.Text = text
	announcement.Visible = true
	announcement.BackgroundTransparency = 0.1
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
	if Audio.AreEffectsReduced() then
		return
	end
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

local function ShowRiftSync(state)
	if not state.InRift then
		riftHud.Visible = false
		if worldPicker then
			worldPicker.Visible = false
		end
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
		attackButton.Text = `Posture : {state.Stance or "Balanced"}`
		riftHint.Text = ""
	end
end

local function ShowRiftEnded(result)
	riftHud.Visible = false
	if result.Win then
		Audio.Play("CoinReward")
		local relicText = result.RelicTier and `\nRelique T{result.RelicTier} obtenue !` or ""
		ShowAnnouncement(
			`Parcours terminé : +{result.Essence} Essence et {UiKit.EGG_TIER_NAMES[result.EggTier] or result.EggTier}{relicText}`
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
	local current = string.match(attackButton.Text, ": (.+)$")
	local nextStance = if current == "Power" then "Guard" elseif current == "Guard" then "Balanced" else "Power"
	Net.ExpeditionAction:FireServer("Stance", nextStance)
end)

revealButton.Activated:Connect(function()
	reveal.Visible = false
end)

local state = nil

local function UpdateTopbar(topbarState)
	if not topbarState then
		return
	end
	essenceLabel.Text = `Essence : {topbarState.Essence or 0}`
	rateLabel.Text = `Rendement : {string.format("%.1f", topbarState.Rate or 0)} / s`
	if topbarState.Stars and topbarState.Stars > 0 then
		rateLabel.Text ..= ` — ★{topbarState.Stars}`
	end
	if topbarState.Luck and topbarState.Luck > 0 then
		rateLabel.Text ..= ` — Chance +{math.floor(topbarState.Luck * 100 + 0.5)} %`
	end
	if topbarState.Meute and topbarState.Meute > 0 then
		rateLabel.Text ..= ` — Meute ×{topbarState.Meute}`
	end
	-- Possessions : places du sanctuaire (gamepass inclus), étoiles, points d'arbre à dépenser.
	local bonusSlots = if topbarState.MoreSlots then Config.GAMEPASSES.MoreSlots.BonusSlots else 0
	local hasSkillPoints = (topbarState.SkillPoints or 0) > 0
	possessionsLabel.Text = `🐾 {topbarState.CreatureCount or 0}/{Sanctuary.MaxCreatures(
		topbarState.SanctuaryLevel or 1,
		bonusSlots
	)}   ★ {topbarState.Stars or 0}   🌟 {topbarState.SkillPoints or 0}`
	possessionsLabel.TextColor3 = if hasSkillPoints then TINTS.ACCENT else TINTS.WHITE
	skillBadge.Visible = hasSkillPoints
end

local function RefreshAll(newState)
	state = newState
	ownedTitles = {}
	if type(state.Titles) == "table" then
		for _, title in state.Titles do
			if type(title) == "string" then
				table.insert(ownedTitles, title)
			end
		end
	end
	selectedTitle = if type(state.SelectedTitle) == "string" then state.SelectedTitle else nil
	RefreshSettings()
	actionBar.Visible = true
	local unlocks = state.FeatureUnlocks or {}
	parcoursButton.Visible = unlocks.Expeditions == true
	moreButton.Visible = unlocks.More == true
	local gates = {
		Index = "Index",
		["Élevage"] = "Breeding",
		Renaissance = "Rebirth",
		Arbre = "SkillTree",
		Objectifs = "Objectives",
		["Marché"] = "Market",
		Boutique = "Shop",
		Amis = "Social",
		["Duels & Classements"] = "Duels",
	}
	for name, key in gates do
		local button = tabButtons[name]
		if button then
			button.Visible = unlocks[key] == true
		end
	end
	UpdateTopbar({
		Essence = state.Essence,
		Rate = state.Rate,
		Stars = state.Stars,
		Luck = state.Luck,
		Meute = state.Meute,
		CreatureCount = state.Creatures and #state.Creatures or 0,
		SanctuaryLevel = state.SanctuaryLevel,
		MoreSlots = state.Entitlements and state.Entitlements.MoreSlots == true,
		SkillPoints = state.SkillPoints,
	})
	UpdateQuestBadge(state.Quests)
	ObjectiveBanner.Refresh(state)
	for _, panel in panels do
		if panel.module.Refresh then
			panel.module.Refresh(state)
		end
	end
end

Net.Sync.OnClientEvent:Connect(RefreshAll)

Net.EconomySync.OnClientEvent:Connect(function(payload)
	if not payload then
		return
	end
	state = state or {}
	for key, value in payload do
		state[key] = value
	end
	UpdateTopbar(payload)
end)

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
				`Prochain parcours dans {string.format("%d:%02d", math.floor(remaining / 60), remaining % 60)}`
			-- en compact le bouton Faille de la barre porte le compte à rebours
			riftStatusLabel.Visible = remaining > 0 and not compact
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
	if world.Worlds and world.Active then
		RenderWorldPicker(world.Worlds)
	elseif worldPicker then
		worldPicker.Visible = false
	end
	if world.Active then
		if riftCountdown then
			coroutine.close(riftCountdown)
			riftCountdown = nil
		end
		Audio.Play("RiftWhoosh")
		riftStatusLabel.Text = "Un parcours s'est ouvert ! Entre dans le portail."
		riftStatusLabel.Visible = not compact
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
	if payload.Quests and state then
		-- Le state local est périmé côté quêtes : fusionner avant refresh,
		-- sinon le bouton Réclamer reste affiché après un claim réussi.
		state.Quests = payload.Quests
		UpdateQuestBadge(payload.Quests)
		QuestsPanel.Refresh(state)
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

Net.ActionResult.OnClientEvent:Connect(function(result)
	if not result then
		return
	end
	if result.Success then
		if result.Action == "QuestClaim" then
			if state then
				QuestsPanel.Refresh(state)
			end
			Audio.Play("CoinReward")
			ShowAnnouncement(`Quête réclamée : +{result.Reward or 0} essence !`)
		elseif result.Action == "SkillBuy" then
			if state then
				SkillPanel.Refresh(state)
			end
			Audio.Play("UpgradeMagic")
			ShowAnnouncement("Talent acheté !")
		elseif result.Action == "TutorialComplete" then
			Audio.Play("CoinReward")
			ShowAnnouncement(`Tutoriel terminé : +{result.Reward or 0} essence !`)
		elseif result.Action == "BreedCreatures" then
			ShowAnnouncement("Élevage réussi !")
		elseif result.Action == "SecretHint" then
			ShowAnnouncement(`Indice de faille ({result.Found}/{result.Total}) : {result.Hint}`)
			Audio.Play("RareFanfare")
		elseif result.Action == "SecretRitual" then
			if result.AlreadyClaimed then
				ShowAnnouncement("Le rituel secret a déjà été accompli.")
			else
				ShowAnnouncement(`Rituel accompli : +{result.Reward or 0} Essence et titre « {result.Title} » !`)
				Audio.Play("RareFanfare")
				Flash(0.6)
			end
		elseif result.Action == "VipChest" then
			ShowAnnouncement(`Coffre VIP : +{result.Essence or 0} Essence, potion et {result.EggTier or "un oeuf"} !`)
			Audio.Play("CoinReward")
		elseif result.Action == "VipEgg" then
			ShowAnnouncement(`Oeuf VIP obtenu : {result.Tier or "LegendaryEgg"} !`)
		elseif result.Action == "SetTitle" then
			ShowAnnouncement(if result.Title then `Titre équipé : {result.Title}` else "Titre retiré.")
		end
	else
		if result.Action == "QuestClaim" and state then
			QuestsPanel.Refresh(state)
		elseif result.Action == "SkillBuy" and state then
			SkillPanel.Refresh(state)
		end
		ShowAnnouncement(result.Reason or "Action refusée")
	end
end)

ObjectiveBanner.Mount(ui)

-- ponytail: retry car un require qui échoue (sync rojo partielle au boot) reste en cache erreur
local function RequireWithRetry(module: ModuleScript)
	for _ = 1, 20 do
		local ok, result = pcall(require, module)
		if ok then
			return result
		end
		task.wait(0.5)
	end
	return nil
end

RequireWithRetry(script.Parent.CreatureDisplay)
local followController = RequireWithRetry(script.Parent.FollowController)
if followController then
	followController.Start()
end
local farmBehaviors = RequireWithRetry(script.Parent.FarmBehaviors)
if farmBehaviors then
	farmBehaviors.Start()
end

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
	topBar.Size = UDim2.fromOffset(if compact then 240 else 320, if compact then 76 else 84)
	settingsPanel.Size = UDim2.fromOffset(if compact then 300 else 340, 284)
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
	if compact then
		riftStatusLabel.Visible = false
	end
end

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(ApplyLayout)
ApplyLayout()

return nil
