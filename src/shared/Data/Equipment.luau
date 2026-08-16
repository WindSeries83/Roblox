return {
	Heart = {
		Name = "Cœur",
		Tiers = {
			{ Name = "Cœur commun", Price = 200, MaxLevelBonus = 5 },
			{ Name = "Cœur rare", Price = 2000, MaxLevelBonus = 15 },
			{ Name = "Cœur mythique", Price = 20000, MaxLevelBonus = 50 },
		},
	},
	Collar = {
		Name = "Collier",
		Tiers = {
			{ Name = "Collier simple", Price = 500, MutationChanceBonus = 0.005 },
			{ Name = "Collier doré", Price = 5000, MutationChanceBonus = 0.015 },
			{ Name = "Collier céleste", Price = 50000, MutationChanceBonus = 0.05 },
		},
	},
	Relic = {
		Name = "Relique",
		DropOnly = true,
		Tiers = {
			{ Name = "Relique fissurée", Legendary = false },
			{ Name = "Relique lumineuse", Legendary = false },
			{ Name = "Relique légendaire", Legendary = true },
		},
	},
}
