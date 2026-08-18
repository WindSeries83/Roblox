return function(t)
	local expect = t.expect
	local LeaderboardService = require(game.ServerScriptService.Services.LeaderboardService)
	local Config = require(game.ReplicatedStorage.Shared.Config)

	local function Profile(essence: number, sanctuaryLevel: number, creatures: { any })
		return {
			Data = {
				Stats = { TotalEssenceEarned = essence },
				SanctuaryLevel = sanctuaryLevel,
				Creatures = creatures,
			},
		}
	end

	t.test("BuildEntry collects essence, level, ranks and species", function()
		local entry = LeaderboardService.BuildEntry(
			1,
			"Alice",
			Profile(500, 3, {
				{ Rarity = "Common", SpeciesId = "Riftling" },
				{ Rarity = "Common", SpeciesId = "Riftling" },
				{ Rarity = "Rare", SpeciesId = "Moonhowl" },
			})
		)
		expect.equal(entry.Essence, 500)
		expect.equal(entry.SanctuaryLevel, 3)
		expect.equal(entry.Ranks.Common, 2)
		expect.equal(entry.Ranks.Rare, 1)
		expect.equal(entry.Species.Riftling, 2)
		expect.equal(entry.Species.Moonhowl, 1)
	end)

	t.test("BuildEntry handles empty sanctuary", function()
		local entry = LeaderboardService.BuildEntry(2, "Bob", Profile(0, 1, {}))
		expect.equal(entry.Essence, 0)
		expect.equal(entry.SanctuaryLevel, 1)
		expect.equal(next(entry.Ranks), nil)
	end)

	t.test("TopEntries sorts by essence descending", function()
		local entries = {
			[1] = { UserId = 1, Essence = 100 },
			[2] = { UserId = 2, Essence = 300 },
			[3] = { UserId = 3, Essence = 200 },
		}
		local top = LeaderboardService.TopEntries(entries, 10)
		expect.equal(top[1].UserId, 2)
		expect.equal(top[2].UserId, 3)
		expect.equal(top[3].UserId, 1)
	end)

	t.test("TopEntries respects the limit", function()
		local entries = {}
		for i = 1, 10 do
			entries[i] = { UserId = i, Essence = i }
		end
		local top = LeaderboardService.TopEntries(entries, Config.LEADERBOARD_TOP)
		expect.equal(#top, math.min(Config.LEADERBOARD_TOP, 10))
	end)

	t.test("TopEntries keeps rank assignment order", function()
		local entries = {
			[1] = { UserId = 7, Essence = 50 },
			[2] = { UserId = 9, Essence = 999 },
		}
		local top = LeaderboardService.TopEntries(entries, 10)
		expect.equal(top[1].UserId, 9)
		expect.equal(top[2].UserId, 7)
	end)
end
