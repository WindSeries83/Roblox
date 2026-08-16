export type RarityId = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic" | "UltraRare" | "Secret"
export type MutationId = "Shadow" | "Frost" | "Golden" | "Prismatic" | "Corrupted" | "Celestial"
export type EggTier = "CommonEgg" | "UncommonEgg" | "RareEgg"
export type ItemType = "Heart" | "Collar" | "Relic"

export type Item = {
	Id: string,
	Type: ItemType,
	Tier: number,
}

export type Creature = {
	Id: string,
	SpeciesId: string,
	Rarity: RarityId,
	Mutation: MutationId | false,
	Level: number,
	MaxLevel: number,
	XP: number,
	Stage: number,
	Power: number,
	Equipment: { Item },
	Parents: { Father: string?, Mother: string? },
	Generation: number,
	HatchedAt: number,
}

export type Egg = {
	Id: string,
	Tier: EggTier,
	Timestamp: number,
}

export type PlayerStats = {
	TotalHatched: number,
	TotalEssenceEarned: number,
	RiftsCompleted: number,
}

export type PlayerData = {
	Essence: number,
	Creatures: { Creature },
	Eggs: { Egg },
	SanctuaryLevel: number,
	Stats: PlayerStats,
	Index: { [string]: true },
	Items: { Item },
	Stars: number,
	Rebirths: number,
	LastPlayed: number,
	Version: number,
}
