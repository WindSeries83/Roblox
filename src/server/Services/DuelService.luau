--!strict

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DuelSim = require(ReplicatedStorage.Shared.DuelSim)
local DuelTransaction = require(ReplicatedStorage.Shared.DuelTransaction)
local FeatureUnlocks = require(ReplicatedStorage.Shared.FeatureUnlocks)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Net = require(ReplicatedStorage.Shared.Net)
local PurchaseLedger = require(ReplicatedStorage.Shared.PurchaseLedger)
local SafeStore = require(script.Parent.SafeStore)

local DuelService = {}

local log
local saveService
local essenceService
local dataSync
local analyticsService
local cooldowns: { [Player]: { [string]: number } } = {}
local requestedAt: { [string]: number } = {}

local TransactionStore = SafeStore.Get("RiftBeastsDuelTransactions_v2", nil)
local ActiveStore = SafeStore.Get("RiftBeastsDuelTransactions_v2", {})

local function Key(id: string): string
	return `Challenge_{id}`
end

local function Error(player: Player, action: string, reason: string)
	Net.ActionResult:FireClient(player, { Success = false, Action = action, Reason = reason })
	log:Economy("Duel", "Rejected", { Player = player.Name, Action = action, Reason = reason })
end

local function Track(id: string, fromState: string, toState: string)
	if analyticsService then
		analyticsService:Event("duel_transition", { ChallengeId = id, From = fromState, To = toState })
	end
	log:Economy("Duel", "Transition", { ChallengeId = id, From = fromState, To = toState })
end

local function GetRecord(id: string): any?
	local record
	local ok = pcall(function()
		record = TransactionStore:GetAsync(Key(id))
	end)
	if ok and type(record) == "table" and record.Id == id then
		return record
	end
	return nil
end

local function PutRecord(record: any): boolean
	local result
	local ok = pcall(function()
		result = TransactionStore:UpdateAsync(Key(record.Id), function(old)
			if old ~= nil then
				return nil
			end
			return record
		end)
	end)
	return ok and type(result) == "table" and result.Id == record.Id and result.State == "Created"
end

local function UpdateRecord(id: string, expected: any, nextState: any, patch: { [string]: any }?): (boolean, any?)
	local fromState: string? = nil
	local result
	local ok = pcall(function()
		result = TransactionStore:UpdateAsync(Key(id), function(record)
			if type(record) ~= "table" then
				return nil
			end
			fromState = record.State
			if DuelTransaction.Transition(record, expected, nextState, patch) then
				return record
			end
			return nil
		end)
	end)
	if not ok or type(result) ~= "table" or result.Id ~= id then
		return false, nil
	end
	if fromState and fromState ~= nextState then
		Track(id, fromState, nextState)
	end
	return true, result
end

local function ActiveIds(): { string }
	local value
	local ok = pcall(function()
		value = ActiveStore:GetAsync("Active")
	end)
	if not ok or type(value) ~= "table" then
		return {}
	end
	local result = {}
	for _, id in value do
		if type(id) == "string" and #result < Config.DUEL_ACTIVE_SCAN_LIMIT then
			table.insert(result, id)
		end
	end
	return result
end

local function AddActive(id: string): boolean
	local result
	local ok = pcall(function()
		result = ActiveStore:UpdateAsync("Active", function(old)
			local ids = if type(old) == "table" then table.clone(old) else {}
			if table.find(ids, id) then
				return ids
			end
			if #ids >= Config.DUEL_ACTIVE_SCAN_LIMIT then
				return nil
			end
			table.insert(ids, id)
			return ids
		end)
	end)
	return ok and type(result) == "table" and table.find(result, id) ~= nil
end

local function RemoveActive(id: string)
	pcall(function()
		ActiveStore:UpdateAsync("Active", function(old)
			local ids = {}
			if type(old) == "table" then
				for _, item in old do
					if item ~= id then
						table.insert(ids, item)
					end
				end
			end
			return ids
		end)
	end)
	requestedAt[id] = nil
end

local function SameIds(actual: any, expected: { string }): boolean
	if type(actual) ~= "table" or #actual ~= #expected then
		return false
	end
	for index, id in expected do
		if actual[index] ~= id then
			return false
		end
	end
	return true
end

