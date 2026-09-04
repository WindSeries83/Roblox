--!strict

return function(t)
	local expect = t.expect
	local RemoteRegistry = require(game.ReplicatedStorage.Shared.RemoteRegistry)

	t.test("registry is complete and duplicate-free", function()
		expect.truthy(RemoteRegistry.Validate(RemoteRegistry.Names))
		expect.falsy(RemoteRegistry.Validate({ "Sync", "Sync" }))
		expect.falsy(RemoteRegistry.Validate({ "", "Sync" }))
	end)
end
