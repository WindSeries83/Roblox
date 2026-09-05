--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Net = require(ReplicatedStorage.Shared.Net)

local Audio = {}

local SOUND_IDS: { [string]: string } = {
	HatchCrack = "rbxassetid://9117459499",
	RareFanfare = "rbxassetid://1836473422",
	RiftWhoosh = "rbxassetid://3073069105",
	UiClick = "rbxassetid://88442833509532",
	UpgradeMagic = "rbxassetid://93989620006639",
	CoinReward = "rbxassetid://109376364304066",
	RebirthRoar = "rbxassetid://7127123554",
	EvolutionWhoosh = "rbxassetid://108306323478967",
}

local VOLUMES: { [string]: number } = {
	HatchCrack = 0.8,
	RareFanfare = 0.6,
	RiftWhoosh = 0.5,
	UiClick = 0.35,
	UpgradeMagic = 0.7,
	CoinReward = 0.7,
	RebirthRoar = 0.8,
	EvolutionWhoosh = 0.6,
}

local MUSIC_IDS: { [string]: string } = {
	Sanctuary = "rbxassetid://97878486673197",
	Rift = "rbxassetid://96584039561549",
}

local MUSIC_VOLUMES: { [string]: number } = {
	Sanctuary = 0.18,
	Rift = 0.22,
}

local music: { [string]: Sound } = {}
local activeSfx: { [Sound]: number } = {}
local currentMusic: string? = nil
local requestedMusic: string? = nil
local sfxEnabled = true
local musicEnabled = true
local reducedEffects = false

function Audio.SetMusic(name: string?)
	requestedMusic = name
	if not musicEnabled then
		for _, sound in music do
			sound:Stop()
		end
		currentMusic = nil
		return
	end
	if currentMusic == name then
		return
	end
	for musicName, sound in music do
		if musicName == name then
			sound.Volume = MUSIC_VOLUMES[musicName]
			sound:Resume()
		else
			sound:Stop()
		end
	end
	currentMusic = name
end

function Audio.SetSfxEnabled(enabled: boolean)
	sfxEnabled = enabled
	for sound, volume in activeSfx do
		if sound.Parent then
			sound.Volume = if enabled then volume else 0
		else
			activeSfx[sound] = nil
		end
	end
end

function Audio.IsSfxEnabled(): boolean
	return sfxEnabled
end

function Audio.SetMusicEnabled(enabled: boolean)
	musicEnabled = enabled
	if enabled then
		Audio.SetMusic(requestedMusic)
	else
		for _, sound in music do
			sound:Stop()
		end
		currentMusic = nil
	end
end

function Audio.IsMusicEnabled(): boolean
	return musicEnabled
end

function Audio.SetReducedEffects(enabled: boolean)
	reducedEffects = enabled
end

function Audio.AreEffectsReduced(): boolean
	return reducedEffects
end

for name, id in MUSIC_IDS do
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = id
	sound.Volume = MUSIC_VOLUMES[name]
	sound.Looped = true
	sound.PlayOnRemove = false
	sound.Parent = SoundService
	music[name] = sound
end

function Audio.Play(name: string, volume: number?)
	local soundId = SOUND_IDS[name]
	if not soundId or not sfxEnabled then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	local level = volume or VOLUMES[name] or 0.5
	sound.Volume = level
	sound.Parent = SoundService
	activeSfx[sound] = level
	sound.Ended:Connect(function()
		activeSfx[sound] = nil
		sound:Destroy()
	end)
	sound:Play()
end

local previousState = nil

local function DiffSync(state)
	if not previousState then
		previousState = state
		return
	end
	local prev = previousState
	if state.SanctuaryLevel and prev.SanctuaryLevel and state.SanctuaryLevel > prev.SanctuaryLevel then
		Audio.Play("UpgradeMagic")
	end
	if state.Stars and prev.Stars and state.Stars > prev.Stars then
		Audio.Play("RebirthRoar")
	end
	if state.Creatures then
		local stages = {}
		for _, creature in state.Creatures do
			stages[creature.Id] = creature.Stage
		end
		for _, creature in prev.Creatures do
			if stages[creature.Id] and stages[creature.Id] > creature.Stage then
				Audio.Play("EvolutionWhoosh")
				break
			end
		end
	end
	previousState = state
end

Net.RiftWorld.OnClientEvent:Connect(function(world)
	if world.Active then
		Audio.SetMusic("Rift")
	else
		Audio.SetMusic("Sanctuary")
	end
end)

Net.Sync.OnClientEvent:Connect(DiffSync)

task.delay(1, function()
	Audio.SetMusic("Sanctuary")
end)

return Audio
