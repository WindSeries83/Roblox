local Eclipse = {}

-- Fenêtre d'Éclipse : active pendant les `duration` premières secondes de chaque intervalle (rendez-vous mondial).
function Eclipse.IsActive(now: number, interval: number, duration: number): boolean
	return now % interval < duration
end

-- Prochaine frontière d'intervalle (début de la prochaine fenêtre ou fin si actif).
function Eclipse.NextBoundary(now: number, interval: number): number
	return now - (now % interval) + interval
end

return Eclipse
