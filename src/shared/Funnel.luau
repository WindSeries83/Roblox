local Funnel = {}

-- Pose l'horodatage d'une première fois ; jamais réécrit.
function Funnel.Stamp(funnel: { [string]: number }, key: string, now: number)
	if (funnel[key] or 0) == 0 then
		funnel[key] = now
	end
end

return Funnel
