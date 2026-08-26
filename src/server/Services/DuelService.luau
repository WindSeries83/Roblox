local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DuelSim = require(ReplicatedStorage.Shared.DuelSim)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Net = require(ReplicatedStorage.Shared.Net)

local SafeStore = require(script.Parent.SafeStore)

local DuelService = {}

local log
local saveService
local essenceService
local dataSync

local challenges: { [string]: any } = {}
local cooldowns: { [Player]: { [string]: number } } = {}

local EscrowStore = SafeStore.Get("RiftBeastsDuels_v1", 0)

-- Clé partagée Escrow_{userId} : plusieurs défis simultanés d'un même joueur
-- s'additionnent dans la même clé (somme exacte) — ne pas passer à une clé par défi.
-- L'escrow vit dans le DataStore : un challenger qui quitte le jeu est
-- remboursé exactement une fois, même hors ligne (AUD-P0-03).
local function EscrowAdjust(userId: number, delta: number)
	local ok, err = pcall(function()
		EscrowStore:UpdateAsync(`Escrow_{userId}`, function(old)
			return math.max(0, (old or 0) + delta)
		end)
	end)
	if not ok then
		warn("[Duel] Escrow store failure:", err) -- flux d'argent : on veut le voir
	end
end

local function TakeEscrow(userId: number): number
	local taken = 0
	local ok, err = pcall(function()
		EscrowStore:UpdateAsync(`Escrow_{userId}`, function(old)
			taken = old or 0
			return 0
		end)
	end)
	if not ok then
		warn("[Duel] Escrow store failure:", err)
		return 0 -- échec store : rien pris, l'escrow reste intacte et sera créditée plus tard
	end
	return taken
end

local function CreditEscrowIfOnline(userId: number, source: string)
	local player = Players:GetPlayerByUserId(userId)
	if not player then
		return
	end
	-- Profil pas encore chargé : ne PAS drainer le store, l'escrow reste disponible.
	if not saveService:GetProfile(player) then
		return
	end
	local amount = TakeEscrow(userId)
	if amount <= 0 then
		return
	end
	local gained = essenceService:Add(player, amount, source) or 0
	if gained < amount then
		-- Crédit partiel/échoué : différence remise en escrow, rien n'est perdu.
		EscrowAdjust(userId, amount - gained)
	end
	if gained > 0 then
		dataSync:Send(player)
	end
end

local function ReleaseEscrow(challenge: any)
	challenges[challenge.Id] = nil
	-- En ligne : remboursement immédiat. Hors ligne : l'escrow reste en store,
	-- crédité à la reconnexion (PlayerAdded).
	CreditEscrowIfOnline(challenge.ChallengerUserId, "DuelRefund")
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
		EscrowAdjust(player.UserId, wager)

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
			ReleaseEscrow(challenge)
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
		TakeEscrow(challenge.ChallengerUserId) -- escrow soldée par le pot, sans re-crédit

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
		ReleaseEscrow(challenge)
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
				-- Challenger parti : escrow libérée (AUD-P0-03). Cible partie : défi mort, remboursement.
				ReleaseEscrow(challenge)
			end
		end
	end)

	-- Rejoin : attendre le profil (chargement async) avant de créditer l'escrow,
	-- ~10 s max. Départ ou profil toujours absent → abandon, l'escrow reste au
	-- store et sera créditée au prochain join.
	local function CreditWhenProfileReady(userId: number)
		for _ = 1, 20 do
			local player = Players:GetPlayerByUserId(userId)
			if not player then
				return
			end
			if saveService:GetProfile(player) then
				CreditEscrowIfOnline(userId, "DuelEscrowRejoin")
				return
			end
			task.wait(0.5)
		end
	end

	for _, player in Players:GetPlayers() do
		task.spawn(CreditWhenProfileReady, player.UserId)
	end
	Players.PlayerAdded:Connect(function(player)
		task.spawn(CreditWhenProfileReady, player.UserId)
	end)

	task.spawn(function()
		while true do
			task.wait(5)
			local now = os.time()
			for _, challenge in challenges do
				if now > challenge.ExpiresAt then
					ReleaseEscrow(challenge)
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
