local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiKit = require(script.Parent.Parent.UiKit)
local Audio = require(script.Parent.Parent.Audio)
local Net = require(ReplicatedStorage.Shared.Net)
local Config = require(ReplicatedStorage.Shared.Config)

local QuestsPanel = {}

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
				Desc = def.Desc,
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
			Type = "Achievement",
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

	local header = UiKit.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 30),
		Parent = cell,
	})
	UiKit.Create("TextLabel", {
		BackgroundTransparency = 1,
		TextColor3 = if row.Claimed or row.Unlocked then TINTS.GREEN else TINTS.WHITE,
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.fromScale(0.7, 1),
		Text = row.Name,
		Parent = header,
	})
	UiKit.Create("TextLabel", {
		BackgroundTransparency = 1,
		TextColor3 = TINTS.ACCENT,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Right,
		Size = UDim2.fromScale(0.3, 1),
		Text = `+{row.Reward}`,
		Parent = header,
	})

	UiKit.Create("TextLabel", {
		BackgroundTransparency = 1,
		TextColor3 = TINTS.WHITE,
		TextSize = 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 18),
		Text = row.Desc,
		Parent = cell,
	})

	if row.Type == "Daily" then
		local done = row.Progress >= row.Target
		if row.Claimed then
			UiKit.Create("TextLabel", {
				BackgroundTransparency = 1,
				TextColor3 = TINTS.GREEN,
				Font = Enum.Font.GothamBold,
				TextSize = 13,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 20),
				Text = "Récompense réclamée",
				Parent = cell,
			})
		elseif done then
			local claim = UiKit.Button(cell, "Réclamer", UDim2.fromOffset(110, 32), UDim2.fromScale(0, 1))
			claim.Name = "ClaimButton"
			claim.Position = UDim2.fromScale(0.5, 0)
			claim.AnchorPoint = Vector2.new(0.5, 0)
			claim.TextSize = 13
			claim.Activated:Connect(function()
				Audio.Play("CoinReward")
				onClaim(row.Id)
			end)
		else
			local label, fill = UiKit.Bar(cell, TINTS.ACCENT)
			label.Visible = false
			fill.Parent.BackgroundTransparency = 1
			fill.Position = UDim2.fromScale(0, 1)
			local ratio = math.clamp(row.Progress / row.Target, 0, 1)
			fill.Size = UDim2.new(ratio, 0, 0, 14)
			UiKit.Create("TextLabel", {
				BackgroundTransparency = 1,
				TextColor3 = TINTS.WHITE,
				Font = Enum.Font.GothamBold,
				TextSize = 12,
				Size = UDim2.new(1, 0, 0, 14),
				Position = UDim2.fromScale(0, 1),
				Text = `{math.floor(row.Progress)} / {row.Target}`,
				Parent = cell,
			})
		end
	else
		local status = if row.Unlocked then "Débloqué" else "À découvrir"
		UiKit.Create("TextLabel", {
			BackgroundTransparency = 1,
			TextColor3 = if row.Unlocked then TINTS.GREEN else TINTS.WHITE,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			Size = UDim2.new(1, 0, 0, 20),
			Text = status,
			Parent = cell,
		})
	end
end

function QuestsPanel.Create(parent: Instance): Frame
	local panel = UiKit.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = parent,
	})

	local subBar = UiKit.Create("Frame", {
		Name = "SubBar",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 34),
		Parent = panel,
	})
	local subTabs = {}
	local function AddSubTab(index: number, name: string, page: Instance)
		local button = UiKit.Create("TextButton", {
			Name = `SubTab{index}`,
			BackgroundColor3 = TINTS.DARK,
			TextColor3 = TINTS.WHITE,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			Size = UDim2.new(0.33, -4, 1, 0),
			Position = UDim2.new(0.33 * (index - 1), 2, 0, 0),
			Text = name,
			Parent = subBar,
		})
		UiKit.Corner(button)
		button.Activated:Connect(function()
			for _, tab in subTabs do
				tab.button.BackgroundColor3 = TINTS.DARK
				tab.page.Visible = false
			end
			button.BackgroundColor3 = TINTS.PANEL
			page.Visible = true
		end)
		table.insert(subTabs, { button = button, page = page })
	end

	local dailyPage = UiKit.Scroller(panel, UDim2.fromScale(0, 0.08), UDim2.new(1, 0, 0.92, -6))
	dailyPage.Name = "DailyPage"
	local achievementPage = UiKit.Scroller(panel, UDim2.fromScale(0, 0.08), UDim2.new(1, 0, 0.92, -6))
	achievementPage.Name = "AchievementPage"
	local guidePage = UiKit.Scroller(panel, UDim2.fromScale(0, 0.08), UDim2.new(1, 0, 0.92, -6))
	guidePage.Name = "GuidePage"

	AddSubTab(1, "Quotidiennes", dailyPage)
	AddSubTab(2, "Succès", achievementPage)
	AddSubTab(3, "Guide", guidePage)
	dailyPage.Visible = true
	achievementPage.Visible = false
	guidePage.Visible = false
	subTabs[1].button.BackgroundColor3 = TINTS.PANEL

	local function BuildGuide()
		UiKit.Clear(guidePage)
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
				TextColor3 = TINTS.WHITE,
				TextSize = 13,
				TextWrapped = true,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 18),
				Text = line,
				Parent = cell,
			})
		end
	end
	BuildGuide()

	local function Refresh(payload)
		local quests = payload and (payload.Quests or payload) or nil
		UiKit.Clear(dailyPage)
		UiKit.Clear(achievementPage)
		for _, row in DailyInfo(quests) do
			AddQuestRow(dailyPage, row, function(questId)
				Net.QuestClaim:FireServer(questId)
			end)
		end
		for _, row in AchievementInfo(quests) do
			AddQuestRow(achievementPage, row)
		end
	end

	QuestsPanel.Refresh = Refresh
	return panel
end

return QuestsPanel