local function SaveMutation(
	player: Player,
	snapshot: any,
	proof: (any) -> boolean,
	rollbackProof: (any) -> boolean
): (boolean, boolean)
	if saveService:SaveProfile(player, proof) then
		return true, true
	end
	local profile = saveService:GetProfile(player)
	if profile then
		local mutated = PurchaseLedger.Snapshot(profile.Data)
		PurchaseLedger.Restore(profile.Data, snapshot)
		local rolledBack = saveService:SaveProfile(player, rollbackProof)
		if not rolledBack then
			PurchaseLedger.Restore(profile.Data, mutated)
		end
		return false, rolledBack
	end
	return false, false
end

local function TeamFromData(data: any, ids: any): { any }?
	if type(data) ~= "table" or type(data.Creatures) ~= "table" or type(ids) ~= "table" then
		return nil
	end
	if #ids < 1 or #ids > Config.DUEL_MAX_TEAM then
		return nil
	end
	local team = {}
	local seen: { [string]: boolean } = {}
	for index = 1, #ids do
		local id = ids[index]
		if type(id) ~= "string" or id == "" or seen[id] then
			return nil
		end
		seen[id] = true
		local creature = Gameplay.FindCreature(data.Creatures, id)
		if not creature then
			return nil
		end
		table.insert(team, creature)
	end
	return team
end

local function TeamCreatures(player: Player, ids: any): { any }?
	local profile = saveService:GetProfile(player)
	return profile and TeamFromData(profile.Data, ids) or nil
end

local function DefenseCreatures(profile: any): { any }?
	if not profile then
		return nil
	end
	local ids = profile.Data.DuelDefense
	if type(ids) ~= "table" or #ids == 0 then
		ids = {}
		for index, creature in profile.Data.Creatures do
			if index > Config.DUEL_MAX_TEAM then
				break
			end
			table.insert(ids, creature.Id)
		end
	end
	return TeamFromData(profile.Data, ids)
end

local function PersistDefense(player: Player, ids: { string }): boolean
	local profile = saveService:GetProfile(player)
	if not profile then
		return false
	end
	local snapshot = PurchaseLedger.Snapshot(profile.Data)
	local previous = table.clone(profile.Data.DuelDefense or {})
	profile.Data.DuelDefense = table.clone(ids)
	return SaveMutation(player, snapshot, function(data)
		return SameIds(data.DuelDefense, ids)
	end, function(data)
		return SameIds(data.DuelDefense, previous)
	end)
end

local function PersistEscrow(player: Player, id: string, amount: number, marker: string): boolean
	local profile = saveService:GetProfile(player)
	if not profile then
		return false
	end
	profile.Data.DuelLedger = profile.Data.DuelLedger or {}
	if profile.Data.DuelLedger[id] == marker then
		return true
	end
	local snapshot = PurchaseLedger.Snapshot(profile.Data)
	if not essenceService:Spend(player, amount, `DuelEscrow_{id}`) then
		return false
	end
	profile.Data.DuelLedger[id] = marker
	return SaveMutation(player, snapshot, function(data)
		return data.DuelLedger and data.DuelLedger[id] == marker
	end, function(data)
		return data.DuelLedger and data.DuelLedger[id] == snapshot.DuelLedger[id]
	end)
end

local function PersistRefund(player: Player, record: any): boolean
	local profile = saveService:GetProfile(player)
	if not profile then
		return false
	end
	profile.Data.DuelLedger = profile.Data.DuelLedger or {}
	if profile.Data.DuelLedger[record.Id] == "DuelRefundApplied" then
		return true
	end
	if profile.Data.DuelLedger[record.Id] ~= "ChallengerEscrowed" then
		return true
	end
	local snapshot = PurchaseLedger.Snapshot(profile.Data)
	profile.Data.DuelLedger[record.Id] = "DuelRefundApplied"
	profile.Data.Essence += record.Wager
	profile.Data.Stats.TotalEssenceEarned += record.Wager
	profile.Data.LastPlayed = os.time()
	return SaveMutation(player, snapshot, function(data)
		return data.DuelLedger and data.DuelLedger[record.Id] == "DuelRefundApplied"
	end, function(data)
		return data.DuelLedger and data.DuelLedger[record.Id] == snapshot.DuelLedger[record.Id]
	end)
end

local function QueueSettlement(record: any, userId: number, role: string, amount: number): boolean
	return saveService:QueueProfileMessage(userId, {
		Type = "DuelSettlement",
		ChallengeId = record.Id,
		Role = role,
		Amount = amount,
	})
