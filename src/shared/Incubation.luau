--!strict

local Incubation = {}

Incubation.MAX_PLACED = 1
Incubation.MIN_DURATION = 30
Incubation.MAX_DURATION = 1800

export type ReservedHatch = {
	Species: string,
	Rarity: string,
	Mutation: string?,
	Power: number,
}

export type IncubatorRecord = {
	IncubatorId: string,
	EggId: string,
	StartedAt: number,
	ReadyAt: number,
	QueueIndex: number,
	ReservedHatch: ReservedHatch,
}

function Incubation.IsRecord(record: any): boolean
	if type(record) ~= "table" then
		return false
	end
	local hatch = record.ReservedHatch
	return type(record.IncubatorId) == "string"
		and record.IncubatorId ~= ""
		and type(record.EggId) == "string"
		and record.EggId ~= ""
		and type(record.StartedAt) == "number"
		and type(record.ReadyAt) == "number"
		and record.ReadyAt >= record.StartedAt
		and type(record.QueueIndex) == "number"
		and record.QueueIndex == math.floor(record.QueueIndex)
		and record.QueueIndex >= 1
		and type(hatch) == "table"
		and type(hatch.Species) == "string"
		and hatch.Species ~= ""
		and type(hatch.Rarity) == "string"
		and hatch.Rarity ~= ""
		and (hatch.Mutation == nil or type(hatch.Mutation) == "string")
		and type(hatch.Power) == "number"
		and hatch.Power >= 0
end

function Incubation.CanStart(record: IncubatorRecord?, eggId: string): boolean
	return type(eggId) == "string" and eggId ~= "" and record == nil
end

local EGG_DURATIONS = {
	CommonEgg = 30,
	UncommonEgg = 45,
	RareEgg = 90,
	EpicEgg = 180,
	LegendaryEgg = 360,
}

local RARITY_BONUSES = {
	Common = 0,
	Uncommon = 15,
	Rare = 45,
	Epic = 90,
	Legendary = 180,
	Mythic = 300,
	UltraRare = 480,
	Secret = 600,
}

function Incubation.Duration(eggTier: string, resultRarity: string, power: number, firstHatch: boolean?): number
	if firstHatch then
		return 5
	end
	local powerBonus = math.clamp(math.floor(power / 10) * 5, 0, 120)
	return math.clamp(
		(EGG_DURATIONS[eggTier] or 0) + (RARITY_BONUSES[resultRarity] or 0) + powerBonus,
		Incubation.MIN_DURATION,
		Incubation.MAX_DURATION
	)
end

function Incubation.State(record: IncubatorRecord?, now: number): string
	if not record or type(record.ReadyAt) ~= "number" then
		return "Empty"
	end
	return if now >= record.ReadyAt then "Ready" else "Incubating"
end

function Incubation.CanClaim(
	record: IncubatorRecord?,
	now: number,
	creatureCount: number,
	maxCreatures: number
): (boolean, string?)
	local state = Incubation.State(record, now)
	if state == "Empty" then
		return false, "Aucune incubation"
	end
	if state == "Incubating" then
		return false, "Incubation en cours"
	end
	if creatureCount >= maxCreatures then
		return false, "Sanctuaire plein"
	end
	return true
end

-- Rayon du triangle de slots, calibrable après capture écran si la couveuse
-- s'avère plus petite que prévu.
Incubation.SLOT_RADIUS = 2.2

-- Décalage XZ d'un slot, pour raycaster le sol au droit de chaque œuf
-- (le raycast central tomberait sur l'œuf décoratif posé sur le socle).
function Incubation.SlotOffset(index: number): Vector3
	local angle = (index - 1) * (2 * math.pi / Incubation.MAX_PLACED) - math.pi / 2
	return Vector3.new(math.cos(angle), 0, math.sin(angle)) * Incubation.SLOT_RADIUS
end

-- Slots compacts posés SUR le plateau : triangle régulier, chaque œuf face au centre.
function Incubation.SlotCFrame(origin: Vector3, index: number): CFrame
	local offset = Incubation.SlotOffset(index)
	return CFrame.lookAt(origin + offset, origin)
end

return Incubation
