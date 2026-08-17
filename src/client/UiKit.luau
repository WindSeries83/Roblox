local Audio = require(script.Parent.Audio)

local UiKit = {}

UiKit.TINTS = {
	DARK = Color3.fromRGB(20, 20, 26),
	PANEL = Color3.fromRGB(30, 30, 40),
	ACCENT = Color3.fromRGB(140, 60, 255),
	WHITE = Color3.fromRGB(235, 235, 245),
	RED = Color3.fromRGB(220, 60, 60),
	GREEN = Color3.fromRGB(70, 190, 100),
}

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

return UiKit
