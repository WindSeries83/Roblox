local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Config = require(ReplicatedStorage.Shared.Config)
local Species = require(ReplicatedStorage.Shared.Data.Species)
local Rarities = require(ReplicatedStorage.Shared.Data.Rarities)
local Equipment = require(ReplicatedStorage.Shared.Data.Equipment)
local Evolution = require(ReplicatedStorage.Shared.Evolution)
local FeatureUnlocks = require(ReplicatedStorage.Shared.FeatureUnlocks)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local UiKit = require(script.Parent:WaitForChild("UiKit"))

local CreatureHud = {}

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local TINTS = UiKit.TINTS

local screen: ScreenGui? = nil
local titleLabel: TextLabel? = nil
local stageLabel: TextLabel? = nil
local xpLabel: TextLabel? = nil
local xpFill: Frame? = nil
local equipButton: TextButton? = nil
local companionButton: TextButton? = nil
local evolveButton: TextButton? = nil
local priceBox: TextBox? = nil

local currentId: string? = nil
local lastState = nil

function CreatureHud.SuggestedPrice(rarity: string): number
	local rank = math.max(1, Gameplay.RarityRank(rarity))
	return math.max(Config.MARKET_MIN_PRICE, math.floor(Config.EGG_PRICES.CommonEgg * (1 + (rank - 1) * 2)))
end

local function Close()
	currentId = nil
	if screen then
		screen.Enabled = false
	end
end

local function CurrentCreature()
	if not currentId or not lastState then
		return nil
	end
	for _, creature in lastState.Creatures do
		if creature.Id == currentId then
			return creature
		end
	end
	return nil
end

local function Render()
	local creature = CurrentCreature()
	if not creature then
		Close()
		return
	end

	local species = Species[creature.SpeciesId]
	local rarity = Rarities[creature.Rarity]
	titleLabel.Text = `{species and species.Name or creature.SpeciesId} — {creature.Rarity}`
	titleLabel.TextColor3 = if rarity then rarity.Color else TINTS.WHITE
	stageLabel.Text = `Stade {creature.Stage} — Niveau {creature.Level} — Puissance {math.floor(creature.Power)}`

	local maxLevel = Evolution.MaxLevelFor(creature)
	if creature.Level >= maxLevel then
		xpFill.Size = UDim2.fromScale(1, 1)
		xpLabel.Text = "Niveau maximum"
	else
		UiKit.SetBar(xpFill, xpLabel, creature.XP, Evolution.XPToNext(creature.Level))
	end

	local equipmentUnlocked = FeatureUnlocks.Require(lastState, "Equipment")
	local item = lastState.Items[1]
	if not equipmentUnlocked then
		equipButton.Visible = true
		equipButton.Text = lastState.UnlockReasons and lastState.UnlockReasons.Equipment or "Équipement verrouillé"
		equipButton.BackgroundColor3 = TINTS.DARK
		equipButton.AutoButtonColor = false
	elseif item then
		local def = Equipment[item.Type] and Equipment[item.Type].Tiers[item.Tier]
		equipButton.Visible = true
		equipButton.Text = if def then `Équiper {def.Name}` else "Équiper"
		equipButton.BackgroundColor3 = TINTS.ACCENT
		equipButton.AutoButtonColor = true
	else
		equipButton.Visible = false
	end

	local isCompanion = lastState.CompanionId == creature.Id
	companionButton.Text = if isCompanion then "Rappeler à la grille" else "Faire suivre"

	local evolutionUnlocked = FeatureUnlocks.Require(lastState, "Evolution")
	if evolutionUnlocked then
		local canEvolve, reason = Evolution.CanEvolve(creature, lastState.Essence)
		evolveButton.Text = if canEvolve
			then `Évoluer ({Evolution.EvolveCost(creature)} Essence)`
			else `Évoluer — {reason}`
		evolveButton.AutoButtonColor = canEvolve
	else
		evolveButton.Text = lastState.UnlockReasons and lastState.UnlockReasons.Evolution or "Évolution verrouillée"
		evolveButton.AutoButtonColor = false
		evolveButton.BackgroundColor3 = TINTS.DARK
	end
end

