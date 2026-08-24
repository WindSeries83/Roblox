local Config = require(script.Parent.Config)

local SkillTree = {}

-- Liste ordonnee des noeuds de l'Arbre d'Etoiles (+1 point par renaissance).
function SkillTree.Nodes()
	return Config.SKILL_TREE
end

function SkillTree.Node(id: string)
	for _, node in Config.SKILL_TREE do
		if node.Id == id then
			return node
		end
	end
	return nil
end

function SkillTree.Rank(ranks: { [string]: number }, id: string): number
	return ranks[id] or 0
end

-- Prerequis d'un noeud : liste d'ids devant etre au rang >= 1 avant lui (racine = vide).
function SkillTree.Requires(node)
	return node.Requires or {}
end

function SkillTree.CanBuy(points: number, ranks: { [string]: number }, id: string): (boolean, string?)
	local node = SkillTree.Node(id)
	if not node then
		return false, "nœud inconnu"
	end
	if SkillTree.Rank(ranks, id) >= node.MaxRank then
		return false, "rang maximum atteint"
	end
	if points < 1 then
		return false, "aucun point d'étoile"
	end
	for _, reqId in SkillTree.Requires(node) do
		if SkillTree.Rank(ranks, reqId) < 1 then
			local reqNode = SkillTree.Node(reqId)
			return false, `nécessite {if reqNode then reqNode.Name else reqId}`
		end
	end
	return true
end

function SkillTree.Buy(points: number, ranks: { [string]: number }, id: string): number
	assert(SkillTree.CanBuy(points, ranks, id), `achat impossible: {id}`)
	ranks[id] = SkillTree.Rank(ranks, id) + 1
	return points - 1
end

-- Agrege les rangs en bonus : somme pour les effets numeriques, flag booleen pour SecretOmen.
function SkillTree.Effects(ranks: { [string]: number })
	local effects = {
		EssenceRate = 0,
		HatchLuck = 0,
		OfflineRate = 0,
		EggPriceReduction = 0,
		RiftRewardMult = 0,
		AscendChanceAdd = 0,
		MutationBonus = 0,
		SecretOmen = false,
		MarketFeeReduction = 0,
		BreedCostReduction = 0,
		UpgradeCostReduction = 0,
	}
	for _, node in Config.SKILL_TREE do
		local rank = SkillTree.Rank(ranks, node.Id)
		if rank > 0 then
			if node.Effect == "SecretOmen" then
				effects.SecretOmen = true
			else
				effects[node.Effect] += node.Value * rank
			end
		end
	end
	return effects
end

return SkillTree
