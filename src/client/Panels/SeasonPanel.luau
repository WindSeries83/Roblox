local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiKit = require(script.Parent.Parent.UiKit)
local Audio = require(script.Parent.Parent.Audio)
local Net = require(ReplicatedStorage.Shared.Net)
local Config = require(ReplicatedStorage.Shared.Config)
local Season = require(ReplicatedStorage.Shared.Season)
local Species = require(ReplicatedStorage.Shared.Data.Species)

local SeasonPanel = {}

local TINTS = UiKit.TINTS

local page
local payload = nil

local function RewardLine(level: number, track: string): string
	local reward = Season.RewardFor(level, track)
	local line = `{reward.Essence} Essence`
	if reward.Creature then
		local species = Species[reward.Creature.SpeciesId]
		line = `{line} + {species and species.Name or reward.Creature.SpeciesId} exclusive`
	end
	if reward.Title then
		line = `{line} + titre "{reward.Title}"`
	end
	return line
end

local function Build(season, hasPremium)
	UiKit.Clear(page)
	if not season then
		return
	end
	local level = season.Level
	local xp = season.XP
	local xpForNext = Season.XPForLevel(math.min(level + 1, Config.SEASON_MAX_LEVEL))
	local xpForCurrent = Season.XPForLevel(level)
	UiKit.Title(page, `Niveau {level}/{Config.SEASON_MAX_LEVEL} — {xp} XP`)
	if level < Config.SEASON_MAX_LEVEL then
		local label, fill = UiKit.Bar(page, TINTS.ACCENT)
		UiKit.SetBar(fill, label, xp - xpForCurrent, xpForNext - xpForCurrent)
	end

	local function Track(title: string, trackName: string, lockedText: string)
		local isPremium = trackName == "premium"
		local claimedList = if isPremium then season.ClaimedPremium else season.ClaimedFree
		UiKit.Title(page, title, 14)
		if isPremium and not hasPremium then
			UiKit.Create("TextLabel", {
				BackgroundTransparency = 1,
				TextColor3 = TINTS.RED,
				TextSize = 13,
				TextWrapped = true,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 18),
				Text = "La piste premium se débloque avec le gamepass Saison Premium.",
				Parent = page,
			})
		end
		for lvl = 1, Config.SEASON_MAX_LEVEL do
			local claimed = claimedList[lvl] == true
			local claimable = (not isPremium or hasPremium) and not claimed and Season.CanClaim(season, lvl, trackName)
			local cell = UiKit.Cell(page)
			UiKit.Create("TextLabel", {
				BackgroundTransparency = 1,
				TextColor3 = if claimed then TINTS.GREEN else TINTS.WHITE,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Size = UDim2.fromScale(0.6, 1),
				Text = `Niv. {lvl} — {RewardLine(lvl, trackName)}`,
				TextWrapped = true,
				Parent = cell,
			})
			if claimable then
				local button = UiKit.Button(cell, "Réclamer", UDim2.new(0.34, 0, 0, 26), UDim2.new(0.64, 0, 0.5, -13))
				if isPremium then
					button.BackgroundColor3 = TINTS.GREEN
				end
				button.Activated:Connect(function()
					Audio.Play("CoinReward")
					Net.SeasonClaim:FireServer(lvl, trackName)
				end)
			else
				UiKit.Create("TextLabel", {
					BackgroundTransparency = 1,
					TextColor3 = if claimed then TINTS.GREEN else Color3.fromRGB(150, 150, 160),
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Right,
					Size = UDim2.new(0.34, 0, 0, 26),
					Position = UDim2.new(0.64, 0, 0.5, -13),
					Text = if claimed then "Réclamé" else lockedText,
					Parent = cell,
				})
			end
		end
	end

	Track("Piste gratuite", "free", "Verrouillé")
	Track("Piste premium", "premium", if not hasPremium then "Premium requis" else "Verrouillé")
end

function SeasonPanel.Create(parent: Instance): Frame
	local panel = UiKit.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = parent,
	})
	page = UiKit.Scroller(panel, UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1))
	page.Name = "SeasonPage"

	Net.SeasonSync.OnClientEvent:Connect(function(payloadData)
		payload = payloadData
		Build(payload.Season, payload.HasPremium)
	end)

	task.spawn(function()
		task.wait(1)
		Net.SeasonRequest:FireServer()
	end)

	return panel
end

function SeasonPanel.Refresh(_state)
	if payload then
		Build(payload.Season, payload.HasPremium)
	end
end

return SeasonPanel
