local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Net = require(ReplicatedStorage.Shared.Net)
local Config = require(ReplicatedStorage.Shared.Config)
local Species = require(ReplicatedStorage.Shared.Data.Species)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TINTS = {
	DARK = Color3.fromRGB(20, 20, 26),
	PANEL = Color3.fromRGB(30, 30, 40),
	ACCENT = Color3.fromRGB(140, 60, 255),
	WHITE = Color3.fromRGB(235, 235, 245),
	RED = Color3.fromRGB(220, 60, 60),
	GREEN = Color3.fromRGB(70, 190, 100),
}

local TIER_NAMES = {
	CommonEgg = "Œuf commun",
	UncommonEgg = "Œuf peu commun",
	RareEgg = "Œuf rare",
}

local function Create(className: string, props: { [string]: any }): Instance
	local inst = Instance.new(className)
	for key, value in props do
		inst[key] = value
	end
	return inst
end

local function Corner(inst: GuiObject)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = inst
end

local function Padding(inst: Instance, amount: number)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, amount)
	pad.PaddingRight = UDim.new(0, amount)
	pad.PaddingTop = UDim.new(0, amount)
	pad.PaddingBottom = UDim.new(0, amount)
	pad.Parent = inst
end

local function Bar(parent: Instance, color: Color3): TextLabel
	local bg = Create("Frame", {
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.5,
		Size = UDim2.fromScale(1, 0.3),
		Parent = parent,
	})
	Corner(bg)
	local fill = Create("Frame", {
		BackgroundColor3 = color,
		Size = UDim2.fromScale(1, 1),
		Parent = bg,
	})
	Corner(fill)
	local label = Create("TextLabel", {
		BackgroundTransparency = 1,
		TextColor3 = TINTS.WHITE,
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		Parent = bg,
	})
	return label, fill
end

local ui = Create("ScreenGui", {
	Name = "RiftBeastsUi",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	Parent = playerGui,
})

local topBar = Create("Frame", {
	BackgroundColor3 = TINTS.PANEL,
	Size = UDim2.fromOffset(260, 64),
	Position = UDim2.fromOffset(12, 12),
	Parent = ui,
})
Corner(topBar)
Padding(topBar, 12)

local essenceLabel = Create("TextLabel", {
	BackgroundTransparency = 1,
	TextColor3 = TINTS.ACCENT,
	Font = Enum.Font.GothamBold,
	TextSize = 24,
	TextXAlignment = Enum.TextXAlignment.Left,
	Size = UDim2.fromScale(1, 0.55),
	Text = "Essence : 0",
	Parent = topBar,
})

local rateLabel = Create("TextLabel", {
	BackgroundTransparency = 1,
	TextColor3 = TINTS.WHITE,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0, 0.55),
	Size = UDim2.fromScale(1, 0.45),
	Text = "Rendement : 0 / s",
	Parent = topBar,
})

local creaturePanel = Create("Frame", {
	BackgroundColor3 = TINTS.PANEL,
	Size = UDim2.fromOffset(320, 300),
	Position = UDim2.fromScale(1, 0.5),
	AnchorPoint = Vector2.new(1, 0.5),
	Parent = ui,
})
Corner(creaturePanel)
Padding(creaturePanel, 10)

Create("TextLabel", {
	BackgroundTransparency = 1,
	TextColor3 = TINTS.WHITE,
	Font = Enum.Font.GothamBold,
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Left,
	Size = UDim2.fromScale(1, 0.1),
	Text = "Créatures",
	Parent = creaturePanel,
})

local creatureList = Create("ScrollingFrame", {
	BackgroundTransparency = 1,
	ScrollBarThickness = 4,
	CanvasSize = UDim2.fromScale(0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Position = UDim2.fromScale(0, 0.12),
	Size = UDim2.fromScale(1, 0.88),
	Parent = creaturePanel,
})

Create("UIListLayout", {
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = creatureList,
})

local eggPanel = Create("Frame", {
	BackgroundColor3 = TINTS.PANEL,
	Size = UDim2.fromOffset(380, 240),
	Position = UDim2.fromOffset(12, 84),
	Parent = ui,
})
Corner(eggPanel)
Padding(eggPanel, 10)

Create("TextLabel", {
	BackgroundTransparency = 1,
	TextColor3 = TINTS.WHITE,
	Font = Enum.Font.GothamBold,
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Left,
	Size = UDim2.fromScale(1, 0.14),
	Text = "Œufs",
	Parent = eggPanel,
})

local shopRow = Create("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.fromScale(0, 0.16),
	Size = UDim2.fromScale(1, 0.2),
	Parent = eggPanel,
})