end

local function ApplyWinner(record: any): boolean
	local player = Players:GetPlayerByUserId(record.WinnerUserId)
	if not player or not saveService:GetProfile(player) then
		return QueueSettlement(record, record.WinnerUserId, "Winner", record.Wager * 2)
	end
	local profile = saveService:GetProfile(player)
	profile.Data.DuelLedger = profile.Data.DuelLedger or {}
	if profile.Data.DuelLedger[record.Id] ~= "DuelWinnerApplied" then
		local snapshot = PurchaseLedger.Snapshot(profile.Data)
		profile.Data.DuelLedger[record.Id] = "DuelWinnerApplied"
		profile.Data.Essence += record.Wager * 2
		profile.Data.Stats.TotalEssenceEarned += record.Wager * 2
		profile.Data.Stats.DuelsWon += 1
		profile.Data.DuelSeason.Rating += 25
		profile.Data.DuelSeason.Wins += 1
		profile.Data.LastPlayed = os.time()
		if
			not SaveMutation(player, snapshot, function(data)
				return data.DuelLedger and data.DuelLedger[record.Id] == "DuelWinnerApplied"
			end, function(data)
				return data.DuelLedger and data.DuelLedger[record.Id] == snapshot.DuelLedger[record.Id]
			end)
		then
			return false
		end
	end
	dataSync:Send(player)
	return true
end

local function ApplyLoser(record: any): boolean
	local player = Players:GetPlayerByUserId(record.LoserUserId)
	if not player or not saveService:GetProfile(player) then
		return QueueSettlement(record, record.LoserUserId, "Loser", 0)
	end
	local profile = saveService:GetProfile(player)
	profile.Data.DuelLedger = profile.Data.DuelLedger or {}
	if profile.Data.DuelLedger[record.Id] ~= "DuelLoserApplied" then
		local snapshot = PurchaseLedger.Snapshot(profile.Data)
		profile.Data.DuelLedger[record.Id] = "DuelLoserApplied"
		profile.Data.Stats.DuelsLost += 1
		profile.Data.DuelSeason.Rating = math.max(0, profile.Data.DuelSeason.Rating - 15)
		profile.Data.DuelSeason.Losses += 1
		profile.Data.LastPlayed = os.time()
		if
			not SaveMutation(player, snapshot, function(data)
				return data.DuelLedger and data.DuelLedger[record.Id] == "DuelLoserApplied"
			end, function(data)
				return data.DuelLedger and data.DuelLedger[record.Id] == snapshot.DuelLedger[record.Id]
			end)
		then
			return false
		end
	end
	dataSync:Send(player)
	return true
end

local function Settle(record: any)
	if record.State == "Resolved" then
		local ok, updated = UpdateRecord(record.Id, "Resolved", "WinnerApplied")
		if not ok then
			return
		end
		record = updated
	end
	if record.State == "WinnerApplied" then
		if not ApplyWinner(record) then
			return
		end
		local ok, updated = UpdateRecord(record.Id, "WinnerApplied", "LoserApplied")
		if not ok then
			return
		end
		record = updated
	end
	if record.State == "LoserApplied" and ApplyLoser(record) then
		local ok = UpdateRecord(record.Id, "LoserApplied", "Settled")
		if ok then
			RemoveActive(record.Id)
		end
	end
end

local function Refund(record: any)
	if record.State ~= "Declined" and record.State ~= "TimedOut" then
		return
	end
	local refunded = true
	if record.HasChallengerEscrow == true then
		local player = Players:GetPlayerByUserId(record.ChallengerUserId)
		refunded = if player and saveService:GetProfile(player)
			then PersistRefund(player, record)
			else QueueSettlement(record, record.ChallengerUserId, "Refund", record.Wager)
	end
	if not refunded then
		return
	end
	local ok = UpdateRecord(record.Id, record.State, "RefundApplied")
	if not ok then
		return
	end
	local settled = UpdateRecord(record.Id, "RefundApplied", "Settled")
	if settled then
		RemoveActive(record.Id)
		local player = Players:GetPlayerByUserId(record.ChallengerUserId)
		if player then
			dataSync:Send(player)
		end
	end
end

