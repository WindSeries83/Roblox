local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UiKit = require(script.Parent.Parent.UiKit)
local Net = require(ReplicatedStorage.Shared.Net)
local SkillTree = require(ReplicatedStorage.Shared.SkillTree)

local SkillPanel = {}

-- Géométrie du graphe : marge de canvas et pas fixes entre lignes/colonnes.
local CANVAS_PAD = 40
local COL_STEP = 130
local ROW_STEP = 110
local NODE_SIZE = 56

-- Palette des états de nœud (verrouillé / possédé / au maximum).
local COLOR_LOCKED = Color3.fromRGB(45, 45, 58)
local COLOR_LOCKED_TEXT = Color3.fromRGB(120, 120, 135)
local COLOR_OWNED = Color3.fromRGB(70, 70, 90)
local COLOR_MAX = Color3.fromRGB(255, 215, 94)
local COLOR_LINE_OWNED = Color3.fromRGB(70, 70, 90)
local COLOR_LINE_LOCKED = Color3.fromRGB(45, 45, 58)

local pointsLabel
local canvas
local detail
local selectedId

local function nodeCenter(node: any): (number, number)
	return CANVAS_PAD + (node.Col - 1) * COL_STEP, CANVAS_PAD + (node.Row - 1) * ROW_STEP
end

-- Un nœud est verrouillé tant qu'un de ses prerequis est au rang 0.
local function isLocked(node, ranks: { [string]: number }): boolean
	for _, reqId in SkillTree.Requires(node) do
		if SkillTree.Rank(ranks, reqId) < 1 then
			return true
		end
	end
	return false
end

local function effectText(node, rank: number): string
	if typeof(node.Value) ~= "number" or rank <= 0 or node.Effect == "SecretOmen" then
		return ""
	end
	return ` · +{string.format("%g", node.Value * rank * 100)} %`
end

local function fillDetail(node, ranks: { [string]: number }, points: number)
	UiKit.Clear(detail)
	local rank = SkillTree.Rank(ranks, node.Id)
	local ok, reason = SkillTree.CanBuy(points, ranks, node.Id)

	UiKit.Create("TextLabel", {
		Name = "DetailName",
		BackgroundTransparency = 1,
		TextColor3 = UiKit.TINTS.WHITE,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -120, 0, 18),
		Text = `{node.Name} ({node.Branch})`,
		Parent = detail,
	})
	UiKit.Create("TextLabel", {
		Name = "DetailDesc",
		BackgroundTransparency = 1,
		TextColor3 = UiKit.TINTS.WHITE,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Position = UDim2.fromOffset(0, 20),
		Size = UDim2.new(1, -120, 0, 34),
		Text = node.Desc,
		Parent = detail,
	})
	local infoText = `Rang {rank}/{node.MaxRank}{effectText(node, rank)}`
	if not ok and reason then
		infoText ..= ` · {reason}`
	end
	UiKit.Create("TextLabel", {
		Name = "DetailInfo",
		BackgroundTransparency = 1,
		TextColor3 = if ok then UiKit.TINTS.GREEN else UiKit.TINTS.RED,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 0, 1, -16),
		Size = UDim2.new(1, -120, 0, 14),
		Text = infoText,
		Parent = detail,
	})

	local buyButton = UiKit.Button(detail, "Acheter", UDim2.fromOffset(104, 32), UDim2.new(1, -112, 0.5, -16))
	buyButton.Name = "BuyButton"
	if not ok then
		buyButton.AutoButtonColor = false
		buyButton.Active = false
		buyButton.BackgroundColor3 = COLOR_OWNED
	end
	buyButton.Activated:Connect(function()
		if ok then
			Net.SkillBuy:FireServer(node.Id)
		end
	end)
end

