local Rarities = {
	Common = {
		Name = "Commun",
		EssenceMult = 1,
		PowerMult = 1,
		Color = Color3.fromRGB(150, 155, 160),
	},
	Uncommon = {
		Name = "Peu commun",
		EssenceMult = 2,
		PowerMult = 1.5,
		Color = Color3.fromRGB(60, 180, 90),
	},
	Rare = {
		Name = "Rare",
		EssenceMult = 5,
		PowerMult = 2.5,
		Color = Color3.fromRGB(60, 120, 255),
	},
	Epic = {
		Name = "Épique",
		EssenceMult = 10,
		PowerMult = 4,
		Color = Color3.fromRGB(160, 80, 220),
	},
	Legendary = {
		Name = "Légendaire",
		EssenceMult = 20,
		PowerMult = 6,
		Color = Color3.fromRGB(255, 180, 60),
	},
	Mythic = {
		Name = "Mythique",
		EssenceMult = 40,
		PowerMult = 9,
		Color = Color3.fromRGB(255, 60, 120),
	},
	UltraRare = {
		Name = "ULTRA RARE",
		EssenceMult = 100,
		PowerMult = 15,
		Color = Color3.fromRGB(255, 255, 255),
	},
	Secret = {
		Name = "Secret",
		EssenceMult = 250,
		PowerMult = 25,
		Color = Color3.fromRGB(0, 0, 0),
	},
}

Rarities.ORDER = {
	"Common",
	"Uncommon",
	"Rare",
	"Epic",
	"Legendary",
	"Mythic",
	"UltraRare",
	"Secret",
}

return Rarities
