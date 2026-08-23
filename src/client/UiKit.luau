local Audio = require(script.Parent.Audio)
local Gameplay = require(game:GetService("ReplicatedStorage").Shared.Gameplay)
local Rarities = require(game:GetService("ReplicatedStorage").Shared.Data.Rarities)

local UiKit = {}

UiKit.TINTS = {
	DARK = Color3.fromRGB(20, 20, 26),
	PANEL = Color3.fromRGB(30, 30, 40),
	ACCENT = Color3.fromRGB(140, 60, 255),
	WHITE = Color3.fromRGB(235, 235, 245),
	RED = Color3.fromRGB(220, 60, 60),
	GREEN = Color3.fromRGB(70, 190, 100),
}

UiKit.EGG_TIER_NAMES = {
	CommonEgg = "Œuf commun",
	UncommonEgg = "Œuf peu commun",
	RareEgg = "Œuf rare",
	EpicEgg = "Œuf épique",
	LegendaryEgg = "Œuf légendaire",
}

function UiKit.Hex(color: Color3): string
	return string.format(
		"#%02X%02X%02X",
		math.floor(color.R * 255 + 0.5),
		math.floor(color.G * 255 + 0.5),
		math.floor(color.B * 255 + 0.5)
	)
end

function UiKit.DropRatesText(weights: { [string]: number }, formatEntry: ((any) -> string)?): string
	local parts = {}
	for _, rate in Gameplay.DropRates(weights) do
		if formatEntry then
			table.insert(parts, formatEntry(rate))
		else
			local rarity = Rarities[rate.Id]
			local name = rarity and rarity.Name or rate.Id
			local color = rarity and rarity.Color or UiKit.TINTS.WHITE
			table.insert(parts, `<font color="{UiKit.Hex(color)}">{name} {string.format("%g", rate.Percent)} %</font>`)
		end
	end
	return table.concat(parts, " · ")
end

local TweenService = game:GetService("TweenService")

function UiKit.Create(className: string, props: { [string]: any }): Instance
	local inst = Instance.new(className)
	for key, value in props do
		inst[key] = value
	end
	if className == "TextButton" or className == "ImageButton" then
		inst.Activated:Connect(function()
			Audio.Play("UiClick")
		end)
		local hoverScale = Instance.new("UIScale")
		inst.MouseEnter:Connect(function()
			if not hoverScale.Parent then
				hoverScale.Parent = inst
			end
			TweenService:Create(hoverScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Scale = 1.05,
			}):Play()
		end)
		inst.MouseLeave:Connect(function()
			TweenService:Create(hoverScale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Scale = 1,
			}):Play()
		end)
	end
	return inst
end

function UiKit.Corner(inst: GuiObject)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = inst
end

function UiKit.Padding(inst: Instance, amount: number)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, amount)
	pad.PaddingRight = UDim.new(0, amount)
	pad.PaddingTop = UDim.new(0, amount)
	pad.PaddingBottom = UDim.new(0, amount)
	pad.Parent = inst
end

function UiKit.Bar(parent: Instance, color: Color3): (TextLabel, Frame)
	local bg = UiKit.Create("Frame", {
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.5,
		Size = UDim2.fromScale(1, 0.3),
		Parent = parent,
	})
	UiKit.Corner(bg)
	local fill = UiKit.Create("Frame", {
		BackgroundColor3 = color,
		Size = UDim2.fromScale(1, 1),
		Parent = bg,
	})
	UiKit.Corner(fill)
	local label = UiKit.Create("TextLabel", {
		BackgroundTransparency = 1,
		TextColor3 = UiKit.TINTS.WHITE,
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		Parent = bg,
	})
	return label, fill
end

function UiKit.SetBar(fill: Frame, label: TextLabel, value: number, max: number)
	local ratio = math.clamp(value / max, 0, 1)
	fill.Size = UDim2.fromScale(ratio, 1)
	label.Text = `{math.max(0, math.floor(value))} / {math.floor(max)}`
end

function UiKit.Title(parent: Instance, text: string, size: number?): TextLabel
	return UiKit.Create("TextLabel", {
		BackgroundTransparency = 1,
		TextColor3 = UiKit.TINTS.WHITE,
		Font = Enum.Font.GothamBold,
		TextSize = size or 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = text,
		Parent = parent,
	})
end

function UiKit.Button(parent: Instance, text: string, size: UDim2?, position: UDim2?): TextButton
	local button = UiKit.Create("TextButton", {
		BackgroundColor3 = UiKit.TINTS.ACCENT,
		TextColor3 = UiKit.TINTS.WHITE,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		Size = size or UDim2.fromScale(1, 0),
		AutomaticSize = size == nil and Enum.AutomaticSize.Y or nil,
		Position = position,
		Text = text,
		Parent = parent,
	})
	UiKit.Corner(button)
	return button
end

function UiKit.Cell(parent: Instance): Frame
	local row = UiKit.Create("Frame", {
		BackgroundColor3 = UiKit.TINTS.DARK,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = parent,
	})
	UiKit.Corner(row)
	UiKit.Padding(row, 8)
	return row
end

function UiKit.Scroller(parent: Instance, position: UDim2, size: UDim2): ScrollingFrame
	local scroller = UiKit.Create("ScrollingFrame", {
		BackgroundTransparency = 1,
		ScrollBarThickness = 4,
		CanvasSize = UDim2.fromScale(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Position = position,
		Size = size,
		Parent = parent,
	})
	UiKit.Create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = scroller,
	})
	return scroller
end

function UiKit.Clear(frame: Instance)
	for _, child in frame:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

function UiKit.SubTabs(parent: Instance, height: number, pages: { any }): Frame
	local bar = UiKit.Create("Frame", {
		Name = "SubBar",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, height),
		Parent = parent,
	})
	local buttons = {}
	for i, page in pages do
		page.Page.Visible = i == 1
		local button = UiKit.Create("TextButton", {
			Name = `SubTab{i}`,
			BackgroundColor3 = UiKit.TINTS.DARK,
			TextColor3 = UiKit.TINTS.WHITE,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			Size = UDim2.new(1 / #pages, -4, 1, 0),
			Position = UDim2.new(1 / #pages * (i - 1), 2, 0, 0),
			Text = page.Name,
			Parent = bar,
		})
		UiKit.Corner(button)
		button.Activated:Connect(function()
			for j, other in buttons do
				other.BackgroundColor3 = UiKit.TINTS.DARK
				pages[j].Page.Visible = false
			end
			button.BackgroundColor3 = UiKit.TINTS.PANEL
			page.Page.Visible = true
		end)
		buttons[i] = button
	end
	buttons[1].BackgroundColor3 = UiKit.TINTS.PANEL
	return bar
end

return UiKit
