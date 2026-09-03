--!strict
-- Pure solo Rift combat state machine. Services own persistence, remotes, and visuals.
-- All timestamps are numeric seconds from one clock; the runtime supplies os.clock().

local Config = require(script.Parent.Config)
local DuelSim = require(script.Parent.DuelSim)
local RiftDifficulty = require(script.Parent.RiftDifficulty)

local RiftCombat = {}

RiftCombat.MAX_DURATION = Config.RIFT_ACTIVE_SECONDS
RiftCombat.ENEMY_COUNT = 4
RiftCombat.KO_DURATION = 10

local NORMAL_HP_RATIO = 0.35
local NORMAL_DAMAGE_RATIO = 0.5
local DEFAULT_CREATURE_HP = 100

export type CreatureState = {
	Id: string,
	Power: number,
	MaxHP: number,
	HP: number,
	KOUntil: number?,
}

export type EnemyState = {
	Index: number,
	IsBoss: boolean,
	MaxHP: number,
	HP: number,
	Damage: number,
}

export type State = {
	Phase: string,
	StartedAt: number,
	EndsAt: number,
	PlayerHP: number,
	PlayerMaxHP: number,
	Enemies: { EnemyState },
	EnemyIndex: number,
	Enemy: EnemyState,
	ActiveCreature: CreatureState?,
	Reserve: { CreatureState },
	AwaitingReplacement: boolean,
	DefeatReason: string?,
	Bonus: string,
	NextAutoAt: number,
}

RiftCombat.AUTO_INTERVAL = 0.75

local function isFinite(value: number): boolean
	return value == value and math.abs(value) ~= math.huge
end

local function copyCreature(raw: any, now: number): CreatureState?
	if type(raw) ~= "table" or type(raw.Id) ~= "string" or type(raw.Power) ~= "number" then
		return nil
	end
	if not isFinite(raw.Power) or raw.Power < 0 then
		return nil
	end

	local maxHp = raw.MaxHP
	if type(maxHp) ~= "number" or not isFinite(maxHp) or maxHp <= 0 then
		maxHp = if type(raw.HP) == "number" and isFinite(raw.HP) and raw.HP > 0 then raw.HP else DEFAULT_CREATURE_HP
	end
	local koUntil = raw.KOUntil
	local knockedOut = type(koUntil) == "number" and koUntil > now
	return {
		Id = raw.Id,
		Power = raw.Power,
		MaxHP = maxHp,
		HP = if knockedOut then 0 else maxHp,
		KOUntil = if knockedOut then koUntil else nil,
	}
end

local function finish(state: State, phase: string, reason: string?): string
	state.Phase = phase
	state.DefeatReason = reason
	state.AwaitingReplacement = false
	return phase
end

local function refreshEnemy(state: State)
	state.Enemy = state.Enemies[state.EnemyIndex]
end

function RiftCombat.Start(creatures: { any }, startedAt: number, tutorial: boolean?): State
	local roster: { CreatureState } = {}
	local seenIds: { [string]: boolean } = {}
	for _, raw in creatures do
		local creature = copyCreature(raw, startedAt)
		if creature and not seenIds[creature.Id] then
			seenIds[creature.Id] = true
			table.insert(roster, creature)
		end
	end

	local power = DuelSim.TeamPower(roster)
	local difficulty = RiftDifficulty.For(power, tutorial == true)
	local normalHp = math.max(1, math.floor(difficulty.GuardianHP * NORMAL_HP_RATIO))
	local normalDamage = math.max(1, math.floor(difficulty.GuardianDamage * NORMAL_DAMAGE_RATIO))
	local enemies: { EnemyState } = {}
	for index = 1, 3 do
		table.insert(enemies, {
			Index = index,
			IsBoss = false,
			MaxHP = normalHp,
			HP = normalHp,
			Damage = normalDamage,
		})
	end
	table.insert(enemies, {
		Index = 4,
		IsBoss = true,
		MaxHP = difficulty.GuardianHP,
		HP = difficulty.GuardianHP,
		Damage = difficulty.GuardianDamage,
	})

	local state: State = {
		Phase = "Fight",
		StartedAt = startedAt,
		EndsAt = startedAt + RiftCombat.MAX_DURATION,
		PlayerHP = Config.RIFT_PLAYER_MAX_HP,
		PlayerMaxHP = Config.RIFT_PLAYER_MAX_HP,
		Enemies = enemies,
		EnemyIndex = 1,
		Enemy = enemies[1],
		ActiveCreature = nil,
		Reserve = roster,
		AwaitingReplacement = false,
		DefeatReason = nil,
		Bonus = "Balanced",
		NextAutoAt = startedAt,
	}
	for index, creature in roster do
		if not creature.KOUntil or creature.KOUntil <= startedAt then
			state.ActiveCreature = table.remove(roster, index)
			break
		end
	end
	if not state.ActiveCreature then
		finish(state, "Defeat", "RosterExhausted")
	end
	return state
