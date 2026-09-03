--!strict

local Worlds = require(script.Parent.Worlds)

local Rush = {}

export type State = {
	WorldId: string,
	AttemptId: string,
	StartedAt: number,
	EndsAt: number,
	Completed: boolean,
	Claimed: boolean,
	Expired: boolean,
}

local function finite(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

function Rush.CanStart(worldId: any, progress: any, stars: any, current: any): (boolean, string?)
	local world = type(worldId) == "string" and Worlds.Get(worldId) or nil
	if not world then
		return false, "unknown_world"
	end
	if not Worlds.CanEnter(progress, stars, worldId) then
		return false, "world_locked"
	end
	if type(current) == "table" then
		if current.Completed == true and current.Claimed ~= true then
			return false, "claim_required"
		end
		if current.Completed ~= true and current.Expired ~= true then
			return false, "active"
		end
	end
	return true, nil
end

function Rush.Start(worldId: any, now: number, attemptId: string?): State?
	local world = type(worldId) == "string" and Worlds.Get(worldId) or nil
	if not world or not finite(now) or now < 0 then
		return nil
	end
	return {
		WorldId = worldId,
		AttemptId = if type(attemptId) == "string" and attemptId ~= "" then attemptId else `${worldId}:{now}`,
		StartedAt = now,
		EndsAt = now + world.Rush.TargetSeconds,
		Completed = false,
		Claimed = false,
		Expired = false,
	}
end

function Rush.Complete(worldId: any, state: any, now: number): ({ [string]: number }?, string?)
	local world = type(worldId) == "string" and Worlds.Get(worldId) or nil
	if
		not world
		or type(state) ~= "table"
		or state.WorldId ~= worldId
		or not finite(now)
		or not finite(state.StartedAt)
		or not finite(state.EndsAt)
	then
		return nil, "invalid"
	end
	if state.Expired then
		return nil, "timeout"
	end
	if state.Completed then
		return nil, if state.Claimed then "already_claimed" else "already_completed"
	end
	if now > state.EndsAt then
		return nil, "timeout"
	end
	state.Completed = true
	state.CompletedAt = now
	return table.clone(world.Rush.Reward), nil
end

function Rush.Claim(state: any): boolean
	if type(state) ~= "table" or state.Completed ~= true or state.Claimed == true or state.Expired == true then
		return false
	end
	state.Claimed = true
	return true
end

function Rush.Expire(state: any, now: number): boolean
	if type(state) ~= "table" or state.Completed == true or state.Claimed == true or state.Expired == true then
		return false
	end
	if not finite(now) or not finite(state.EndsAt) or now <= state.EndsAt then
		return false
	end
	state.Expired = true
	return true
end

function Rush.Status(state: any, now: number): string
	if type(state) ~= "table" then
		return "Idle"
	end
	if state.Claimed == true then
		return "Claimed"
	end
	if state.Completed == true then
		return "Completed"
	end
	if state.Expired == true or (finite(now) and finite(state.EndsAt) and now > state.EndsAt) then
		return "Expired"
	end
	return "Active"
end

function Rush.Snapshot(state: any, now: number): { [string]: any }
	local status = Rush.Status(state, now)
	if type(state) ~= "table" then
		return {
			Active = false,
			Status = status,
			RemainingSeconds = 0,
			NextAction = "Start",
		}
	end
	local remaining = if finite(state.EndsAt) and finite(now) then math.max(0, math.ceil(state.EndsAt - now)) else 0
	return {
		Active = status == "Active" or status == "Completed",
		Status = status,
		WorldId = state.WorldId,
		StartedAt = state.StartedAt,
		EndsAt = state.EndsAt,
		RemainingSeconds = remaining,
		Completed = state.Completed == true,
		Claimed = state.Claimed == true,
		NextAction = if status == "Completed" then "Claim" elseif status == "Active" then "Wait" else "Start",
	}
end

return Rush
