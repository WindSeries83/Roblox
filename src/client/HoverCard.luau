local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rarities = require(ReplicatedStorage.Shared.Data.Rarities)
local Mutations = require(ReplicatedStorage.Shared.Data.Mutations)
local Species = require(ReplicatedStorage.Shared.Data.Species)

local HoverCard = {}

local WIDTH = 220
local LINE_HEIGHT = 18
local LINE_GAP = 2
local PAD = 8

local COLORS = {
	BG = Color3.fromRGB(20, 20, 26),
	WHITE = Color3.fromRGB(235, 235, 245),
	ACCENT = Color3.fromRGB(140, 60, 255),
	GREEN = Color3.fromRGB(70, 190, 100),
}

function HoverCard.BuildLines(entry)
	local lines = {}
	local species = Species[entry.SpeciesId]
	local rarity = Rarities[entry.Rarity]
	local name = species and species.Name or entry.SpeciesId
	table.insert(lines, {
		Text = `{name} · {rarity and rarity.Name or entry.Rarity}`,
		Color = rarity and rarity.Color or COLORS.WHITE,
	})
	if entry.Mutation ~= false and entry.Mutation ~= nil and Mutations[entry.Mutation] then
		local mutation = Mutations[entry.Mutation]
		table.insert(lines, {
			Text = `{mutation.Name} ×{mutation.Multiplier}`,
			Color = mutation.Color,
		})
	end
	if entry.Level ~= nil and entry.Power ~= nil then
		table.insert(lines, {
			Text = `Niv. {entry.Level} · Puissance {math.floor(entry.Power)}`,
			Color = COLORS.WHITE,
		})
	end
	if entry.SuggestedPrice ~= nil then
		table.insert(lines, {
			Text = `Valeur ≈ {math.floor(entry.SuggestedPrice)} Essence`,
			Color = COLORS.GREEN,
		})
	end
	if entry.Discovered then
		table.insert(lines, { Text = "Découvert", Color = COLORS.ACCENT })
	end
	return lines
end

local screenGui: ScreenGui? = nil
local billboard: BillboardGui? = nil
local card: Frame? = nil

local function EnsureCard(): Frame
	if card and card.Parent then
		return card
	end
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HoverCardGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 100
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	billboard = Instance.new("BillboardGui")
	billboard.Name = "HoverCardBillboard"
	billboard.ResetOnSpawn = false
	billboard.AlwaysOnTop = true
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.MaxDistance = 120
	billboard.Enabled = false
	billboard.Parent = playerGui

	card = Instance.new("Frame")
	card.Name = "Card"
	card.BackgroundColor3 = COLORS.BG
	card.BackgroundTransparency = 0.08
	card.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card

	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, LINE_GAP)
	list.Parent = card

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, PAD)
	pad.PaddingRight = UDim.new(0, PAD)
	pad.PaddingTop = UDim.new(0, PAD)
	pad.PaddingBottom = UDim.new(0, PAD)
	pad.Parent = card

	return card
end

local function RenderLines(frame: Frame, lines)
	for _, child in frame:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	for i, line in lines do
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.TextColor3 = line.Color
		label.Font = Enum.Font.Gotham
		label.TextSize = 14
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextTruncate = Enum.TextTruncate.AtEnd
		label.Size = UDim2.new(1, 0, 0, LINE_HEIGHT)
		label.LayoutOrder = i
		label.Text = line.Text
		label.Parent = frame
	end
end

function HoverCard.Show(anchor: GuiObject | BasePart, entry)
	local frame = EnsureCard()
	local lines = HoverCard.BuildLines(entry)
	RenderLines(frame, lines)

	local height = #lines * LINE_HEIGHT + (#lines - 1) * LINE_GAP + PAD * 2
	frame.Size = UDim2.fromOffset(WIDTH, height)

	if anchor:IsA("BasePart") then
		screenGui.Enabled = false
		billboard.Adornee = anchor
		billboard.Size = UDim2.fromOffset(WIDTH, height)
		frame.Parent = billboard
		frame.Position = UDim2.fromOffset(0, 0)
		frame.AnchorPoint = Vector2.zero
		billboard.Enabled = true
	else
		billboard.Enabled = false
		frame.Parent = screenGui
		local camera = workspace.CurrentCamera
		local viewport = camera and camera.ViewportSize or Vector2.new(1024, 768)
		local origin = anchor.AbsolutePosition
		local extent = origin + anchor.AbsoluteSize
		local x =
			math.clamp((origin.X + extent.X) / 2, WIDTH / 2 + 4, math.max(WIDTH / 2 + 4, viewport.X - WIDTH / 2 - 4))
		local top = origin.Y - 8
		if top - height >= 0 then
			frame.AnchorPoint = Vector2.new(0.5, 1)
			frame.Position = UDim2.fromOffset(x, top)
		else
			frame.AnchorPoint = Vector2.new(0.5, 0)
			frame.Position = UDim2.fromOffset(x, extent.Y + 8)
		end
		screenGui.Enabled = true
	end
end

function HoverCard.Hide()
	if billboard then
		billboard.Enabled = false
	end
	if screenGui then
		screenGui.Enabled = false
	end
end

return HoverCard
