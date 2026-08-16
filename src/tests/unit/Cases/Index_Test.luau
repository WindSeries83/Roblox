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
		Index.Register(entries, "Moonhowl", "Rare", false)
		Index.Register(entries, "CinderSeraph", "Rare", false)
		local completions = Index.FamilyCompletions(entries)
		expect.truthy(completions.Mystic)
		expect.falsy(completions.Feral)

		local expected = (1 + 2 * Config.INDEX_ENTRY_BONUS) * (1 + Config.INDEX_FAMILY_BONUS)
		expect.near(Index.ComputeMult(entries), expected)
	end)

	-- An incomplete family grants nothing.
	t.test("incomplete family grants nothing", function()
		local entries = {}
		Index.Register(entries, "Moonhowl", "Rare", false)
		expect.falsy(Index.FamilyCompletions(entries).Mystic)
	end)
end
