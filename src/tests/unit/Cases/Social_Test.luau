return function(t)
	local expect = t.expect
	local Social = require(game.ReplicatedStorage.Shared.Social)

	t.test("rejects invalid user ids at the trust boundary", function()
		expect.falsy(Social.IsValidUserId(nil))
		expect.falsy(Social.IsValidUserId("123"))
		expect.falsy(Social.IsValidUserId(0))
		expect.falsy(Social.IsValidUserId(12.5))
		expect.falsy(Social.IsValidUserId(-4))
		expect.truthy(Social.IsValidUserId(123))
	end)

	t.test("accepts a valid invitation and rejects an expired one", function()
		local invite = { InviteId = "invite-1", FromUserId = 123, ExpiresAt = 1060 }
		expect.truthy(Social.IsInviteValid(invite, 1059))
		expect.falsy(Social.IsInviteValid(invite, 1060))
		expect.falsy(Social.IsInviteValid(invite, 1061))
	end)

	t.test("rejects malformed invitations", function()
		expect.falsy(Social.IsInviteValid({ InviteId = "invite-1", FromUserId = 123, ExpiresAt = "1060" }, 1059))
		expect.falsy(Social.IsInviteValid({ InviteId = "", FromUserId = 123, ExpiresAt = 1060 }, 1059))
		expect.falsy(Social.IsInviteValid({ InviteId = "invite-1", FromUserId = 0, ExpiresAt = 1060 }, 1059))
	end)
end
