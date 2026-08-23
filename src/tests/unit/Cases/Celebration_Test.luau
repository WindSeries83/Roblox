return function(t)
	local expect = t.expect
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Celebration = require(game.StarterPlayer.StarterPlayerScripts.Celebration)
	local Gameplay = require(ReplicatedStorage.Shared.Gameplay)

	t.test("tier maps the celebration pyramid", function()
		expect.truthy(Celebration.Tier(Gameplay.RarityRank("Epic")) == "epic")
		expect.truthy(Celebration.Tier(Gameplay.RarityRank("Legendary")) == "legendary")
		expect.truthy(Celebration.Tier(Gameplay.RarityRank("Mythic")) == "legendary")
		expect.truthy(Celebration.Tier(Gameplay.RarityRank("UltraRare")) == "ultra")
		expect.truthy(Celebration.Tier(Gameplay.RarityRank("Secret")) == "ultra")
	end)

	t.test("rarity and unknown ranks celebrate nothing", function()
		expect.truthy(Celebration.Tier(Gameplay.RarityRank("Rare")) == "none")
		expect.truthy(Celebration.Tier(Gameplay.RarityRank("Nope")) == "none")
		expect.truthy(Celebration.Tier(0) == "none")
	end)

	t.test("hatch below epic is a no-op", function()
		Celebration.Hatch(0)
	end)
end
