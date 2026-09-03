--!strict

local DuelTransaction = {}

export type State =
	"Created"
	| "ChallengerEscrowed"
	| "Accepted"
	| "Resolved"
	| "WinnerApplied"
	| "LoserApplied"
	| "Declined"
	| "TimedOut"
	| "RefundApplied"
	| "Settled"
	| "Cancelled"

local NEXT: { [string]: { [string]: boolean } } = {
	Created = { ChallengerEscrowed = true, Declined = true, TimedOut = true, Cancelled = true },
	ChallengerEscrowed = { Accepted = true, Declined = true, TimedOut = true, Cancelled = true },
	Accepted = { Resolved = true, Cancelled = true },
	Resolved = { WinnerApplied = true, Cancelled = true },
	WinnerApplied = { LoserApplied = true, Cancelled = true },
	LoserApplied = { Settled = true, Cancelled = true },
	Declined = { RefundApplied = true, Cancelled = true },
	TimedOut = { RefundApplied = true, Cancelled = true },
	RefundApplied = { Settled = true, Cancelled = true },
	Settled = {},
	Cancelled = {},
}

local TERMINAL = {
	Settled = true,
	Cancelled = true,
}

function DuelTransaction.State(record: any): State?
	if type(record) ~= "table" or type(record.State) ~= "string" then
		return nil
	end
	return record.State :: State
end

function DuelTransaction.IsTerminal(record: any): boolean
	local state = DuelTransaction.State(record)
	return state ~= nil and TERMINAL[state] == true
end

function DuelTransaction.Transition(record: any, expected: State, nextState: State, patch: { [string]: any }?): boolean
	if type(record) ~= "table" then
		return false
	end
	if record.State == nextState then
		return true
	end
	if record.State ~= expected or not NEXT[expected] or NEXT[expected][nextState] ~= true then
		return false
	end
	if patch then
		for key, value in patch do
			record[key] = value
		end
	end
	record.State = nextState
	return true
end

function DuelTransaction.CanExpire(record: any, now: number): boolean
	if type(record) ~= "table" or type(record.ExpiresAt) ~= "number" or type(now) ~= "number" then
		return false
	end
	return (record.State == "ChallengerEscrowed" or record.State == "Created") and now > record.ExpiresAt
end

function DuelTransaction.New(fields: { [string]: any }): { [string]: any }
	local record = table.clone(fields)
	record.State = "Created"
	return record
end

return DuelTransaction
