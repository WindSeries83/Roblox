export type RarityId = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic" | "UltraRare" | "Secret"
export type MutationId = "Shadow" | "Frost" | "Golden" | "Prismatic" | "Corrupted" | "Celestial"
export type EggTier = "CommonEgg" | "UncommonEgg" | "RareEgg"

export type Creature = {
	Id: string,
	SpeciesId: string,
	Rarity: RarityId,
	Mutation: MutationId | false,
	Level: number,
	Power: number,
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
	LastPlayed: number,
	Version: number,
}
