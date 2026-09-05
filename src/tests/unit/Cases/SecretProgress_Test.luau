--!strict

return function(t)
	local expect = t.expect
	local SecretProgress = require(game.ReplicatedStorage.Shared.SecretProgress)

	t.test("requires all four boss discoveries", function()
		expect.equal(SecretProgress.Count({ TwilightGrove = true, AshForge = true }), 2)
		expect.falsy(SecretProgress.All({ TwilightGrove = true, AshForge = true, GalePeaks = true }))
		expect.truthy(SecretProgress.All({
			TwilightGrove = true,
			AshForge = true,
			GalePeaks = true,
			NyxAbyss = true,
		}))
	end)
end