local function Build()
	screen = UiKit.Create("ScreenGui", {
		Name = "CreatureHud",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		Enabled = false,
		Parent = playerGui,
	})

	local overlay = UiKit.Create("TextButton", {
		Name = "Overlay",
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.fromScale(1, 1),
		Parent = screen,
	})
	overlay.Activated:Connect(Close)

	local panel = UiKit.Create("Frame", {
		Name = "Panel",
		BackgroundColor3 = TINTS.PANEL,
		Size = UDim2.fromOffset(320, 300),
		Position = UDim2.new(0.5, 0, 1, -16),
		AnchorPoint = Vector2.new(0.5, 1),
		ZIndex = 50,
		Parent = screen,
	})
	UiKit.Corner(panel)
	UiKit.Padding(panel, 10)

	titleLabel = UiKit.Create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		TextColor3 = TINTS.WHITE,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.fromScale(1, 0.12),
		ZIndex = 50,
		Text = "",
		Parent = panel,
	})

	stageLabel = UiKit.Create("TextLabel", {
		Name = "Stage",
		BackgroundTransparency = 1,
		TextColor3 = TINTS.WHITE,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0, 0.14),
		Size = UDim2.fromScale(1, 0.1),
		ZIndex = 50,
		Text = "",
		Parent = panel,
	})

	xpLabel, xpFill = UiKit.Bar(panel, TINTS.ACCENT)
	xpLabel.Position = UDim2.fromScale(0, 0.26)
	xpLabel.Size = UDim2.fromScale(1, 0.1)

	equipButton = UiKit.Button(panel, "Équiper", UDim2.fromScale(1, 0.13), UDim2.fromScale(0, 0.37))
	equipButton.ZIndex = 50
	equipButton.Activated:Connect(function()
		if not lastState or not FeatureUnlocks.Require(lastState, "Equipment") then
			return
		end
		local item = lastState and lastState.Items[1]
		if item and currentId then
			Net.EquipItem:FireServer(currentId, item.Id)
		end
	end)

	companionButton = UiKit.Button(panel, "Faire suivre", UDim2.fromScale(1, 0.13), UDim2.fromScale(0, 0.52))
	companionButton.ZIndex = 50
	companionButton.Activated:Connect(function()
		local creature = CurrentCreature()
		if creature then
			local isCurrent = lastState.CompanionId == creature.Id
			-- true → rappel (nil) ; false → désignation.
			Net.SetCompanion:FireServer(if isCurrent then nil else creature.Id)
		end
	end)

	evolveButton = UiKit.Button(panel, "Évoluer", UDim2.fromScale(1, 0.13), UDim2.fromScale(0, 0.67))
	evolveButton.ZIndex = 50
	evolveButton.Activated:Connect(function()
		if not lastState or not FeatureUnlocks.Require(lastState, "Evolution") then
			return
		end
		local creature = CurrentCreature()
		if creature then
			local canEvolve = Evolution.CanEvolve(creature, lastState.Essence)
			if canEvolve then
				Net.EvolveCreature:FireServer(creature.Id)
			end
		end
	end)

	priceBox = UiKit.Create("TextBox", {
		Name = "Price",
		BackgroundColor3 = TINTS.DARK,
		TextColor3 = TINTS.WHITE,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		Text = "",
		ClearTextOnFocus = false,
		Size = UDim2.fromScale(0.45, 0.13),
		Position = UDim2.fromScale(0, 0.81),
		ZIndex = 50,
		Parent = panel,
	})
	UiKit.Corner(priceBox)

	local sellButton =
		UiKit.Button(panel, "Vendre au marché", UDim2.fromScale(0.53, 0.13), UDim2.fromScale(0.47, 0.81))
	sellButton.ZIndex = 50
	sellButton.Activated:Connect(function()
		local price = tonumber(priceBox.Text)
		if currentId and price then
			price = math.clamp(math.floor(price), Config.MARKET_MIN_PRICE, Config.MARKET_MAX_PRICE)
			Net.MarketList:FireServer(currentId, price)
			Close()
		end
	end)

	UiKit.Create("TextLabel", {
		Name = "Hint",
		BackgroundTransparency = 1,
		TextColor3 = TINTS.WHITE,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextTransparency = 0.4,
		Size = UDim2.fromScale(1, 0.05),
		Position = UDim2.fromScale(0, 0.95),
		ZIndex = 50,
		Text = "Clic ailleurs pour fermer",
		Parent = panel,
	})
end

function CreatureHud.Open(creature, state)
	lastState = state
	currentId = creature.Id
	if not screen or not screen.Parent then
		Build()
	end
	priceBox.Text = tostring(CreatureHud.SuggestedPrice(creature.Rarity))
	screen.Enabled = true
	Render()
end

Net.Sync.OnClientEvent:Connect(function(state)
	lastState = state
	if screen and screen.Enabled then
		Render()
	end
end)

return CreatureHud
