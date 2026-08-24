return function(t)
	local expect = t.expect
	local SkillTree = require(game.ReplicatedStorage.Shared.SkillTree)

	-- The tree exposes exactly twelve purchasable nodes.
	t.test("tree exposes exactly twelve purchasable nodes", function()
		local nodes = SkillTree.Nodes()
		expect.equal(#nodes, 12)
		for _, node in nodes do
			expect.truthy(node.MaxRank >= 1)
			expect.truthy(node.Effect ~= nil)
			expect.truthy(node.Value > 0 or node.Effect == "SecretOmen")
		end
	end)

	-- Buying consumes one point per rank and respects max rank.
	t.test("buy consumes one point per rank and respects max rank", function()
		local ranks = {}
		local points = SkillTree.Buy(SkillTree.Buy(2, ranks, "FarmRate1"), ranks, "FarmRate1")
		expect.equal(points, 0)
		expect.equal(SkillTree.Rank(ranks, "FarmRate1"), 2)
		local ok, reason = SkillTree.CanBuy(points, ranks, "FarmRate1")
		expect.falsy(ok)
		expect.truthy(reason ~= nil)
	end)

	-- Unknown node and zero points are rejected.
	t.test("buy rejects unknown node and insufficient points", function()
		expect.falsy(SkillTree.CanBuy(1, {}, "Nope"))
		expect.falsy(SkillTree.CanBuy(0, {}, "FarmRate1"))
	end)

	-- A locked node is refused while its prerequisite sits at rank 0, and the reason names the parent.
	t.test("canbuy refuses locked node and names required parent", function()
		local ok, reason = SkillTree.CanBuy(5, {}, "FarmLuck")
		expect.falsy(ok)
		expect.truthy(string.find(reason, "Sève lente", 1, true) ~= nil)
	end)

	-- As soon as the prerequisite reaches rank 1 the node becomes purchasable.
	t.test("canbuy accepts once prerequisite reaches rank 1", function()
		expect.truthy(SkillTree.CanBuy(5, { FarmRate1 = 1 }, "FarmLuck"))
	end)

	-- The Requires helper normalizes root nodes to an empty list (and keeps chain links intact).
	t.test("requires helper returns empty list without prerequisites", function()
		expect.deepEqual(SkillTree.Requires(SkillTree.Node("FarmRate1")), {})
		expect.deepEqual(SkillTree.Requires(SkillTree.Node("SecretOmen")), { "MutOmen" })
	end)

	-- Effects sum ranks across nodes of the same effect.
	t.test("effects sum ranks across nodes of same effect", function()
		local effects = SkillTree.Effects({
			FarmRate1 = 3,
			FarmRate2 = 1,
			MutOmen = 2,
			SecretOmen = 1,
			MarketFeeCut = 3,
		})
		expect.near(effects.EssenceRate, 0.25, 1e-9)
		expect.near(effects.MutationBonus, 0.12, 1e-9)
		expect.truthy(effects.SecretOmen == true)
		expect.near(effects.MarketFeeReduction, 0.03, 1e-9)
		expect.equal(effects.HatchLuck, 0)
	end)

	-- An empty tree yields zeroed effects.
	t.test("effects of empty tree are zeroed", function()
		local effects = SkillTree.Effects({})
		expect.equal(effects.EssenceRate, 0)
		expect.equal(effects.RiftRewardMult, 0)
		expect.falsy(effects.SecretOmen)
	end)
end
