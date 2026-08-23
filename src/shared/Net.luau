local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Net = {}

local function Event(name: string): RemoteEvent
	local existing = Remotes:FindFirstChild(name)
	if existing then
		return existing :: RemoteEvent
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = Remotes
	return remote
end

Net.BuyEgg = Event("BuyEgg")
Net.HatchEgg = Event("HatchEgg")
Net.RiftAttack = Event("RiftAttack")
Net.Sync = Event("Sync")
Net.HatchResult = Event("HatchResult")
Net.RareDrop = Event("RareDrop")
Net.RiftSync = Event("RiftSync")
Net.RiftEnded = Event("RiftEnded")
Net.RiftWorld = Event("RiftWorld")
Net.RiftRequest = Event("RiftRequest")
Net.EvolveCreature = Event("EvolveCreature")
Net.BuyItem = Event("BuyItem")
Net.EquipItem = Event("EquipItem")
Net.UnequipItem = Event("UnequipItem")
Net.BreedCreatures = Event("BreedCreatures")
Net.BreedResult = Event("BreedResult")
Net.RebirthRequest = Event("RebirthRequest")
Net.RebirthPreview = Event("RebirthPreview")
Net.RebirthConfirm = Event("RebirthConfirm")
Net.UpgradeSanctuary = Event("UpgradeSanctuary")
Net.QuestsSync = Event("QuestsSync")
Net.QuestClaim = Event("QuestClaim")
Net.TutorialComplete = Event("TutorialComplete")
Net.OrbClaimed = Event("OrbClaimed")

Net.LuckSync = Event("LuckSync")
Net.BoostState = Event("BoostState")

Net.MarketList = Event("MarketList")
Net.MarketListings = Event("MarketListings")
Net.MarketBuy = Event("MarketBuy")
Net.MarketRemove = Event("MarketRemove")
Net.MarketSync = Event("MarketSync")

Net.DuelChallenge = Event("DuelChallenge")
Net.DuelAccept = Event("DuelAccept")
Net.DuelDecline = Event("DuelDecline")
Net.DuelRequest = Event("DuelRequest")
Net.DuelResult = Event("DuelResult")

Net.SeasonSync = Event("SeasonSync")
Net.SeasonRequest = Event("SeasonRequest")
Net.SeasonClaim = Event("SeasonClaim")

Net.LeaderboardRequest = Event("LeaderboardRequest")
Net.LeaderboardSync = Event("LeaderboardSync")
Net.LeaderboardVisit = Event("LeaderboardVisit")
Net.LeaderboardDetail = Event("LeaderboardDetail")

return Net
