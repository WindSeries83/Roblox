--!strict

local RemoteRegistry = {}

RemoteRegistry.Names = {
	"BuyEgg",
	"PlaceEgg",
	"StartIncubation",
	"ClaimIncubation",
	"RiftAttack",
	"Sync",
	"EconomySync",
	"ActionResult",
	"HatchResult",
	"RareDrop",
	"RiftSync",
	"RiftEnded",
	"RiftWorld",
	"RiftRequest",
	"ExpeditionRequest",
	"ExpeditionAction",
	"ExpeditionSync",
	"ExpeditionEnded",
	"RushStart",
	"RushComplete",
	"RushClaim",
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
	"AssignSanctuary",
	"CollectSanctuary",
	"InviteSanctuary",
	"VisitSanctuary",
	"SetDuelDefense",
	"QuestsSync",
	"QuestClaim",
	"TutorialComplete",
	"OrbClaimed",
	"SkillBuy",
	"FriendsSync",
	"JoinFriend",
	"InviteFriend",
	"RespondFriendInvite",
	"FriendInvite",
	"VisitPlot",
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
	"SeasonSync",
	"SeasonRequest",
	"SeasonClaim",
	"LeaderboardRequest",
	"LeaderboardSync",
	"LeaderboardVisit",
	"LeaderboardDetail",
	"SecretRitual",
	"SetTitle",
}

function RemoteRegistry.Validate(names: { string }): boolean
	local seen = {}
	for _, name in names do
		if type(name) ~= "string" or name == "" or seen[name] then
			return false
		end
		seen[name] = true
	end
	return true
end

return RemoteRegistry
