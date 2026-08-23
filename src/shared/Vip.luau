local Vip = {}

-- Cadeau quotidien : une fois par jour calendaire.
function Vip.GiftDue(lastGiftDate: string, today: string): boolean
	return lastGiftDate ~= today
end

return Vip