local function ResolveAccepted(record: any): boolean
	if record.State ~= "Accepted" then
		return record.State == "Resolved" or record.State == "WinnerApplied" or record.State == "LoserApplied"
	end
	local attackerWon = DuelSim.Resolve(record.AttackPower, record.DefensePower, record.Seed)
	local winner = if attackerWon then record.ChallengerUserId else record.TargetUserId
	local loser = if attackerWon then record.TargetUserId else record.ChallengerUserId
	local ok = UpdateRecord(record.Id, "Accepted", "Resolved", {
		WinnerUserId = winner,
		LoserUserId = loser,
		AttackerWon = attackerWon,
		ResolvedAt = os.time(),
	})
	return ok
end

local function Expire(record: any)
	if not DuelTransaction.CanExpire(record, os.time()) then
		return
	end
	local ok, updated = UpdateRecord(record.Id, record.State, "TimedOut", { TimedOutAt = os.time() })
	if ok and updated then
		Refund(updated)
	end
end

local function SendRequest(record: any)
	if record.State ~= "ChallengerEscrowed" then
		return
	end
	local player = Players:GetPlayerByUserId(record.TargetUserId)
	if not player then
		return
	end
	local now = os.clock()
	if now - (requestedAt[record.Id] or 0) < 5 then
		return
	end
	requestedAt[record.Id] = now
	Net.DuelRequest:FireClient(player, {
		Id = record.Id,
		ChallengerName = record.ChallengerName,
		Wager = record.Wager,
		AttackPower = record.AttackPower,
		ExpiresAt = record.ExpiresAt,
	})
end

local function Process(record: any)
	if record.State == "Created" then
		local challenger = Players:GetPlayerByUserId(record.ChallengerUserId)
		local profile = if challenger then saveService:GetProfile(challenger) else nil
		if profile and profile.Data.DuelLedger and profile.Data.DuelLedger[record.Id] == "ChallengerEscrowed" then
			local recovered, stored = UpdateRecord(record.Id, "Created", "ChallengerEscrowed", {
				HasChallengerEscrow = true,
			})
			if recovered and stored then
				SendRequest(stored)
			end
		elseif DuelTransaction.CanExpire(record, os.time()) then
			Expire(record)
		end
	elseif record.State == "ChallengerEscrowed" then
		if DuelTransaction.CanExpire(record, os.time()) then
			Expire(record)
		else
			SendRequest(record)
		end
	elseif record.State == "Accepted" then
		if ResolveAccepted(record) then
			local resolved = GetRecord(record.Id)
			if resolved then
				Settle(resolved)
			end
		end
	elseif record.State == "Resolved" or record.State == "WinnerApplied" or record.State == "LoserApplied" then
		Settle(record)
	elseif record.State == "Declined" or record.State == "TimedOut" then
		Refund(record)
	elseif DuelTransaction.IsTerminal(record) then
		RemoveActive(record.Id)
	end
end

