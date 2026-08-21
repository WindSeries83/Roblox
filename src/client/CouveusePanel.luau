local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Net = require(ReplicatedStorage.Shared.Net)
local Config = require(ReplicatedStorage.Shared.Config)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Rarities = require(ReplicatedStorage.Shared.Data.Rarities)
local UiKit = require(script.Parent.UiKit)

local CouveusePanel = {}

local TIER_NAMES = {
	CommonEgg = "Œuf commun",
	UncommonEgg = "Œuf peu commun",
	RareEgg = "Œuf rare",
}
local TIER_ORDER = { "CommonEgg", "UncommonEgg", "RareEgg" }

local function Hex(color: Color3): string
	return string.format(
		"#%02X%02X%02X",
		math.floor(color.R * 255 + 0.5),
		math.floor(color.G * 255 + 0.5),
		math.floor(color.B * 255 + 0.5)
	)
end

local function EggRatesText(weights: { [string]: number }): string
	local parts = {}
	for _, rate in Gameplay.DropRates(weights) do
		local rarity = Rarities[rate.Id]
		local name = rarity and rarity.Name or rate.Id
		local color = rarity and rarity.Color or UiKit.TINTS.WHITE
		table.insert(parts, `<font color="{Hex(color)}">{name} {string.format("%g", rate.Percent)} %</font>`)
	end
	return table.concat(parts, " · ")
end

local lastState = nil
local panel: Frame? = nil
local eggList: ScrollingFrame? = nil

local function Refresh()
	if not lastState or not eggList or not eggList.Parent then
		return
	end
	UiKit.Clear(eggList)
	for i, egg in lastState.Eggs do
		local row = UiKit.Cell(eggList)
		row.Name = `EggRow{i}`
		row.Size = UDim2.new(1, -8, 0, 38)
		UiKit.Create("TextLabel", {
			BackgroundTransparency = 1,
			TextColor3 = UiKit.TINTS.WHITE,
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.fromScale(0.55, 1),
			Text = TIER_NAMES[egg.Tier] or egg.Tier,
			Parent = row,
		})
		local hatch = UiKit.Button(row, "Éclore", UDim2.fromScale(0.42, 1), UDim2.fromScale(0.56, 0))
		hatch.Activated:Connect(function()
			Net.HatchEgg:FireServer(egg.Id)
		end)
	end
end

function CouveusePanel.Start()
	-- ponytail: retry indéfiniment — le place peut charger l'objet couveuse après le script
	local model, gui, prompt
	while not (model and gui and prompt) do
		model = Workspace:FindFirstChild("Couveuse")
		gui = model and model:FindFirstChild("CouveuseGui", true)
		prompt = model and model:FindFirstChildWhichIsA("ProximityPrompt", true)
		if not (model and gui and prompt) then
			task.wait(1)
		end
	end
	if gui:FindFirstChild("Root") then
		return
	end

	panel = UiKit.Create("Frame", {
		Name = "Root",
		BackgroundColor3 = UiKit.TINTS.PANEL,
		BackgroundTransparency = 0.05,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		Parent = gui,
	})
	UiKit.Corner(panel)
	UiKit.Padding(panel, 8)

	UiKit.Title(panel, "Couveuse", 14)

	eggList = UiKit.Scroller(panel, UDim2.fromOffset(0, 22), UDim2.new(1, 0, 1, -78))
	eggList.Name = "EggList"

	local ratesRow = UiKit.Create("Frame", {
		Name = "RatesRow",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, -46),
		Size = UDim2.new(1, 0, 0, 14),
		Parent = panel,
	})
	for i, tier in TIER_ORDER do
		UiKit.Create("TextLabel", {
			Name = `Rates{tier}`,
			RichText = true,
			BackgroundTransparency = 1,
			TextColor3 = UiKit.TINTS.WHITE,
			TextSize = 9,
			TextWrapped = true,
			Position = UDim2.fromScale((i - 1) / 3, 0),
			Size = UDim2.fromScale(1 / 3, 1),
			Text = EggRatesText(Config.EGG_RARITY_WEIGHTS[tier]),
			Parent = ratesRow,
		})
	end

	local buyRow = UiKit.Create("Frame", {
		Name = "BuyRow",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 30),
		Parent = panel,
	})
	for i, tier in TIER_ORDER do
		local button = UiKit.Button(
			buyRow,
			`{TIER_NAMES[tier]}\n{Config.EGG_PRICES[tier]}`,
			UDim2.new(1 / 3, -4, 1, 0),
			UDim2.new((i - 1) / 3, 2, 0, 0)
		)
		button.TextSize = 10
		button.Activated:Connect(function()
			Net.BuyEgg:FireServer(tier)
		end)
	end

	local lastTrigger = 0
	prompt.Triggered:Connect(function()
		if os.clock() - lastTrigger < 0.25 then
			return
		end
		lastTrigger = os.clock()
		panel.Visible = not panel.Visible
		if panel.Visible then
			Refresh()
		end
	end)

	Net.Sync.OnClientEvent:Connect(function(state)
		lastState = state
		if panel.Visible then
			Refresh()
		end
	end)
end

task.spawn(function()
	CouveusePanel.Start()
end)

return CouveusePanel
