return function(t)
	local expect = t.expect
	local Index = require(game.ReplicatedStorage.Shared.Index)
	local Config = require(game.ReplicatedStorage.Shared.Config)

	-- Index keys join species, rarity and mutation.
	t.test("index keys join species rarity and mutation", function()
		expect.equal(Index.Key("Riftling", "Common", false), "Riftling|Common|false")
		expect.equal(Index.Key("Moonhowl", "Rare", "Frost"), "Moonhowl|Rare|Frost")
	end)

	-- Register then Has reports discovery.
	t.test("register then has reports discovery", function()
		local entries = {}
		Index.Register(entries, "Riftling", "Common", false)
		expect.truthy(Index.Has(entries, "Riftling", "Common", false))
		expect.falsy(Index.Has(entries, "Riftling", "Common", "Frost"))
	end)

	-- An empty index has a multiplier of one.
	t.test("empty index has multiplier one", function()
		expect.near(Index.ComputeMult({}), 1)
	end)

	-- Each entry adds the configured bonus.
	t.test("each entry adds the configured bonus", function()
		local entries = {}
		Index.Register(entries, "Riftling", "Common", false)
		Index.Register(entries, "Moonhowl", "Rare", false)
		expect.near(Index.ComputeMult(entries), 1 + 2 * Config.INDEX_ENTRY_BONUS)
	end)

	-- Completing a family grants the family bonus on top of entries.
	t.test("completing a family grants the family bonus", function()
		local entries = {}
		local species = require(game.ReplicatedStorage.Shared.Data.Species)
		for id, def in species do
			if def.Family == "Mystic" then
				Index.Register(entries, id, "Rare", false)
			end
		end
		local completions = Index.FamilyCompletions(entries)
		expect.truthy(completions.Mystic)
		expect.falsy(completions.Feral)

		local mysticCount = 0
		for _, def in species do
			if def.Family == "Mystic" then
				mysticCount += 1
			end
		end
		local expected = (1 + mysticCount * Config.INDEX_ENTRY_BONUS) * (1 + Config.INDEX_FAMILY_BONUS)
		expect.near(Index.ComputeMult(entries), expected)
	end)

	-- An incomplete family grants nothing.
	t.test("incomplete family grants nothing", function()
		local entries = {}
		Index.Register(entries, "Moonhowl", "Rare", false)
		expect.falsy(Index.FamilyCompletions(entries).Mystic)
	end)

	-- Catalog lists every species exactly once with its def fields.
	t.test("catalog lists every species once", function()
		local species = require(game.ReplicatedStorage.Shared.Data.Species)
		local expected = 0
		for _ in species do
			expected += 1
		end
		local seen = {}
		local count = 0
		for _, entry in Index.Catalog() do
			expect.truthy(entry.SpeciesId ~= nil)
			expect.truthy(entry.Name ~= nil)
			expect.truthy(entry.Rarity ~= nil)
			expect.truthy(entry.Family ~= nil)
			expect.falsy(seen[entry.SpeciesId])
			seen[entry.SpeciesId] = true
			count += 1
		end
		expect.equal(count, expected)
	end)

	-- EntryState reports owned, discovered or unknown per species.
	t.test("entry state reports owned discovered unknown", function()
		local entries = {}
		Index.Register(entries, "Moonhowl", "Rare", false)
		local creatures = { { SpeciesId = "Riftling" } }
		expect.equal(Index.EntryState(entries, "Riftling", creatures), "owned")
		expect.equal(Index.EntryState(entries, "Riftling", {}), "unknown")
		expect.equal(Index.EntryState(entries, "Moonhowl", creatures), "discovered")
		expect.equal(Index.EntryState(entries, "PondSentinel", creatures), "unknown")
	end)
end