local function OnChallenge(player: Player, targetName: any, wager: any, teamIds: any)
	local profile = saveService:GetProfile(player)
	local unlocked, reason
	if profile then
		unlocked, reason = FeatureUnlocks.Require(profile.Data, "Duels")
	else
		unlocked, reason = false, "Profil indisponible."
	end
	if not unlocked then
		Error(player, "DuelChallenge", reason or "Les duels sont verrouillés.")
		return
	end
	if not Gameplay.CheckCooldown(cooldowns, player, "Challenge", Config.DUEL_COOLDOWN) then
		return
	end
	if typeof(targetName) ~= "string" or typeof(teamIds) ~= "table" then
		Error(player, "DuelChallenge", "Cible ou équipe invalide.")
		return
	end
	if
		type(wager) ~= "number"
		or wager ~= wager
		or math.floor(wager) ~= wager
		or wager < Config.DUEL_MIN_WAGER
		or wager > Config.DUEL_MAX_WAGER
	then
		Error(player, "DuelChallenge", "Mise invalide.")
		return
	end
	local target = Players:FindFirstChild(targetName)
	local targetProfile = if target then saveService:GetProfile(target) else nil
	local targetUnlocked = targetProfile and FeatureUnlocks.Require(targetProfile.Data, "Duels")
	if not target or target == player or not targetProfile or not targetUnlocked then
		Error(player, "DuelChallenge", "Cet adversaire n'est pas disponible pour les duels.")
		return
	end
	local team = TeamCreatures(player, teamIds)
	if not team or DuelSim.TeamPower(team) <= 0 then
		Error(player, "DuelChallenge", "Équipe attaquante invalide.")
		return
	end
	local id = HttpService:GenerateGUID(false)
	local record = DuelTransaction.New({
		Id = id,
		ChallengerUserId = player.UserId,
		ChallengerName = player.Name,
		TargetUserId = target.UserId,
		TargetName = target.Name,
		Wager = wager,
		AttackTeam = PurchaseLedger.Snapshot(team),
		AttackPower = DuelSim.TeamPower(team),
		Seed = os.time() * 1000 + Random.new():NextInteger(0, 999),
		CreatedAt = os.time(),
		ExpiresAt = os.time() + Config.DUEL_TIMEOUT,
		-- If a later save/state update fails, timeout recovery only refunds when
		-- the profile ledger proves that this expected escrow was actually debited.
		HasChallengerEscrow = true,
	})
	if not PutRecord(record) or not AddActive(id) then
		UpdateRecord(id, "Created", "Cancelled")
		Error(player, "DuelChallenge", "Le duel n'a pas pu être enregistré. Réessaie.")
		return
	end
	local snapshot = PurchaseLedger.Snapshot(profile.Data)
	if not essenceService:Spend(player, wager, `DuelEscrow_{id}`) then
		UpdateRecord(id, "Created", "Cancelled")
		RemoveActive(id)
		Error(player, "DuelChallenge", "Fonds insuffisants.")
		return
	end
	profile.Data.DuelLedger = profile.Data.DuelLedger or {}
	profile.Data.DuelLedger[id] = "ChallengerEscrowed"
	local saved, rolledBack = SaveMutation(player, snapshot, function(data)
		return data.DuelLedger and data.DuelLedger[id] == "ChallengerEscrowed"
	end, function(data)
		return data.DuelLedger and data.DuelLedger[id] == snapshot.DuelLedger[id]
	end)
	if not saved then
		if rolledBack then
			UpdateRecord(id, "Created", "Cancelled")
			RemoveActive(id)
		end
		Error(player, "DuelChallenge", "Sauvegarde de la mise impossible, aucun duel lancé.")
		return
	end
	local escrowed, stored = UpdateRecord(id, "Created", "ChallengerEscrowed", { HasChallengerEscrow = true })
	if not escrowed or not stored then
		Error(player, "DuelChallenge", "Le duel attend la confirmation du stockage.")
		return
	end
	SendRequest(stored)
end

local function OnAccept(player: Player, id: any)
	if typeof(id) ~= "string" then
		return
	end
	local record = GetRecord(id)
	if not record or record.TargetUserId ~= player.UserId then
		Error(player, "DuelAccept", "Défi introuvable ou déjà traité.")
		return
	end
	local profile = saveService:GetProfile(player)
	local unlocked, reason
	if profile then
		unlocked, reason = FeatureUnlocks.Require(profile.Data, "Duels")
	else
		unlocked, reason = false, "Profil indisponible."
	end
	if not unlocked then
		Error(player, "DuelAccept", reason or "Les duels sont verrouillés.")
		return
	end
	if os.time() > record.ExpiresAt then
		Expire(record)
		Error(player, "DuelAccept", "Ce défi a expiré.")
		return
	end
	if record.State ~= "ChallengerEscrowed" then
		Error(player, "DuelAccept", "Ce défi a déjà été traité.")
		return
	end
	local defense = DefenseCreatures(profile)
	if not defense or DuelSim.TeamPower(defense) <= 0 then
		Error(player, "DuelAccept", "Ta défense doit contenir une créature valide.")
		return
	end
	if not PersistEscrow(player, record.Id, record.Wager, "DefenderEscrowed") then
		Error(player, "DuelAccept", "Mise insuffisante ou sauvegarde impossible.")
		return
	end
	local accepted, stored = UpdateRecord(record.Id, "ChallengerEscrowed", "Accepted", {
		DefenseTeam = PurchaseLedger.Snapshot(defense),
		DefensePower = DuelSim.TeamPower(defense),
		HasDefenderEscrow = true,
		AcceptedAt = os.time(),
	})
	if not accepted or not stored then
		Error(player, "DuelAccept", "Le dépôt est confirmé; le duel sera repris automatiquement.")
		return
	end
	if not ResolveAccepted(stored) then
		return
	end
	local resolved = GetRecord(record.Id)
	if not resolved then
		return
	end
	Settle(resolved)
	local payload = {
		Wager = resolved.Wager,
		AttackPower = resolved.AttackPower,
		DefensePower = resolved.DefensePower,
	}
	local attacker = Players:GetPlayerByUserId(resolved.ChallengerUserId)
	local defender = Players:GetPlayerByUserId(resolved.TargetUserId)
	if attacker then
		local result = table.clone(payload)
		result.Won = resolved.WinnerUserId == attacker.UserId
		result.OpponentName = resolved.TargetName
		Net.DuelResult:FireClient(attacker, result)
	end
	if defender then
		local result = table.clone(payload)
		result.Won = resolved.WinnerUserId == defender.UserId
		result.OpponentName = resolved.ChallengerName
		Net.DuelResult:FireClient(defender, result)
	end
