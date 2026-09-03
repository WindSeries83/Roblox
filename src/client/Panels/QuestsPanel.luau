local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiKit = require(script.Parent.Parent.UiKit)
local Net = require(ReplicatedStorage.Shared.Net)
local Config = require(ReplicatedStorage.Shared.Config)

local QuestsPanel = {}
local pendingClaims: { [string]: boolean } = {}

local TINTS = UiKit.TINTS

local function DailyInfo(quests)
	local rows = {}
	if not quests or not quests.Daily then
		return rows
	end
	for _, quest in quests.Daily do
		local def = Config.DAILY_QUESTS[quest.Id]
		if def then
			table.insert(rows, {
				Type = "Daily",
				Id = quest.Id,
				Name = def.Name,
				Desc = def.Desc:gsub("{target}", tostring(def.Target)),
				Progress = quest.Progress,
				Target = def.Target,
				Reward = def.Reward,
				Claimed = quest.Claimed,
			})
		end
	end
	return rows
end

local function AchievementInfo(quests)
	local rows = {}
	if not quests or not quests.Achievements then
		return rows
	end
	for id, def in Config.ACHIEVEMENTS do
		table.insert(rows, {
			Id = id,
			Name = def.Name,
			Desc = def.Desc,
			Reward = def.Reward,
			Unlocked = quests.Achievements[id] == true,
		})
	end
	return rows
end

local function AddQuestRow(parent: Instance, row, onClaim: (string) -> ())
	local cell = UiKit.Cell(parent)
	cell.Name = `QuestRow_{row.Id}`

	-- Badge récompense : chip en haut à droite de la card, hors du flux du header.
	local rewardBadge = UiKit.Create("Frame", {
		Name = "RewardBadge",
		BackgroundColor3 = TINTS.DARK,
		Position = UDim2.new(1, -4, 0, 4),
		AnchorPoint = Vector2.new(1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 22),
		Parent = cell,
	})
	local rewardCorner = Instance.new("UICorner")
	rewardCorner.CornerRadius = UDim.new(0, 6)
	rewardCorner.Parent = rewardBadge
	local rewardPad = Instance.new("UIPadding")
	rewardPad.PaddingLeft = UDim.new(0, 4)
	rewardPad.PaddingRight = UDim.new(0, 4)
	rewardPad.PaddingTop = UDim.new(0, 4)
	rewardPad.PaddingBottom = UDim.new(0, 4)
	rewardPad.Parent = rewardBadge
	UiKit.Create("TextLabel", {
		BackgroundTransparency = 1,
		TextColor3 = TINTS.ACCENT,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.fromScale(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		Text = `+{row.Reward}`,
		Parent = rewardBadge,
	})

	local header = UiKit.Create("Frame", {
		Name = "Header",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 38),
		Parent = cell,
	})
	UiKit.Create("TextLabel", {
		BackgroundTransparency = 1,
		TextColor3 = if row.Claimed then TINTS.GREEN else TINTS.WHITE,
		Font = Enum.Font.GothamBold,
		TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.fromScale(1, 1),
		Text = row.Name,
		Parent = header,
	})

	UiKit.Create("TextLabel", {
		Name = "Desc",
		BackgroundTransparency = 1,
		TextColor3 = TINTS.WHITE,
		TextSize = 14,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.fromOffset(0, 40),
		Size = UDim2.new(1, 0, 0, 20),
		Text = row.Desc,
		Parent = cell,
	})

	if row.Claimed then
		UiKit.Create("TextLabel", {
			BackgroundTransparency = 1,
			TextColor3 = TINTS.GREEN,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			Position = UDim2.fromOffset(0, 64),
			Size = UDim2.new(1, 0, 0, 20),
			Text = "Récompense réclamée",
			Parent = cell,
		})
	elseif row.Progress >= row.Target then
		local claim = UiKit.Button(cell, "Réclamer", UDim2.fromOffset(110, 32), UDim2.new(0.5, 0, 0, 66))
		claim.Name = `Claim_{row.Id}`
		claim.AnchorPoint = Vector2.new(0.5, 0)
		claim.TextSize = 13
		claim.Activated:Connect(function()
			if pendingClaims[row.Id] then
				return
			end
			pendingClaims[row.Id] = true
			claim.Active = false
			onClaim(row.Id)
		end)
	else
		-- Barre pleine largeur avec la progression superposée au remplissage.
		local ratio = math.clamp(row.Progress / row.Target, 0, 1)
		local bar = UiKit.Create("Frame", {
			Name = "ProgressBar",
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.5,
			Position = UDim2.fromOffset(0, 64),
			Size = UDim2.new(1, 0, 0, 18),
			Parent = cell,
		})
		UiKit.Corner(bar)
		local fill = UiKit.Create("Frame", {
			Name = "Fill",
			BackgroundColor3 = TINTS.ACCENT,
			Size = UDim2.fromScale(ratio, 1),
			Parent = bar,
		})
		UiKit.Corner(fill)
		UiKit.Create("TextLabel", {
			BackgroundTransparency = 1,
			TextColor3 = TINTS.WHITE,
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			ZIndex = 2,
			Size = UDim2.fromScale(1, 1),
			Text = `{math.floor(row.Progress)} / {row.Target}`,
			Parent = bar,
		})
	end
