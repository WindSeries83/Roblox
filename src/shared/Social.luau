local Social = {}

function Social.IsValidUserId(userId: unknown): boolean
	return type(userId) == "number" and userId == math.floor(userId) and userId > 0 and userId < 10 ^ 12
end

function Social.IsValidInviteId(inviteId: unknown): boolean
	return type(inviteId) == "string" and #inviteId > 0 and #inviteId <= 80
end

function Social.IsInviteValid(invite: any, now: number?): boolean
	local at = now or os.time()
	return type(invite) == "table"
		and Social.IsValidUserId(invite.FromUserId)
		and Social.IsValidInviteId(invite.InviteId)
		and type(invite.ExpiresAt) == "number"
		and invite.ExpiresAt > at
end

return Social
