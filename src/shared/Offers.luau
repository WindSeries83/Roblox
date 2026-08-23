local DAY = 86400

local Offers = {}

-- Jour de retour : D2 dès 1 jour d'absence, D7 dès 6 jours.
function Offers.ReturnDay(elapsed: number): string?
	if elapsed >= 6 * DAY then
		return "D7"
	elseif elapsed >= DAY then
		return "D2"
	end
	return nil
end

function Offers.ReturnGiftDue(data: any, day: string): boolean
	return data.Offers.ReturnGifts[day] ~= true
end

return Offers