end

local function OnDecline(player: Player, id: any)
	if typeof(id) ~= "string" then
		return
	end
	local record = GetRecord(id)
	if not record or record.TargetUserId ~= player.UserId then
		Error(player, "DuelDecline", "Défi introuvable ou déjà traité.")
		return
	end
	local profile = saveService:GetProfile(player)
	if not profile or not FeatureUnlocks.Require(profile.Data, "Duels") then
		Error(player, "DuelDecline", "Les duels sont verrouillés.")
		return
	end
	if record.State ~= "Created" and record.State ~= "ChallengerEscrowed" then
		Error(player, "DuelDecline", "Ce duel est déjà accepté ou réglé.")
		return
	end
	local declined, stored = UpdateRecord(id, record.State, "Declined", { DeclinedAt = os.time() })
	if not declined or not stored then
		return
	end
	Refund(stored)
	local attacker = Players:GetPlayerByUserId(record.ChallengerUserId)
	if attacker then
		Net.DuelResult:FireClient(attacker, { Won = false, Reason = "declined", OpponentName = player.Name })
	end
end

function DuelService:Init(container)
	log = container:Get("Log")
	saveService = container:Get("SaveService")
	essenceService = container:Get("EssenceService")
	dataSync = container:Get("DataSync")
	analyticsService = container:Get("AnalyticsService")
end

function DuelService:Start()
	Net.SetDuelDefense.OnServerEvent:Connect(function(player: Player, ids: any)
		local profile = saveService:GetProfile(player)
		local unlocked, reason
		if profile then
			unlocked, reason = FeatureUnlocks.Require(profile.Data, "Duels")
		else
			unlocked, reason = false, "Profil indisponible."
		end
		if not unlocked then
			Error(player, "SetDuelDefense", reason or "Les duels sont verrouillés.")
			return
		end
		local team = TeamCreatures(player, ids)
		if not team then
			Error(player, "SetDuelDefense", "Équipe de défense invalide.")
			return
		end
		local validIds = {}
		for _, creature in team do
			table.insert(validIds, creature.Id)
		end
		if not PersistDefense(player, validIds) then
			Error(player, "SetDuelDefense", "La défense n'a pas été sauvegardée.")
			return
		end
		Net.ActionResult:FireClient(player, { Success = true, Action = "SetDuelDefense" })
		dataSync:Send(player)
	end)
	Net.DuelChallenge.OnServerEvent:Connect(OnChallenge)
	Net.DuelAccept.OnServerEvent:Connect(OnAccept)
	Net.DuelDecline.OnServerEvent:Connect(OnDecline)

	local function ProcessPlayer(player: Player)
		task.spawn(function()
			for _ = 1, 20 do
				if not player:IsDescendantOf(Players) then
					return
				end
				if saveService:GetProfile(player) then
					for _, id in ActiveIds() do
						local record = GetRecord(id)
						if
							record
							and (record.TargetUserId == player.UserId or record.ChallengerUserId == player.UserId)
						then
							Process(record)
						end
					end
					return
				end
				task.wait(0.5)
			end
		end)
	end

	for _, player in Players:GetPlayers() do
		ProcessPlayer(player)
	end
	Players.PlayerAdded:Connect(ProcessPlayer)
	Players.PlayerRemoving:Connect(function(player)
		cooldowns[player] = nil
		for _, id in ActiveIds() do
			local record = GetRecord(id)
			if record and record.ChallengerUserId == player.UserId then
				requestedAt[id] = nil
			end
		end
	end)

	task.spawn(function()
		while true do
			task.wait(5)
			for _, id in ActiveIds() do
				local record = GetRecord(id)
				if record then
					Process(record)
				else
					RemoveActive(id)
				end
			end
		end
	end)
end

return DuelService
