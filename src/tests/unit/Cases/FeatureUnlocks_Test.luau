return function(t)
	local FeatureUnlocks = require(game.ReplicatedStorage.Shared.FeatureUnlocks)
	local expect = t.expect

	local function data(stars, totalHatched, progress)
		return {
			Stars = stars,
			Stats = { TotalHatched = totalHatched },
			WorldProgress = progress or {},
		}
	end

	-- Le départ n'expose que les œufs et la base privée.
	t.test("starts with eggs and sanctuaries only", function()
		local unlocked = FeatureUnlocks.For(data(0, 0))
		expect.truthy(unlocked.Eggs)
		expect.truthy(unlocked.Sanctuaries)
		expect.falsy(unlocked.Expeditions)
		expect.falsy(unlocked.More)
		expect.falsy(unlocked.Index)
		expect.falsy(unlocked.SkillTree)
		expect.falsy(unlocked.Equipment)
		expect.falsy(unlocked.Evolution)
		expect.falsy(unlocked.Breeding)
	end)

	-- La première créature révèle le parcours sans révéler les menus avancés.
	t.test("unlocks expeditions after the first hatch", function()
		local unlocked = FeatureUnlocks.For(data(0, 1))
		expect.truthy(unlocked.Expeditions)
		expect.falsy(unlocked.Shop)
	end)

	-- Le premier boss révèle la boutique, les objectifs et la Renaissance.
	t.test("unlocks first advanced surfaces after boss one", function()
		local unlocked = FeatureUnlocks.For(data(0, 1, { TwilightGrove = { BossDefeated = true } }))
		expect.truthy(unlocked.More)
		expect.truthy(unlocked.Objectives)
		expect.truthy(unlocked.Shop)
		expect.truthy(unlocked.Rebirth)
	end)

	-- Les étoiles révèlent ensuite les systèmes par paliers.
	t.test("unlocks progression systems by rebirth tier", function()
		local r1 = FeatureUnlocks.For(data(1, 1, { TwilightGrove = { BossDefeated = true } }))
		expect.truthy(r1.World2)
		expect.truthy(r1.SkillTree)
		expect.truthy(r1.Index)
		expect.truthy(r1.Equipment)
		expect.truthy(r1.Evolution)
		expect.truthy(r1.Market)
		expect.equal(r1.SharedSanctuaryCount, 1)

		local r2 = FeatureUnlocks.For(data(2, 1, { AshForge = { BossDefeated = true } }))
		expect.truthy(r2.Social)
		expect.truthy(r2.Duels)
		expect.falsy(r2.Breeding)

		local r3 = FeatureUnlocks.For(data(3, 1, { GalePeaks = { BossDefeated = true } }))
		expect.truthy(r3.Breeding)
		expect.equal(r3.SharedSanctuaryCount, 2)

		local endgame = FeatureUnlocks.For(data(4, 1, { NyxAbyss = { BossDefeated = true } }))
		expect.truthy(endgame.Endgame)
		expect.equal(endgame.SharedSanctuaryCount, 3)
	end)

	t.test("server guard returns a readable reason at every progression tier", function()
		local lockedData = data(0, 1)
		local locked, reason = FeatureUnlocks.Require(lockedData, "Evolution")
		expect.falsy(locked)
		expect.truthy(reason ~= nil and string.find(reason, "Renaissance", 1, true) ~= nil)

		local unlockedData = data(1, 1, { TwilightGrove = { BossDefeated = true } })
		local ok, noReason = FeatureUnlocks.Require(unlockedData, "Evolution")
		expect.truthy(ok)
		expect.equal(noReason, nil)

		local reasons = FeatureUnlocks.Reasons(lockedData)
		expect.truthy(reasons.Index ~= nil)
		expect.truthy(reasons.SkillTree ~= nil)
		expect.truthy(reasons.Equipment ~= nil)
		expect.truthy(reasons.Evolution ~= nil)
		expect.truthy(reasons.Breeding ~= nil)
	end)
end
