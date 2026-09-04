--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Net = {}

local NAMES = {
	"BuyEgg",
	"PlaceEgg",
	"RiftAttack",
	"Sync",
	"HatchResult",
	"RareDrop",
	"RiftSync",
	"RiftEnded",
	"RiftWorld",
	"RiftRequest",
	"EvolveCreature",
	"BuyItem",
	"EquipItem",
	"UnequipItem",
	"BreedCreatures",
	"BreedResult",
	"RebirthRequest",
	"RebirthPreview",
	"RebirthConfirm",
	"UpgradeSanctuary",
	"SetCompanion",
	"QuestsSync",
	"QuestClaim",
	"TutorialComplete",
	"OrbClaimed",
	"SkillBuy",
	"FriendsSync",
	"JoinFriend",
	"BoostState",
	"EclipseState",
	"GlobalDrop",
	"GlobalStats",
	"MarketList",
	"MarketListings",
	"MarketBuy",
	"MarketRemove",
	"MarketSync",
	"DuelChallenge",
	"DuelAccept",
	"DuelDecline",
	"DuelRequest",
	"DuelResult",
	"PolicyState",
	"SeasonSync",
	"SeasonRequest",
	"SeasonClaim",
	"LeaderboardRequest",
	"LeaderboardSync",
	"LeaderboardVisit",
	"LeaderboardDetail",
}

function Net.EnsureRemotes()
	if not RunService:IsServer() then
		return
	end
	for _, name in NAMES do
		if not Remotes:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = Remotes
		end
	end
end

local function Event(name: string): RemoteEvent
	local existing = Remotes:FindFirstChild(name)
	if existing then
		return existing :: RemoteEvent
	end
	if RunService:IsServer() then
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = Remotes
		return remote
	end
	return Remotes:WaitForChild(name) :: RemoteEvent
end

Net.BuyEgg = Event("BuyEgg")
Net.PlaceEgg = Event("PlaceEgg")
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
Net.SetCompanion = Event("SetCompanion")
Net.QuestsSync = Event("QuestsSync")
Net.QuestClaim = Event("QuestClaim")
Net.TutorialComplete = Event("TutorialComplete")
Net.OrbClaimed = Event("OrbClaimed")
Net.SkillBuy = Event("SkillBuy")

Net.FriendsSync = Event("FriendsSync")
Net.JoinFriend = Event("JoinFriend")

Net.BoostState = Event("BoostState")
Net.EclipseState = Event("EclipseState")

Net.GlobalDrop = Event("GlobalDrop")
Net.GlobalStats = Event("GlobalStats")

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
Net.PolicyState = Event("PolicyState")

return Net
