local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiKit = require(script.Parent.Parent.UiKit)
local Net = require(ReplicatedStorage.Shared.Net)
local SkillTree = require(ReplicatedStorage.Shared.SkillTree)

-- Liste linéaire (retour playtest 25/08) : les talents se suivent dans l'ordre
-- de déblocage. Chaque ligne montre sans ambiguïté verrouillé / achetable /
-- possédé / au maximum — pas de graphe, ça se lit de haut en bas.
local SkillPanel = {}

local COLOR_LOCKED = Color3.fromRGB(45, 45, 58)
local COLOR_LOCKED_TEXT = Color3.fromRGB(120, 120, 135)
local COLOR_MAX = Color3.fromRGB(255, 215, 94)

local pointsLabel
local list
local pendingBuys: { [string]: boolean } = {}

-- Profondeur de dépendance : les racines d'abord, chaque palier après ses prerequis.
local depthCache: { [string]: number } = {}
local function depthOf(node): number
	local cached = depthCache[node.Id]
	if cached then
		return cached
	end
	local max = 0
	for _, reqId in SkillTree.Requires(node) do
		local req = SkillTree.Node(reqId)
		if req then
			max = math.max(max, depthOf(req) + 1)
		end
	end
	depthCache[node.Id] = max
	return max
end

local function sortedNodes()
	local nodes = table.clone(SkillTree.Nodes())
	table.sort(nodes, function(a, b)
		local da, db = depthOf(a), depthOf(b)
		if da ~= db then
			return da < db
		end
		if a.Branch ~= b.Branch then
			return a.Branch < b.Branch
		end
		return (a.Row or 0) < (b.Row or 0)
	end)
	return nodes
end

local function effectText(node, rank: number): string
	if typeof(node.Value) ~= "number" or rank <= 0 or node.Effect == "SecretOmen" then
		return ""
	end
	return ` · +{string.format("%g", node.Value * rank * 100)} %`
end

local function AddSkillRow(parent, node, ranks: { [string]: number }, points: number, order: number)
	local rank = SkillTree.Rank(ranks, node.Id)
	local maxed = rank >= node.MaxRank
	local locked = false
	local prereqName = nil
	for _, reqId in SkillTree.Requires(node) do
		if SkillTree.Rank(ranks, reqId) < 1 then
			locked = true
			local req = SkillTree.Node(reqId)
			prereqName = req and req.Name or reqId
			break
		end
	end
	local ok, reason = SkillTree.CanBuy(points, ranks, node.Id)

	local cell = UiKit.Cell(parent)
	cell.Name = `Skill_{node.Id}`
	cell.LayoutOrder = order
	cell.Size = UDim2.new(1, -8, 0, 64)

	-- Pastille d'état : ★ max / 🔒 verrouillé / ●● possédé / + achetable
	local circle = UiKit.Create("Frame", {
		Name = "State",
		BackgroundColor3 = if maxed
			then COLOR_MAX
			elseif locked then COLOR_LOCKED
			elseif rank > 0 then Color3.fromRGB(70, 70, 90)
			else UiKit.TINTS.ACCENT,
		Size = UDim2.fromOffset(36, 36),
		Position = UDim2.fromOffset(4, 14),
		Parent = cell,
	})
	UiKit.Corner(circle)
	UiKit.Create("TextLabel", {
		Name = "StateGlyph",
		BackgroundTransparency = 1,
		TextColor3 = if locked then COLOR_LOCKED_TEXT else UiKit.TINTS.DARK,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		Size = UDim2.fromScale(1, 1),
		Text = if maxed
			then "★"
			elseif locked then "🔒"
			elseif rank > 0 then string.rep("●", math.min(rank, 3))
			else "+",
		Parent = circle,
	})

	-- Nom + branche, puis description avec l'effet du rang actuel.
	UiKit.Create("TextLabel", {
		Name = "Name",
		BackgroundTransparency = 1,
		TextColor3 = if locked then COLOR_LOCKED_TEXT else UiKit.TINTS.WHITE,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(50, 7),
		Size = UDim2.new(1, -220, 0, 18),
		Text = `{node.Name}  ·  {node.Branch}`,
		Parent = cell,
	})
	UiKit.Create("TextLabel", {
		Name = "Desc",
		BackgroundTransparency = 1,
		TextColor3 = UiKit.TINTS.WHITE,
		TextTransparency = if locked then 0.5 else 0.15,
		TextSize = 11,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(50, 27),
		Size = UDim2.new(1, -220, 0, 32),
		Text = node.Desc .. effectText(node, rank),
		Parent = cell,
	})
	UiKit.Create("TextLabel", {
		Name = "Rank",
		BackgroundTransparency = 1,
		TextColor3 = if maxed then COLOR_MAX else UiKit.TINTS.WHITE,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.new(1, -160, 0, 10),
		Size = UDim2.fromOffset(150, 14),
		Text = `Rang {rank}/{node.MaxRank}`,
		Parent = cell,
	})

	-- Action ou raison, alignée à droite.
	if maxed then
		UiKit.Create("TextLabel", {
			Name = "Maxed",
			BackgroundTransparency = 1,
			TextColor3 = COLOR_MAX,
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 6),
			Size = UDim2.fromOffset(90, 20),
			Text = "Max ★",
			Parent = cell,
		})
	elseif ok then
		local buy = UiKit.Button(cell, "Acheter", UDim2.fromOffset(96, 34), UDim2.new(1, -106, 0.5, -17))
		buy.Name = `Buy_{node.Id}`
		buy.AnchorPoint = Vector2.new(1, 0)
		buy.Activated:Connect(function()
			if pendingBuys[node.Id] then
				return
			end
			pendingBuys[node.Id] = true
			buy.Active = false
			Net.SkillBuy:FireServer(node.Id)
		end)
	else
		UiKit.Create("TextLabel", {
			Name = "LockedReason",
			BackgroundTransparency = 1,
			TextColor3 = if locked then Color3.fromRGB(255, 150, 150) else Color3.fromRGB(160, 160, 170),
			Font = Enum.Font.Gotham,
			TextSize = 11,
			TextWrapped = true,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, -8),
			Size = UDim2.fromOffset(150, 32),
			Text = if locked then `🔒 {prereqName}` else reason,
			Parent = cell,
		})
	end
end

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

	list = UiKit.Scroller(frame, UDim2.fromScale(0, 0.08), UDim2.fromScale(1, 0.92))
	list.Name = "SkillList"
	-- Les lignes se suivent dans l'ordre de déblocage : tri explicite par LayoutOrder.
	local layout = list:FindFirstChildOfClass("UIListLayout")
	if layout then
		layout.SortOrder = Enum.SortOrder.LayoutOrder
	end
	return frame
end

function SkillPanel.Refresh(state)
	pendingBuys = {}
	local points = state.SkillPoints or 0
	local ranks = state.SkillRanks or {}
	pointsLabel.Text = `Points d'étoile : {points}`

	UiKit.Clear(list)
	local order = 0
	for _, node in sortedNodes() do
		order += 1
		AddSkillRow(list, node, ranks, points, order)
	end
end

return SkillPanel