Create("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 6),
	Parent = shopRow,
})

local eggList = Create("ScrollingFrame", {
	BackgroundTransparency = 1,
	ScrollBarThickness = 4,
	CanvasSize = UDim2.fromScale(0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Position = UDim2.fromScale(0, 0.4),
	Size = UDim2.fromScale(1, 0.6),
	Parent = eggPanel,
})

Create("UIListLayout", {
	Padding = UDim.new(0, 4),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = eggList,
})

local riftHud = Create("Frame", {
	BackgroundColor3 = TINTS.PANEL,
	Size = UDim2.fromOffset(420, 190),
	Position = UDim2.fromScale(0.5, 1),
	AnchorPoint = Vector2.new(0.5, 1),
	Visible = false,
	Parent = ui,
})
Corner(riftHud)
Padding(riftHud, 12)

Create("TextLabel", {
	BackgroundTransparency = 1,
	TextColor3 = TINTS.ACCENT,
	Font = Enum.Font.GothamBold,
	TextSize = 20,
	Size = UDim2.fromScale(1, 0.16),
	Text = "Faille",
	Parent = riftHud,
})

local guardianLabel, guardianFill = Bar(riftHud, TINTS.RED)
guardianLabel.Position = UDim2.fromScale(0, 0.2)
guardianLabel.Size = UDim2.fromScale(1, 0.12)
guardianLabel.Parent = riftHud

local playerHpLabel, playerHpFill = Bar(riftHud, TINTS.GREEN)
playerHpLabel.Position = UDim2.fromScale(0, 0.36)
playerHpLabel.Size = UDim2.fromScale(1, 0.12)
playerHpLabel.Parent = riftHud

local attackButton = Create("TextButton", {
	BackgroundColor3 = TINTS.ACCENT,
	TextColor3 = TINTS.WHITE,
	Font = Enum.Font.GothamBold,
	TextSize = 18,
	Size = UDim2.fromScale(1, 0.2),
	Position = UDim2.fromScale(0, 0.55),
	Text = "Attaquer",
	Parent = riftHud,
})
Corner(attackButton)

local riftHint = Create("TextLabel", {
	BackgroundTransparency = 1,
	TextColor3 = TINTS.WHITE,
	TextSize = 14,
	Position = UDim2.fromScale(0, 0.78),
	Size = UDim2.fromScale(1, 0.2),
	Text = "",
	Parent = riftHud,
})

local announcement = Create("Frame", {
	BackgroundColor3 = TINTS.PANEL,
	Size = UDim2.fromOffset(520, 56),
	Position = UDim2.fromScale(0.5, 0.06),
	AnchorPoint = Vector2.new(0.5, 0),
	Visible = false,
	ZIndex = 10,
	Parent = ui,
})
Corner(announcement)

local announcementLabel = Create("TextLabel", {
	BackgroundTransparency = 1,
	TextColor3 = TINTS.WHITE,
	Font = Enum.Font.GothamBold,
	TextSize = 18,
	Size = UDim2.fromScale(1, 1),
	Text = "",
	ZIndex = 10,
	Parent = announcement,
})

local flashOverlay = Create("Frame", {
	BackgroundColor3 = TINTS.WHITE,
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	ZIndex = 100,
	Parent = ui,
})

local reveal = Create("Frame", {
	BackgroundColor3 = TINTS.PANEL,
	Size = UDim2.fromOffset(420, 150),
	Position = UDim2.fromScale(0.5, 0.4),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Visible = false,
	ZIndex = 20,
	Parent = ui,
})
Corner(reveal)

local revealLabel = Create("TextLabel", {
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

local revealButton = Create("TextButton", {
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
Corner(revealButton)

local riftStatusLabel = Create("TextLabel", {
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
Corner(riftStatusLabel)

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

local function SetBar(fill: Frame, label: TextLabel, value: number, max: number)
	local ratio = math.clamp(value / max, 0, 1)
	fill.Size = UDim2.fromScale(ratio, 1)
	label.Text = `{math.max(0, math.floor(value))} / {math.floor(max)}`
end

local function RenderCreatures(creatures)
	for _, child in creatureList:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	for _, creature in creatures do
		local row = Create("Frame", {
			BackgroundColor3 = TINTS.DARK,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = creatureList,
		})
		Corner(row)
		Padding(row, 8)
		local speciesName = Species[creature.SpeciesId] and Species[creature.SpeciesId].Name or creature.SpeciesId
		local label = Create("TextLabel", {
			BackgroundTransparency = 1,
			TextColor3 = TINTS.WHITE,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextWrapped = true,
			Text = `{speciesName} — Niv. {creature.Level} — Puissance {creature.Power}`,
			Parent = row,
		})
		local rarity = string.upper(creature.Rarity)
		label.Text = `[{rarity}] {label.Text}`
	end
end

local function RenderEggs(eggs)
	for _, child in eggList:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	for _, egg in eggs do
		local row = Create("Frame", {
			BackgroundColor3 = TINTS.DARK,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = eggList,
		})
		Corner(row)
		Padding(row, 8)
		Create("TextLabel", {
			BackgroundTransparency = 1,
			TextColor3 = TINTS.WHITE,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.fromScale(1, 0.4),
			Text = TIER_NAMES[egg.Tier] or egg.Tier,
			Parent = row,
		})
		local button = Create("TextButton", {
			BackgroundColor3 = TINTS.ACCENT,
			TextColor3 = TINTS.WHITE,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			Position = UDim2.fromScale(0.55, 0),
			Size = UDim2.fromScale(0.45, 0.4),
			Text = "Éclore",
			Parent = row,
		})
		Corner(button)
		button.Activated:Connect(function()
			Net.HatchEgg:FireServer(egg.Id)
		end)
	end
end

local function RenderShop(prices)
	for _, child in shopRow:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local tierOrder = { "CommonEgg", "UncommonEgg", "RareEgg" }
	for _, tier in tierOrder do
		local price = prices[tier]
		if not price then
			continue
		end
		local button = Create("TextButton", {
			BackgroundColor3 = TINTS.DARK,
			TextColor3 = TINTS.WHITE,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			Size = UDim2.fromScale(1 / 3, 1),
			LayoutOrder = 1,
			Text = `{TIER_NAMES[tier]}\n{price} Essence`,
			TextWrapped = true,
			Parent = shopRow,
		})
		Corner(button)
		button.Activated:Connect(function()
			Net.BuyEgg:FireServer(tier)
		end)
	end
end

local function ShowRiftSync(state)
	if not state.InRift then
		riftHud.Visible = false
		return
	end
	riftHud.Visible = true
	SetBar(guardianFill, guardianLabel, state.GuardianHP, state.GuardianMaxHP)
	SetBar(playerHpFill, playerHpLabel, state.PlayerHP, state.PlayerMaxHP)
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
		ShowAnnouncement(
			`Faille terminée : +{result.Essence} Essence et {TIER_NAMES[result.EggTier] or result.EggTier}`
		)
		Flash(0.35)
	else
		ShowAnnouncement("Défaite face au gardien. Tes créatures n'étaient pas prêtes.")
	end
end

attackButton.Activated:Connect(function()
	Net.RiftAttack:FireServer()
end)

revealButton.Activated:Connect(function()
	reveal.Visible = false
end)

Net.Sync.OnClientEvent:Connect(function(state)
	essenceLabel.Text = `Essence : {state.Essence}`
	rateLabel.Text = `Rendement : {string.format("%.1f", state.Rate)} / s`
	RenderCreatures(state.Creatures)
	RenderEggs(state.Eggs)
end)

Net.HatchResult.OnClientEvent:Connect(function(result)
	local mutationText = result.MutationName and ` {result.MutationName}` or ""
	revealLabel.Text = `Tu as obtenu {result.SpeciesName} !\n{result.RarityName}{mutationText}`
	revealLabel.TextColor3 = result.RarityColor
	reveal.Visible = true
	if result.Announced then
		Flash(0.7)
	end
end)

Net.RareDrop.OnClientEvent:Connect(function(payload)
	local mutationText = payload.MutationName and ` {payload.MutationName}` or ""
	ShowAnnouncement(`{payload.PlayerName} a obtenu {payload.SpeciesName} ({payload.RarityName}{mutationText}) !`)
end)

Net.RiftSync.OnClientEvent:Connect(ShowRiftSync)

Net.RiftEnded.OnClientEvent:Connect(ShowRiftEnded)

Net.RiftWorld.OnClientEvent:Connect(function(state)
	if state.Active then
		riftStatusLabel.Text = "Une faille s'est ouverte ! Entre dans le portail."
		riftStatusLabel.Visible = true
	else
		riftStatusLabel.Visible = false
	end
end)

RenderShop(Config.EGG_PRICES)

return nil