local function buildGraph(ranks: { [string]: number }, points: number)
	UiKit.Clear(canvas)

	-- Traits de connexion d'abord : ancrés au centre du parent, pivotés vers l'enfant, sous les nœuds.
	for _, node in SkillTree.Nodes() do
		local x, y = nodeCenter(node)
		for _, reqId in SkillTree.Requires(node) do
			local parentNode = SkillTree.Node(reqId)
			if parentNode then
				local px, py = nodeCenter(parentNode)
				local dx, dy = x - px, y - py
				local length = math.sqrt(dx * dx + dy * dy)
				UiKit.Create("Frame", {
					Name = "Link",
					BackgroundColor3 = if SkillTree.Rank(ranks, reqId) >= 1
						then COLOR_LINE_OWNED
						else COLOR_LINE_LOCKED,
					BorderSizePixel = 0,
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.fromOffset(px, py),
					Size = UDim2.fromOffset(length, 3),
					Rotation = math.deg(math.atan2(dy, dx)),
					ZIndex = 1,
					Parent = canvas,
				})
			end
		end
	end

	for _, node in SkillTree.Nodes() do
		local x, y = nodeCenter(node)
		local rank = SkillTree.Rank(ranks, node.Id)
		local maxed = rank >= node.MaxRank
		local locked = isLocked(node, ranks)
		local backgroundColor, textColor, glyph
		if maxed then
			backgroundColor, textColor, glyph = COLOR_MAX, UiKit.TINTS.DARK, "★"
		elseif locked then
			backgroundColor, textColor, glyph = COLOR_LOCKED, COLOR_LOCKED_TEXT, "🔒"
		elseif rank > 0 then
			backgroundColor, textColor, glyph = COLOR_OWNED, UiKit.TINTS.WHITE, string.rep("●", math.min(rank, 3))
		elseif points > 0 then
			backgroundColor, textColor, glyph = UiKit.TINTS.ACCENT, UiKit.TINTS.WHITE, "+"
		else
			backgroundColor, textColor, glyph = COLOR_LOCKED, COLOR_LOCKED_TEXT, "+"
		end

		local nodeButton = UiKit.Create("TextButton", {
			Name = `Node_{node.Id}`,
			BackgroundColor3 = backgroundColor,
			TextColor3 = textColor,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBold,
			TextSize = 18,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(NODE_SIZE, NODE_SIZE),
			Text = glyph,
			ZIndex = 2,
			Parent = canvas,
		})
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, NODE_SIZE / 2)
		corner.Parent = nodeButton

		-- Pulse discret sur les nœuds achetables pour attirer l'œil.
		if not maxed and not locked and points > 0 then
			local pulse = Instance.new("UIScale")
			pulse.Parent = nodeButton
			TweenService:Create(
				pulse,
				TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{ Scale = 1.06 }
			):Play()
		end

		nodeButton.Activated:Connect(function()
			selectedId = node.Id
			fillDetail(node, ranks, points)
		end)
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

	-- Graphe en positions absolues : le Scroller générique pose un UIListLayout qui gênerait.
	local maxCol, maxRow = 0, 0
	for _, node in SkillTree.Nodes() do
		maxCol = math.max(maxCol, node.Col or 0)
		maxRow = math.max(maxRow, node.Row or 0)
	end
	canvas = UiKit.Create("ScrollingFrame", {
		Name = "NodeGraph",
		BackgroundTransparency = 1,
		ScrollBarThickness = 4,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(
			CANVAS_PAD + maxCol * COL_STEP + CANVAS_PAD,
			CANVAS_PAD + maxRow * ROW_STEP + CANVAS_PAD
		),
		Position = UDim2.fromScale(0, 0.08),
		Size = UDim2.new(1, 0, 0.92, -98),
		Parent = frame,
	})

	detail = UiKit.Card(frame, UDim2.new(1, 0, 0, 90))
	detail.Position = UDim2.new(0, 0, 1, -90)
	return frame
end

function SkillPanel.Refresh(state)
	local points = state.SkillPoints or 0
	local ranks = state.SkillRanks or {}
	pointsLabel.Text = `Points d'étoile : {points}`

	buildGraph(ranks, points)
	if selectedId then
		local node = SkillTree.Node(selectedId)
		if node then
			fillDetail(node, ranks, points)
			return
		end
	end
	UiKit.Clear(detail)
end

return SkillPanel
