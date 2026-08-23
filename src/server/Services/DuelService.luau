local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DuelSim = require(ReplicatedStorage.Shared.DuelSim)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Net = require(ReplicatedStorage.Shared.Net)

local DuelService = {}

local log
local saveService
local essenceService
local dataSync

local challenges: { [string]: any } = {}
local cooldowns: { [Player]: { [string]: number } } = {}

local function Refund(challenge: any)
	essenceService:Add(Players:GetPlayerByUserId(challenge.ChallengerUserId), challenge.Wager, "DuelRefund")
	challenges[challenge.Id] = nil
end

local function TeamCreatures(player: Player, teamIds: { string }): { any }
	local profile = saveService:GetProfile(player)
	if not profile then
		return nil
	end
	local team = {}
	for _, creatureId in teamIds do
		local found = Gameplay.FindCreature(profile.Data.Creatures, creatureId)
		if not found then
			return nil
		end
		table.insert(team, found)
	end
	return team
end

function DuelService:Init(container)
	log = container:Get("Log")
	saveService = container:Get("SaveService")
	essenceService = container:Get("EssenceService")
	dataSync = container:Get("DataSync")
end

function DuelService:Start()
	Net.DuelChallenge.OnServerEvent:Connect(function(player: Player, targetName: any, wager: any, teamIds: any)
		if not Gameplay.CheckCooldown(cooldowns, player, "Challenge", Config.DUEL_COOLDOWN) then
			return
		end
		if typeof(targetName) ~= "string" or typeof(teamIds) ~= "table" then
			return
		end
		if
			type(wager) ~= "number"
			or wager ~= wager
			or math.floor(wager) ~= wager
			or wager < Config.DUEL_MIN_WAGER
			or wager > Config.DUEL_MAX_WAGER
		then
			return
		end
		if #teamIds < 1 or #teamIds > Config.DUEL_MAX_TEAM then
			return
		end

		local target = Players:FindFirstChild(targetName)
		if not target or target == player then
			log:Economy("Duel", "ChallengeRejected", { Player = player.Name, Reason = "Cible invalide" })
			return
		end
		if not saveService:GetProfile(target) then
			return
		end

		local team = TeamCreatures(player, teamIds)
		if not team then
			log:Economy("Duel", "ChallengeRejected", { Player = player.Name, Reason = "Équipe invalide" })
			return
		end
		local attackPower = DuelSim.TeamPower(team)
		if attackPower <= 0 then
			log:Economy("Duel", "ChallengeRejected", { Player = player.Name, Reason = "Équipe sans puissance" })
			return
		end
		if not essenceService:Spend(player, wager, "DuelWager") then
			log:Economy("Duel", "ChallengeRejected", { Player = player.Name, Reason = "Fonds insuffisants" })
			return
		end

		local challenge = {
			Id = HttpService:GenerateGUID(false),
			ChallengerUserId = player.UserId,
			ChallengerName = player.Name,
			TargetUserId = target.UserId,
			Wager = wager,
			AttackPower = attackPower,
			Seed = os.time() * 1000 + Random.new():NextInteger(0, 999),
			ExpiresAt = os.time() + Config.DUEL_TIMEOUT,
		}
		challenges[challenge.Id] = challenge
		Net.DuelRequest:FireClient(target, {
			Id = challenge.Id,
			ChallengerName = challenge.ChallengerName,
			Wager = challenge.Wager,
			AttackPower = challenge.AttackPower,
		})
		log:Economy("Duel", "Challenge", {
			Player = player.Name,
			Target = target.Name,
			Wager = wager,
			AttackPower = attackPower,
		})
	end)

	Net.DuelAccept.OnServerEvent:Connect(function(player: Player, challengeId: any)
		if typeof(challengeId) ~= "string" then
			return
		end
		local challenge = challenges[challengeId]
		if not challenge or challenge.TargetUserId ~= player.UserId or os.time() > challenge.ExpiresAt then
			return
		end
		if not essenceService:Spend(player, challenge.Wager, "DuelWager") then
			Refund(challenge)
			log:Economy("Duel", "AcceptRejected", { Player = player.Name, Reason = "Fonds insuffisants" })
			return
		end

		local defenderProfile = saveService:GetProfile(player)
		local defensePower = DuelSim.TeamPower(defenderProfile.Data.Creatures)
		local attacker = Players:GetPlayerByUserId(challenge.ChallengerUserId)
		challenges[challenge.Id] = nil

		local attackerWon = DuelSim.Resolve(challenge.AttackPower, defensePower, challenge.Seed)
		local winner = if attackerWon then attacker else player
		essenceService:Add(winner, challenge.Wager * 2, "DuelWin")

		local attackerProfile = saveService:GetProfile(attacker)
		if attackerWon then
			attackerProfile.Data.Stats.DuelsWon += 1
			defenderProfile.Data.Stats.DuelsLost += 1
		else
			attackerProfile.Data.Stats.DuelsLost += 1
			defenderProfile.Data.Stats.DuelsWon += 1
		end

		Net.DuelResult:FireClient(attacker, {
			Won = attackerWon,
			Wager = challenge.Wager,
			AttackPower = challenge.AttackPower,
			DefensePower = defensePower,
			OpponentName = player.Name,
		})
		Net.DuelResult:FireClient(player, {
			Won = not attackerWon,
			Wager = challenge.Wager,
			AttackPower = challenge.AttackPower,
			DefensePower = defensePower,
			OpponentName = challenge.ChallengerName,
		})
		dataSync:Send(attacker)
		dataSync:Send(player)

		log:Economy("Duel", "Resolved", {
			Challenger = challenge.ChallengerName,
			Defender = player.Name,
			Wager = challenge.Wager,
			AttackPower = challenge.AttackPower,
			DefensePower = defensePower,
			Winner = winner.Name,
		})
	end)

	Net.DuelDecline.OnServerEvent:Connect(function(player: Player, challengeId: any)
		if typeof(challengeId) ~= "string" then
			return
		end
		local challenge = challenges[challengeId]
		if not challenge or challenge.TargetUserId ~= player.UserId then
			return
		end
		Refund(challenge)
		local attacker = Players:GetPlayerByUserId(challenge.ChallengerUserId)
		if attacker then
			Net.DuelResult:FireClient(attacker, {
				Won = false,
				Reason = "declined",
				OpponentName = player.Name,
			})
			dataSync:Send(attacker)
		end
		log:Economy("Duel", "Declined", {
			Challenger = challenge.ChallengerName,
			Defender = player.Name,
			Wager = challenge.Wager,
		})
	end)

	Players.PlayerRemoving:Connect(function(player)
		cooldowns[player] = nil
		for _, challenge in challenges do
			if challenge.TargetUserId == player.UserId or challenge.ChallengerUserId == player.UserId then
				if challenge.ChallengerUserId == player.UserId then
					challenges[challenge.Id] = nil
				else
					Refund(challenge)
				end
			end
		end
	end)

	task.spawn(function()
		while true do
			task.wait(5)
			local now = os.time()
			for _, challenge in challenges do
				if now > challenge.ExpiresAt then
					Refund(challenge)
					log:Economy("Duel", "Expired", {
						Challenger = challenge.ChallengerName,
						Wager = challenge.Wager,
					})
				end
			end
		end
	end)
end

return DuelService
