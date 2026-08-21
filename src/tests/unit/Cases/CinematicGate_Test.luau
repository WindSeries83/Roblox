return function(t)
	local expect = t.expect
	local Cinematic = require(game.StarterPlayer.StarterPlayerScripts.Cinematic)

	t.test("ShouldPlay accepts Mythic and above", function()
		expect.truthy(Cinematic.ShouldPlay("Mythic"))
		expect.truthy(Cinematic.ShouldPlay("UltraRare"))
		expect.truthy(Cinematic.ShouldPlay("Secret"))
	end)

	t.test("ShouldPlay rejects ranks below Mythic", function()
		expect.falsy(Cinematic.ShouldPlay("Common"))
		expect.falsy(Cinematic.ShouldPlay("Uncommon"))
		expect.falsy(Cinematic.ShouldPlay("Rare"))
		expect.falsy(Cinematic.ShouldPlay("Epic"))
		expect.falsy(Cinematic.ShouldPlay("Legendary"))
	end)

	t.test("ShouldPlay rejects unknown or missing rarity", function()
		expect.falsy(Cinematic.ShouldPlay("Nope"))
		expect.falsy(Cinematic.ShouldPlay(nil))
	end)
end
