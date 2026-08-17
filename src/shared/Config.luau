return {
	ESSENCE_BASE_RATE = 0.5,
	SANCTUARY_LEVEL_BONUS = 0.2,

	STARTER_ESSENCE = 100,

	EGG_PRICES = {
		CommonEgg = 50,
		UncommonEgg = 200,
		RareEgg = 800,
	},

	EGG_RARITY_WEIGHTS = {
		CommonEgg = { Common = 75, Uncommon = 20, Rare = 5 },
		UncommonEgg = { Uncommon = 80, Rare = 20 },
		RareEgg = { Rare = 100 },
	},

	FIRST_HATCH_WEIGHTS = { Common = 40, Uncommon = 40, Rare = 20 },

	MUTATION_WEIGHTS = {
		None = 88,
		Shadow = 10,
		Frost = 2,
	},

	ANNOUNCE_MIN_RARITY = "Rare",

	OFFLINE_RATE = 0.5,
	OFFLINE_CAP_SECONDS = 12 * 3600,

	RIFT_INTERVAL = 600,
	RIFT_ACTIVE_SECONDS = 180,
	RIFT_ESSENCE_MULT = 8,
	RIFT_REWARD_SECONDS = 60,
	RIFT_MIN_REWARD = 50,
	RIFT_EGG_WEIGHTS = { CommonEgg = 60, UncommonEgg = 35, RareEgg = 5 },
	RIFT_PORTAL_POSITION = Vector3.new(40, 3, 40),

	RIFT_PLAYER_MAX_HP = 100,
	RIFT_GUARDIAN_BASE_HP = 60,
	RIFT_GUARDIAN_HP_PER_POWER = 4,
	RIFT_ATTACK_COOLDOWN = 1,
	RIFT_PLAYER_DAMAGE_MULT = 0.8,
	RIFT_GUARDIAN_ATTACK_INTERVAL = 2.5,
	RIFT_GUARDIAN_DAMAGE = 12,

	RIFT_RELIC_WEIGHTS = { None = 88, T1 = 8, T2 = 3, T3 = 1 },

	BASE_MAX_LEVEL = 10,
	CREATURE_XP_PER_SECOND = 0.25,
	LEVEL_XP_BASE = 60,
	LEVEL_POWER_BONUS = 0.15,

	BREED_COST = 250,
	BREED_COOLDOWN = 300,
	BREED_INHERIT_SAME = 0.8,
	BREED_INHERIT_ONE = 0.4,
	BREED_INHERIT_SINGLE = 0.6,
	BREED_MUTATION_WEIGHTS = { None = 95, Shadow = 4, Frost = 1 },

	INDEX_ENTRY_BONUS = 0.01,
	INDEX_FAMILY_BONUS = 0.10,

	STAR_ESSENCE_BONUS = 0.5,
	REBIRTH_THRESHOLDS = { 50000, 250000, 1250000, 6250000 },

	MAX_CREATURES_BASE = 10,
	SANCTUARY_SLOTS_PER_LEVEL = 2,
	SANCTUARY_UPGRADE_BASE_COST = 1000,
	SANCTUARY_UPGRADE_COST_MULT = 4,

	COLLAR_MUTATION_CAP = 0.25,

	TUTORIAL_REWARD = 50,

	DAILY_QUESTS_COUNT = 3,

	DAILY_QUESTS = {
		HatchDaily = {
			Name = "Éclore des œufs",
			Desc = "Éclos {target} œufs",
			Target = 2,
			Reward = 100,
		},
		RiftDaily = {
			Name = "Vaincre la faille",
			Desc = "Gagne un combat de faille",
			Target = 1,
			Reward = 150,
		},
		BreedDaily = {
			Name = "Croiser des créatures",
			Desc = "Réussis un élevage",
			Target = 1,
			Reward = 120,
		},
		EssenceDaily = {
			Name = "Gagner de l'essence",
			Desc = "Gagne {target} essence (récompenses exclues)",
			Target = 500,
			Reward = 100,
		},
		IndexDaily = {
			Name = "Découvrir des espèces",
			Desc = "Découvre {target} nouvelles entrées de l'index",
			Target = 2,
			Reward = 150,
		},
	},

	ACHIEVEMENTS = {
		FirstHatch = { Name = "Premier pas", Desc = "Éclos ton premier œuf", Reward = 50 },
		TenHatch = { Name = "Collectionneur", Desc = "Éclos 10 œufs", Reward = 200 },
		HundredHatch = { Name = "Éleveur acharné", Desc = "Éclos 100 œufs", Reward = 1000 },
		FiveCreatures = { Name = "Meute grandissante", Desc = "Possède 5 créatures", Reward = 100 },
		FirstRift = { Name = "Brèche vaincue", Desc = "Gagne une faille", Reward = 200 },
		RiftMaster = { Name = "Dompteur de faille", Desc = "Gagne 10 failles", Reward = 1000 },
		FirstBreed = { Name = "Élevage réussi", Desc = "Croise deux créatures", Reward = 150 },
		Breeder = { Name = "Maître éleveur", Desc = "Croise 10 fois", Reward = 800 },
		FirstRebirth = { Name = "Nouvelle ère", Desc = "Renaît une première fois", Reward = 500 },
		FirstMutation = { Name = "Chanceux", Desc = "Obtiens une créature mutée", Reward = 300 },
		Dex10 = { Name = "Explorateur", Desc = "Découvre 10 entrées de l'index", Reward = 150 },
		Dex50 = { Name = "Naturaliste", Desc = "Découvre 50 entrées de l'index", Reward = 1500 },
		Essence10k = { Name = "Banquier", Desc = "Gagne 10 000 essence au total", Reward = 500 },
	},
}

-- SYNC_MARKER
