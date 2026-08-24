local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Net = require(ReplicatedStorage.Shared.Net)
local Config = require(ReplicatedStorage.Shared.Config)
local Sanctuary = require(ReplicatedStorage.Shared.Sanctuary)
local UiKit = require(script.Parent.UiKit)

local CouveusePanel = {}

local lastState = nil
local panel: Frame? = nil
local eggList: ScrollingFrame? = nil
local buyButtons: { [string]: TextButton } = {}
local lockedTiers: { [string]: number? } = {}

local function RefreshBuyButtons()
	local essence = math.floor(lastState and lastState.Essence or 0)
	for tier, button in buyButtons do
		local required = lockedTiers[tier]
		local price = Config.EGG_PRICES[tier]
		if required then
			button.Text = `{UiKit.EGG_TIER_NAMES[tier]} 🔒\nRang {required}`
			button.TextColor3 = Color3.fromRGB(140, 140, 150)
		elseif essence < price then
			button.Text = `{UiKit.EGG_TIER_NAMES[tier]}\n{price} — insuffisant`
			button.TextColor3 = Color3.fromRGB(255, 120, 120)
		else
			button.Text = `{UiKit.EGG_TIER_NAMES[tier]}\n{price}`
			button.TextColor3 = UiKit.TINTS.WHITE
		end
	end
end

local function Refresh()
	if not lastState or not eggList or not eggList.Parent then
		return
	end
	lockedTiers = Sanctuary.EggGate(lastState.SanctuaryLevel or 1)
	RefreshBuyButtons()
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
			Text = UiKit.EGG_TIER_NAMES[egg.Tier] or egg.Tier,
			Parent = row,
		})
		local hatch = UiKit.Button(row, "Placer", UDim2.fromScale(0.42, 1), UDim2.fromScale(0.56, 0))
		hatch.Activated:Connect(function()
			Net.PlaceEgg:FireServer(egg.Id)
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

	UiKit.Create("TextLabel", {
		Name = "PlaceHint",
		BackgroundTransparency = 1,
		TextTransparency = 0.3,
		TextColor3 = UiKit.TINTS.WHITE,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 0, 1, -74),
		Size = UDim2.new(1, 0, 0, 12),
		Text = "Va à la couveuse pour éclore tes œufs",
		Parent = panel,
	})

	local ratesRow = UiKit.Create("Frame", {
		Name = "RatesRow",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, -46),
		Size = UDim2.new(1, 0, 0, 14),
		Parent = panel,
	})
	for i, tier in Sanctuary.EGG_TIERS do
		UiKit.Create("TextLabel", {
			Name = `Rates{tier}`,
			RichText = true,
			BackgroundTransparency = 1,
			TextColor3 = UiKit.TINTS.WHITE,
			TextSize = 9,
			TextWrapped = true,
			Position = UDim2.fromScale((i - 1) / #Sanctuary.EGG_TIERS, 0),
			Size = UDim2.fromScale(1 / #Sanctuary.EGG_TIERS, 1),
			Text = UiKit.DropRatesText(Config.EGG_RARITY_WEIGHTS[tier]),
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
	for i, tier in Sanctuary.EGG_TIERS do
		local button = UiKit.Button(
			buyRow,
			`{UiKit.EGG_TIER_NAMES[tier]}\n{Config.EGG_PRICES[tier]}`,
			UDim2.new(1 / #Sanctuary.EGG_TIERS, -4, 1, 0),
			UDim2.new((i - 1) / #Sanctuary.EGG_TIERS, 2, 0, 0)
		)
		button.TextSize = 10
		buyButtons[tier] = button
		button.Activated:Connect(function()
			if lockedTiers[tier] then
				return
			end
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