end

local LOCK_GRAY = Color3.fromRGB(130, 130, 140)

-- Succès : card compacte en grille (icône, nom, desc, récompense).
local function AddAchievementCard(parent: Instance, row)
	local card = UiKit.Card(parent, UDim2.new(0.5, -6, 0, 84))
	card.Name = `Achievement_{row.Id}`
	local unlocked = row.Unlocked == true
	UiKit.Create("TextLabel", {
		Name = "Icon",
		BackgroundTransparency = 1,
		TextColor3 = if unlocked then TINTS.GREEN else LOCK_GRAY,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.fromOffset(24, 20),
		Text = if unlocked then "✓" else "🔒",
		Parent = card,
	})
	UiKit.Create("TextLabel", {
		Name = "Name",
		BackgroundTransparency = 1,
		TextColor3 = if unlocked then TINTS.GREEN else TINTS.WHITE,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromOffset(26, 1),
		Size = UDim2.new(1, -26, 0, 18),
		Text = row.Name,
		Parent = card,
	})
	UiKit.Create("TextLabel", {
		Name = "Desc",
		BackgroundTransparency = 1,
		TextColor3 = TINTS.WHITE,
		TextSize = 11,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.fromOffset(0, 24),
		Size = UDim2.new(1, 0, 0, 28),
		Text = row.Desc,
		Parent = card,
	})
	UiKit.Create("TextLabel", {
		Name = "Reward",
		BackgroundTransparency = 1,
		TextColor3 = TINTS.ACCENT,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 14),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = `+{row.Reward}`,
		Parent = card,
	})
end

function QuestsPanel.Create(parent: Instance): Frame
	local panel = UiKit.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = parent,
	})

	local dailyPage = UiKit.Scroller(panel, UDim2.fromScale(0, 0.08), UDim2.new(1, 0, 0.92, -6))
	dailyPage.Name = "DailyPage"
	local achievementPage = UiKit.Scroller(panel, UDim2.fromScale(0, 0.08), UDim2.new(1, 0, 0.92, -6))
	achievementPage.Name = "AchievementPage"
	-- Succès : grille 2 colonnes de cards à la place de la liste dense.
	for _, child in achievementPage:GetChildren() do
		if child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
	UiKit.Create("UIGridLayout", {
		Name = "AchievementGrid",
		CellSize = UDim2.new(0.5, -6, 0, 84),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = achievementPage,
	})
	local guidePage = UiKit.Scroller(panel, UDim2.fromScale(0, 0.08), UDim2.new(1, 0, 0.92, -6))
	guidePage.Name = "GuidePage"

	UiKit.SubTabs(panel, 34, {
		{ Name = "Quotidiennes", Page = dailyPage },
		{ Name = "Succès", Page = achievementPage },
		{ Name = "Guide", Page = guidePage },
	})

	local function BuildGuide()
		UiKit.Clear(guidePage)
		-- Puces un peu plus aérées que le défaut du Scroller.
		for _, child in guidePage:GetChildren() do
			if child:IsA("UIListLayout") then
				child.Padding = UDim.new(0, 10)
			end
		end
		local lines = {
			"1. Achète des œufs et éclos-les : tu obtiens des créatures.",
			"2. Tes créatures produisent de l'essence automatiquement.",
			"3. Améliore ton sanctuaire pour en garder plus.",
			"4. Croise deux créatures pour en obtenir une nouvelle.",
			"5. Nourris tes créatures pour les faire évoluer.",
			"6. Affronte le gardien de la faille : il entre dans le portail quand une faille s'ouvre.",
			"7. Découvre des espèces pour remplir ton index.",
			"8. La renaissance te redonne tout... avec plus de pouvoir.",
			"Les quêtes quotidiennes changent chaque jour. Réclame tes récompenses !",
		}
		for _, line in lines do
			local cell = UiKit.Cell(guidePage)
			UiKit.Create("TextLabel", {
				BackgroundTransparency = 1,
				RichText = true,
				TextColor3 = TINTS.WHITE,
				TextSize = 14,
				TextWrapped = true,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 18),
				Text = `<font color="#8C3CFF">●</font> {line}`,
				Parent = cell,
			})
		end
	end
	BuildGuide()

	local function Refresh(payload)
		pendingClaims = {}
		local quests = payload and (payload.Quests or payload) or nil
		UiKit.Clear(dailyPage)
		UiKit.Clear(achievementPage)
		for _, row in DailyInfo(quests) do
			AddQuestRow(dailyPage, row, function(questId)
				Net.QuestClaim:FireServer(questId)
			end)
		end
		for _, row in AchievementInfo(quests) do
			AddAchievementCard(achievementPage, row)
		end
	end

	QuestsPanel.Refresh = Refresh
	return panel
end

return QuestsPanel
