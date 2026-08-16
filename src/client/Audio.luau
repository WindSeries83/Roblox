local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Net = require(ReplicatedStorage.Shared.Net)

local Audio = {}

local SOUND_IDS = {
	HatchCrack = "rbxassetid://9117459499",
	RareFanfare = "rbxassetid://1836473422",
	RiftWhoosh = "rbxassetid://3073069105",
	UiClick = "rbxassetid://88442833509532",
	UpgradeMagic = "rbxassetid://93989620006639",
	CoinReward = "rbxassetid://109376364304066",
	RebirthRoar = "rbxassetid://7127123554",
	EvolutionWhoosh = "rbxassetid://108306323478967",
}

local VOLUMES = {
	HatchCrack = 0.8,
	RareFanfare = 0.6,
	RiftWhoosh = 0.5,
	UiClick = 0.35,
	UpgradeMagic = 0.7,
	CoinReward = 0.7,
	RebirthRoar = 0.8,
	EvolutionWhoosh = 0.6,
}

function Audio.Play(name: string, volume: number?)
	local soundId = SOUND_IDS[name]
	if not soundId then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or VOLUMES[name] or 0.5
	sound.Parent = SoundService
	sound.Ended:Connect(function()
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

Net.Sync.OnClientEvent:Connect(DiffSync)

return Audio
