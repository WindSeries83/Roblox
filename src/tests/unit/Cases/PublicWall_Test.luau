return function(t)
	local expect = t.expect
	local PublicWall = require(game.ReplicatedStorage.Shared.PublicWall)

	t.test("upsert place le dernier soutien en tête et borne la liste", function()
		local entries = PublicWall.Upsert({ { Id = "old" }, { Id = "older" } }, { Id = "new" }, 2)
		expect.equal(#entries, 2)
		expect.equal(entries[1].Id, "new")
		expect.equal(entries[2].Id, "old")
	end)

	t.test("upsert remplace une entrée identique sans doublon", function()
		local entries = PublicWall.Upsert(
			{ { Id = "secret-1", Name = "Ancien" } },
			{ Id = "secret-1", Name = "Nouveau" },
			10
		)
		expect.equal(#entries, 1)
		expect.equal(entries[1].Name, "Nouveau")
	end)
end