end

function RiftCombat.Advance(state: State, now: number): string
	if state.Phase == "Fight" and now >= state.EndsAt then
		return finish(state, "Defeat", "Timeout")
	end
	return state.Phase
end

function RiftCombat.PlayerAttack(state: State, now: number): number
	if RiftCombat.Advance(state, now) ~= "Fight" or state.AwaitingReplacement then
		return 0
	end
	local active = state.ActiveCreature
	if not active then
		return 0
	end
	local multiplier = if state.Bonus == "Power" then 1.25 else 1
	local damage = math.floor(DuelSim.TeamPower({ active }) * Config.RIFT_PLAYER_DAMAGE_MULT * multiplier)
	if damage <= 0 then
		return 0
	end
	state.Enemy.HP = math.max(0, state.Enemy.HP - damage)
	if state.Enemy.HP == 0 then
		if state.EnemyIndex == #state.Enemies then
			finish(state, "Victory")
		else
			state.EnemyIndex += 1
			refreshEnemy(state)
		end
	end
	return damage
end

function RiftCombat.DamagePlayer(state: State, amount: number, now: number): number
	if RiftCombat.Advance(state, now) ~= "Fight" or amount <= 0 or not isFinite(amount) then
		return 0
	end
	local dealt = math.min(state.PlayerHP, amount)
	state.PlayerHP -= dealt
	if state.PlayerHP <= 0 then
		finish(state, "Defeat", "PlayerKO")
	end
	return dealt
end

function RiftCombat.EnemyAttack(state: State, now: number): number
	if RiftCombat.Advance(state, now) ~= "Fight" or state.AwaitingReplacement then
		return 0
	end
	local multiplier = if state.Bonus == "Guard" then 0.5 else 1
	return RiftCombat.DamagePlayer(state, state.Enemy.Damage * multiplier, now)
end

function RiftCombat.ChooseBonus(state: State, bonus: string): boolean
	if state.Phase ~= "Fight" or not table.find({ "Balanced", "Power", "Guard" }, bonus) then
		return false
	end
	state.Bonus = bonus
	return true
end

function RiftCombat.AutoTick(state: State, now: number): number
	if RiftCombat.Advance(state, now) ~= "Fight" or now < state.NextAutoAt then
		return 0
	end
	state.NextAutoAt = now + RiftCombat.AUTO_INTERVAL
	local damage = RiftCombat.PlayerAttack(state, now)
	if state.Phase == "Fight" then
		RiftCombat.EnemyAttack(state, now)
	end
	return damage
end

function RiftCombat.DamageCreature(state: State, amount: number, now: number): number
	if
		RiftCombat.Advance(state, now) ~= "Fight"
		or state.AwaitingReplacement
		or amount <= 0
		or not isFinite(amount)
	then
		return 0
	end
	local active = state.ActiveCreature
	if not active then
		return 0
	end
	local dealt = math.min(active.HP, amount)
	active.HP -= dealt
	if active.HP <= 0 then
		active.HP = 0
		active.KOUntil = now + RiftCombat.KO_DURATION
		state.AwaitingReplacement = true
		if #state.Reserve == 0 then
			finish(state, "Defeat", "RosterExhausted")
		end
	end
	return dealt
end

function RiftCombat.SelectReplacement(state: State, creatureId: string, now: number): boolean
	if RiftCombat.Advance(state, now) ~= "Fight" or not state.AwaitingReplacement then
		return false
	end
	for index, creature in state.Reserve do
		if creature.Id == creatureId and (not creature.KOUntil or creature.KOUntil <= now) then
			local previous = state.ActiveCreature
			if previous then
				table.insert(state.Reserve, previous)
			end
			creature.HP = creature.MaxHP
			creature.KOUntil = nil
			state.ActiveCreature = creature
			table.remove(state.Reserve, index)
			state.AwaitingReplacement = false
			return true
		end
	end
	return false
end

return RiftCombat
