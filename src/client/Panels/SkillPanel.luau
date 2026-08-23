local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiKit = require(script.Parent.Parent.UiKit)
local Net = require(ReplicatedStorage.Shared.Net)
local SkillTree = require(ReplicatedStorage.Shared.SkillTree)

local SkillPanel = {}

local pointsLabel
local nodeList

function SkillPanel.Create(parent)
	local frame = UiKit.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = parent,
	})
	UiKit.Padding(frame, 10)

	UiKit.Title(frame, "Arbre d'Étoiles")

	pointsLabel = UiKit.Create("TextLabel", {
		Name = "PointsLabel",
		BackgroundTransparency = 1,
		TextColor3 = UiKit.TINTS.ACCENT,
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.fromScale(1, 0.06),
		Text = "",
		Parent = frame,
	})

	nodeList = UiKit.Scroller(frame, UDim2.fromScale(0, 0.08), UDim2.fromScale(1, 0.92))
	nodeList.Name = "NodeList"
	return frame
end

function SkillPanel.Refresh(state)
	local points = state.SkillPoints or 0
	local ranks = state.SkillRanks or {}
	pointsLabel.Text = `Points d'étoile : {points}`

	UiKit.Clear(nodeList)
	for _, node in SkillTree.Nodes() do
		local rank = ranks[node.Id] or 0
		local maxed = rank >= node.MaxRank
		local row = UiKit.Cell(nodeList)
		UiKit.Create("TextLabel", {
			Name = "NodeLabel",
			BackgroundTransparency = 1,
			TextColor3 = if maxed then UiKit.TINTS.ACCENT else UiKit.TINTS.WHITE,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.fromScale(0.8, 1),
			Text = `[{node.Branch}] {node.Name} — {node.Desc} ({rank}/{node.MaxRank})`,
			Parent = row,
		})
		local buyButton = UiKit.Button(row, "+", UDim2.fromOffset(32, 32), UDim2.new(1, -34, 0.5, -16))
		buyButton.Name = "BuyButton"
		buyButton.Activated:Connect(function()
			Net.SkillBuy:FireServer(node.Id)
		end)
	end
end

return SkillPanel
