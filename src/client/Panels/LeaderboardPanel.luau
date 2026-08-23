local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiKit = require(script.Parent.Parent.UiKit)
local Net = require(ReplicatedStorage.Shared.Net)
local Rarities = require(ReplicatedStorage.Shared.Data.Rarities)
local Species = require(ReplicatedStorage.Shared.Data.Species)

local LeaderboardPanel = {}

local TINTS = UiKit.TINTS

local page
local detailFrame

local function RarityName(rarity: string): string
	local def = Rarities[rarity]
	return def and def.Name or rarity
end

local function SpeciesName(speciesId: string): string
	local def = Species[speciesId]
	return def and def.Name or speciesId
end

local function ShowDetail(payload)
	UiKit.Clear(detailFrame)
	if not payload then
		UiKit.Title(detailFrame, "Clique sur un joueur pour visiter son sanctuaire.")
		return
	end
	UiKit.Title(detailFrame, `Sanctuaire de {payload.Name}`)
	UiKit.Title(detailFrame, `Niveau {payload.SanctuaryLevel} — {payload.Essence} Essence gagnée`, 14)
	UiKit.Title(detailFrame, "Créatures par rang", 14)
	for rarity, count in payload.Ranks do
		local def = Rarities[rarity]
		UiKit.Create("TextLabel", {
			BackgroundTransparency = 1,
			TextColor3 = def and def.Color or TINTS.WHITE,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 18),
			Text = `{RarityName(rarity)} : {count}`,
			Parent = detailFrame,
		})
	end
	UiKit.Title(detailFrame, "Espèces phares", 14)
	for _, species in payload.Species do
		UiKit.Create("TextLabel", {
			BackgroundTransparency = 1,
			TextColor3 = TINTS.WHITE,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 18),
			Text = `{SpeciesName(species.Id)} ×{species.Count}`,
			Parent = detailFrame,
		})
	end
end

function LeaderboardPanel.Create(parent: Instance): Frame
	local panel = UiKit.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = parent,
	})

	page = UiKit.Scroller(panel, UDim2.fromOffset(0, 0), UDim2.fromScale(0.58, 1))
	page.Name = "LeaderboardPage"
	UiKit.Title(page, "Classement (Essence totale)")

	detailFrame = UiKit.Create("Frame", {
		Name = "SanctuaryDetail",
		BackgroundColor3 = TINTS.PANEL,
		Position = UDim2.fromScale(0.6, 0),
		Size = UDim2.fromScale(0.4, 1),
		Parent = panel,
	})
	UiKit.Corner(detailFrame)
	UiKit.Padding(detailFrame, 10)
	UiKit.Create("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = detailFrame,
	})
	ShowDetail(nil)

	Net.LeaderboardDetail.OnClientEvent:Connect(ShowDetail)

	Net.LeaderboardSync.OnClientEvent:Connect(function(payload)
		UiKit.Clear(page)
		UiKit.Title(page, "Classement (Essence totale)")
		for _, entry in payload.Entries do
			local cell = UiKit.Cell(page)
			UiKit.Create("TextLabel", {
				BackgroundTransparency = 1,
				TextColor3 = if entry.Rank <= 3 then TINTS.ACCENT else TINTS.WHITE,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Size = UDim2.fromScale(0.66, 1),
				Text = `#{entry.Rank} {entry.Name} — {entry.Essence} Essence — Sanctuaire niv. {entry.SanctuaryLevel}`,
				TextWrapped = true,
				Parent = cell,
			})
			local button = UiKit.Button(cell, "Visiter", UDim2.new(0.3, 0, 0, 26), UDim2.new(0.68, 0, 0.5, -13))
			button.BackgroundColor3 = TINTS.DARK
			button.Activated:Connect(function()
				Net.LeaderboardVisit:FireServer(entry.UserId)
			end)
		end
	end)

	task.spawn(function()
		task.wait(1)
		Net.LeaderboardRequest:FireServer()
	end)

	return panel
end

return LeaderboardPanel
