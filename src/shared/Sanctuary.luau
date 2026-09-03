local Config = require(script.Parent.Config)

local Sanctuary = {}

Sanctuary.SLOTS_PER_LEVEL = Config.SANCTUARY_SLOTS_PER_LEVEL
Sanctuary.SHARED_IDS = { "Sanctuary1", "Sanctuary2", "Sanctuary3" }
Sanctuary.SHARED_CREATURE_CAP = 3

function Sanctuary.MaxCreatures(sanctuaryLevel: number, bonusSlots: number?): number
	return Config.MAX_CREATURES_BASE
		+ math.max(0, sanctuaryLevel - 1) * Config.SANCTUARY_SLOTS_PER_LEVEL
		+ (bonusSlots or 0)
end

function Sanctuary.UpgradeCost(sanctuaryLevel: number): number
	return Config.SANCTUARY_UPGRADE_BASE_COST * (Config.SANCTUARY_UPGRADE_COST_MULT ^ (sanctuaryLevel - 1))
end

-- Tiers d'œufs verrouillés à ce rang : { tier = rang requis }. Absent = débloqué.
function Sanctuary.EggGate(sanctuaryLevel: number): { [string]: number }
	return {
		UncommonEgg = if sanctuaryLevel >= 2 then nil else 2,
		RareEgg = if sanctuaryLevel >= 3 then nil else 3,
		EpicEgg = if sanctuaryLevel >= 4 then nil else 4,
		LegendaryEgg = if sanctuaryLevel >= 5 then nil else 5,
	}
end

function Sanctuary.EggLocked(tier: string, sanctuaryLevel: number): number?
	return Sanctuary.EggGate(sanctuaryLevel)[tier]
end

Sanctuary.EGG_TIERS = { "CommonEgg", "UncommonEgg", "RareEgg", "EpicEgg", "LegendaryEgg" }

-- Tri déterministe de l'inventaire : palier croissant (ordre boutique),
-- puis ancienneté. table.sort n'est pas stable -> tiebreak explicite.
function Sanctuary.SortEggs(eggs: { any }): { any }
	local tierRank = {}
	for rank, tier in Sanctuary.EGG_TIERS do
		tierRank[tier] = rank
	end
	local sorted = table.clone(eggs)
	table.sort(sorted, function(a, b)
		local ra, rb = tierRank[a.Tier] or 0, tierRank[b.Tier] or 0
		if ra ~= rb then
			return ra < rb
		end
		return (a.Timestamp or 0) < (b.Timestamp or 0)
	end)
	return sorted
end

-- Les sources gratuites (faille, offres) ne contournent pas le gate : retombe
-- au meilleur palier débloqué.
function Sanctuary.ResolveEggTier(tier: string, sanctuaryLevel: number): string
	local i = table.find(Sanctuary.EGG_TIERS, tier) or 1
	while i > 1 and Sanctuary.EggLocked(Sanctuary.EGG_TIERS[i], sanctuaryLevel) do
		i -= 1
	end
	return Sanctuary.EGG_TIERS[i]
end

function Sanctuary.ValidateAssignment(
	sanctuaryId: string,
	creatureIds: { string },
	ownedIds: { [string]: boolean },
	unlockedCount: number
): boolean
	local index = table.find(Sanctuary.SHARED_IDS, sanctuaryId)
	if not index or index > unlockedCount then
		return false
	end
	local seen = {}
	local count = 0
	for key, creatureId in creatureIds do
		count += 1
		if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > #creatureIds then
			return false
		end
		if type(creatureId) ~= "string" or seen[creatureId] or not ownedIds[creatureId] then
			return false
		end
		seen[creatureId] = true
	end
	return count <= Sanctuary.SHARED_CREATURE_CAP
end

function Sanctuary.OfflineReward(rate: number, lastCollectedAt: number, now: number): (number, number)
	local elapsed = math.clamp(now - math.max(0, lastCollectedAt), 0, Config.OFFLINE_CAP_SECONDS)
	return math.max(0, math.floor(rate * Config.OFFLINE_RATE * elapsed)), now
end

return Sanctuary
