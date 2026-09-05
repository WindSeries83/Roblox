local Vip = {}

function Vip.IsActive(expiresAt: number?, now: number?): boolean
	return type(expiresAt) == "number" and expiresAt > (now or os.time())
end

function Vip.Extend(expiresAt: number?, now: number, durationSeconds: number): number
	local base = if Vip.IsActive(expiresAt, now) then expiresAt :: number else now
	return base + durationSeconds
end

-- Cadeau quotidien : une fois par jour calendaire.
function Vip.GiftDue(lastGiftDate: string, today: string): boolean
	return lastGiftDate ~= today
end

function Vip.CanAccess(expiresAt: number?, now: number?): boolean
	return Vip.IsActive(expiresAt, now)
end

return Vip
