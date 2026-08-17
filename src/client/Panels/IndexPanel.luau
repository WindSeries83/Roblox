local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiKit = require(script.Parent.Parent.UiKit)
local Species = require(ReplicatedStorage.Shared.Data.Species)
local Index = require(ReplicatedStorage.Shared.Index)

local IndexPanel = {}

local entryList
local summaryLabel

local function ParseKey(key)
	local speciesId, rarity, mutation = key:match("^([^|]+)|([^|]+)|(.+)$")
	return speciesId, rarity, mutation
end

function IndexPanel.Create(parent)
	local frame = UiKit.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = parent,
	})
	UiKit.Padding(frame, 10)

	UiKit.Title(frame, "Index")

	summaryLabel = UiKit.Create("TextLabel", {
		Name = "SummaryLabel",
		BackgroundTransparency = 1,
		TextColor3 = UiKit.TINTS.ACCENT,
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.fromScale(1, 0.06),
		Text = "",
		Parent = frame,
	})

	entryList = UiKit.Scroller(frame, UDim2.fromScale(0, 0.08), UDim2.fromScale(1, 0.92))
	entryList.Name = "EntryList"
	return frame
end

function IndexPanel.Refresh(state)
	local mult = Index.ComputeMult(state.Index)
	local count = 0
	for _ in state.Index do
		count += 1
	end
	summaryLabel.Text = `{count} découvertes — Bonus rendement : +{math.floor((mult - 1) * 100)}%`

	UiKit.Clear(entryList)
	local keys = {}
	for key in state.Index do
		table.insert(keys, key)
	end
	table.sort(keys)
	for _, key in keys do
		local speciesId, rarity, mutation = ParseKey(key)
		local species = Species[speciesId]
		local name = species and species.Name or speciesId
		local mutationName = mutation ~= "false" and mutation or "sans mutation"
		local row = UiKit.Cell(entryList)
		UiKit.Create("TextLabel", {
			BackgroundTransparency = 1,
			TextColor3 = UiKit.TINTS.WHITE,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = `{name} — {rarity} — {mutationName}`,
			Parent = row,
		})
	end

	local families = Index.FamilyCompletions(state.Index)
	local done = ""
	for family in families do
		done ..= `{family} complétée !\n`
	end
	summaryLabel.Text ..= done
end

return IndexPanel
