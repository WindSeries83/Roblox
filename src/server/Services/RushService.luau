local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local PurchaseLedger = require(ReplicatedStorage.Shared.PurchaseLedger)
local Rush = require(ReplicatedStorage.Shared.Rush)
local Worlds = require(ReplicatedStorage.Shared.Worlds)

local RushService = {}

local saveService
local essenceService
local analyticsService
local dataSync
local expiring: { [Player]: boolean } = {}

local function snapshot(player: Player)
	local profile = saveService:GetProfile(player)
	if not profile then
		return nil
	end
	return Rush.Snapshot(profile.Data.Rush and profile.Data.Rush.Active, os.time())
end

local function event(name: string, properties: { [string]: any }, player: Player)
	if analyticsService then
		analyticsService:Event(name, properties, player)
	end
end

local function respond(player: Player, action: string, ok: boolean, reason: string?, payload: any?)
	Net.ActionResult:FireClient(player, {
		Type = "Rush",
		Action = action,
		Ok = ok,
		Reason = reason,
		Rush = payload or snapshot(player),
	})
end

local function reject(player: Player, action: string, reason: string)
	event("rush_reject", { Action = action, Reason = reason }, player)
	respond(player, action, false, reason)
end

local function stateProof(attemptId: string, check: (any, any) -> boolean)
	return function(data)
		local active = data.Rush and data.Rush.Active
		return type(active) == "table" and active.AttemptId == attemptId and check(active, data)
	end
end

local function StartRush(player: Player, worldId: any)
	local profile = saveService:GetProfile(player)
	if not profile then
		return reject(player, "start", "profile_unavailable")
	end
	local current = profile.Data.Rush and profile.Data.Rush.Active
	local allowed, reason = Rush.CanStart(worldId, profile.Data.WorldProgress, profile.Data.Stars or 0, current)
	if not allowed then
		return reject(player, "start", reason or "rejected")
	end
	local world = Worlds.Get(worldId)
	if not world then
		return reject(player, "start", "unknown_world")
	end
	local previous = if type(current) == "table" then table.clone(current) else nil
	local now = os.time()
	local attemptId = HttpService:GenerateGUID(false)
	local state = Rush.Start(worldId, now, attemptId)
	if not state then
		return reject(player, "start", "invalid")
	end
	profile.Data.Rush = profile.Data.Rush or {}
	profile.Data.Rush.Active = state
	profile.Data.LastPlayed = now
	local saved = saveService:SaveProfile(
		player,
		stateProof(attemptId, function(active)
			return active.StartedAt == state.StartedAt and active.EndsAt == state.EndsAt and active.Completed == false
		end)
	)
	if not saved then
		profile.Data.Rush.Active = previous
		return reject(player, "start", "save_failed")
	end
	event("rush_start", { WorldId = world.Id, TargetSeconds = world.Rush.TargetSeconds }, player)
	dataSync:Send(player)
	respond(player, "start", true)
end

local function CompleteRush(player: Player)
	local profile = saveService:GetProfile(player)
	local state = profile and profile.Data.Rush and profile.Data.Rush.Active
	if not profile or type(state) ~= "table" then
		return reject(player, "complete", "not_started")
	end
	local before = table.clone(state)
	local reward, reason = Rush.Complete(state.WorldId, state, os.time())
	if not reward then
		if reason == "timeout" and Rush.Expire(state, os.time()) then
			local saved = saveService:SaveProfile(
				player,
				stateProof(state.AttemptId, function(active)
					return active.Expired == true
				end)
			)
			if not saved then
				profile.Data.Rush.Active = before
				return reject(player, "complete", "save_failed")
			end
			dataSync:Send(player)
		end
		return reject(player, "complete", reason or "rejected")
	end
	local saved = saveService:SaveProfile(
		player,
		stateProof(state.AttemptId, function(active)
			return active.Completed == true and active.Claimed == false
		end)
	)
	if not saved then
		profile.Data.Rush.Active = before
		return reject(player, "complete", "save_failed")
	end
	event("rush_complete", { WorldId = state.WorldId, Duration = state.CompletedAt - state.StartedAt }, player)
	dataSync:Send(player)
	respond(player, "complete", true, nil, { Reward = reward, State = snapshot(player) })
end

local function ClaimRush(player: Player)
	local profile = saveService:GetProfile(player)
	local state = profile and profile.Data.Rush and profile.Data.Rush.Active
	if not profile or type(state) ~= "table" then
		return reject(player, "claim", "not_started")
	end
	if state.Completed ~= true then
		return reject(player, "claim", if state.Expired then "timeout" else "not_completed")
	end
	if state.Claimed == true then
		return reject(player, "claim", "already_claimed")
	end
	local world = Worlds.Get(state.WorldId)
	if not world then
		return reject(player, "claim", "unknown_world")
	end
	local ledgerKey = `Rush:{state.AttemptId}`
	local ledger = profile.Data.EconomyLedger or {}
	profile.Data.EconomyLedger = ledger
	local alreadyGranted = ledger[ledgerKey] == true
	local before = PurchaseLedger.Snapshot(profile.Data)
	if not Rush.Claim(state) then
		return reject(player, "claim", "already_claimed")
	end
	local granted = if alreadyGranted
		then world.Rush.Reward.Essence
		else essenceService:AddOnce(player, world.Rush.Reward.Essence, `Rush_{state.WorldId}`, ledgerKey)
	if granted <= 0 then
		PurchaseLedger.Restore(profile.Data, before)
		return reject(player, "claim", "grant_failed")
	end
	local saved = saveService:SaveProfile(
		player,
		stateProof(state.AttemptId, function(active, data)
			return active.Completed == true
				and active.Claimed == true
				and data.EconomyLedger
				and data.EconomyLedger[ledgerKey] == true
		end)
	)
	if not saved then
		PurchaseLedger.Restore(profile.Data, before)
		return reject(player, "claim", "save_failed")
	end
	event("rush_claim", { WorldId = state.WorldId, Amount = granted }, player)
	dataSync:Send(player)
	respond(player, "claim", true, nil, { Reward = { Essence = granted }, State = snapshot(player) })
end

local function Expire(player: Player)
	if expiring[player] then
		return
	end
	local profile = saveService:GetProfile(player)
	local state = profile and profile.Data.Rush and profile.Data.Rush.Active
	if type(state) ~= "table" or state.Completed == true or state.Claimed == true or state.Expired == true then
		return
	end
	if not Rush.Expire(state, os.time()) then
		return
	end
	expiring[player] = true
	local saved = saveService:SaveProfile(
		player,
		stateProof(state.AttemptId, function(active)
			return active.Expired == true
		end)
	)
	expiring[player] = nil
	if not saved then
		state.Expired = false
		return
	end
	event("rush_reject", { Action = "complete", Reason = "timeout", WorldId = state.WorldId }, player)
	dataSync:Send(player)
end

function RushService:Init(cont)
	saveService = cont:Get("SaveService")
	essenceService = cont:Get("EssenceService")
	analyticsService = cont:Get("AnalyticsService")
	dataSync = cont:Get("DataSync")
end

function RushService:Start()
	Net.RushStart.OnServerEvent:Connect(StartRush)
	Net.RushComplete.OnServerEvent:Connect(CompleteRush)
	Net.RushClaim.OnServerEvent:Connect(ClaimRush)
	Players.PlayerRemoving:Connect(function(player)
		expiring[player] = nil
	end)
	task.spawn(function()
		while true do
			for player in pairs(saveService.Profiles) do
				Expire(player)
			end
			task.wait(1)
		end
	end)
end

return RushService
