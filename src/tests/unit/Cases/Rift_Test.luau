return function(t)
	local expect = t.expect
	local Config = require(game.ReplicatedStorage.Shared.Config)

	t.test("relic defeat rate is one quarter of win rate", function()
		for _, tier in { "T1", "T2", "T3" } do
			expect.near(Config.RIFT_RELIC_WEIGHTS_DEFEAT[tier], Config.RIFT_RELIC_WEIGHTS[tier] * 0.25, 0.01)
		end
	end)

	t.test("reentry cooldown is positive", function()
		expect.truthy(Config.RIFT_REENTRY_COOLDOWN >= 1)
	end)

	t.test("expedition entry window repeats every five minutes", function()
		expect.equal(Config.RIFT_INTERVAL, 5 * 60)
	end)

	t.test("first rift uses a forgiving tutorial guardian", function()
		local RiftDifficulty = require(game.ReplicatedStorage.Shared.RiftDifficulty)
		local tutorial = RiftDifficulty.For(6, true)
		local normal = RiftDifficulty.For(6, false)
		expect.equal(tutorial.GuardianHP, 48)
		expect.equal(tutorial.GuardianDamage, 8)
		expect.truthy(tutorial.GuardianHP < normal.GuardianHP)
	end)

	t.test("solo rift starts with three enemies and a boss", function()
		local RiftCombat = require(game.ReplicatedStorage.Shared.RiftCombat)
		local state = RiftCombat.Start({
			{ Id = "a", Power = 30, MaxHP = 40 },
			{ Id = "b", Power = 20, MaxHP = 50 },
			{ Id = "c", Power = 10, MaxHP = 60 },
		}, 100, false)

		expect.equal(state.EndsAt, 280)
		expect.equal(#state.Enemies, 4)
		expect.falsy(state.Enemies[1].IsBoss)
		expect.truthy(state.Enemies[4].IsBoss)
		expect.equal(state.ActiveCreature.Id, "a")
		expect.equal(#state.Reserve, 2)
	end)

	t.test("active creature can be knocked out and replaced from owned reserve", function()
		local RiftCombat = require(game.ReplicatedStorage.Shared.RiftCombat)
		local state = RiftCombat.Start({
			{ Id = "a", Power = 30, MaxHP = 40 },
			{ Id = "b", Power = 20, MaxHP = 50 },
		}, 100, false)

		RiftCombat.DamageCreature(state, 999, 100)
		expect.equal(state.ActiveCreature.HP, 0)
		expect.truthy(state.ActiveCreature.KOUntil > 100)
		expect.falsy(RiftCombat.SelectReplacement(state, "a", 100))
		expect.truthy(RiftCombat.SelectReplacement(state, "b", 100))
		expect.equal(state.ActiveCreature.Id, "b")
	end)

	t.test("a temporarily knocked out owned creature stays in reserve", function()
		local RiftCombat = require(game.ReplicatedStorage.Shared.RiftCombat)
		local state = RiftCombat.Start({
			{ Id = "a", Power = 30, MaxHP = 40, KOUntil = 110 },
			{ Id = "b", Power = 20, MaxHP = 50 },
		}, 100, false)

		expect.equal(state.ActiveCreature.Id, "b")
		expect.equal(#state.Reserve, 1)
		expect.equal(RiftCombat.DamageCreature(state, 999, 100), 50)
		expect.falsy(RiftCombat.SelectReplacement(state, "a", 109))
		expect.truthy(RiftCombat.SelectReplacement(state, "a", 110))
	end)

	t.test("player knockout, exhausted roster, and timeout defeat the rift", function()
		local RiftCombat = require(game.ReplicatedStorage.Shared.RiftCombat)
		local state = RiftCombat.Start({ { Id = "a", Power = 30, MaxHP = 40 } }, 100, false)
		RiftCombat.DamagePlayer(state, 999, 100)
		expect.equal(state.Phase, "Defeat")
		expect.equal(state.DefeatReason, "PlayerKO")

		state = RiftCombat.Start({ { Id = "a", Power = 30, MaxHP = 40 } }, 100, false)
		RiftCombat.DamageCreature(state, 999, 100)
		expect.equal(state.Phase, "Defeat")
		expect.equal(state.DefeatReason, "RosterExhausted")

		state = RiftCombat.Start({ { Id = "a", Power = 30, MaxHP = 40 } }, 100, false)
		RiftCombat.Advance(state, state.EndsAt)
		expect.equal(state.Phase, "Defeat")
		expect.equal(state.DefeatReason, "Timeout")

		state = RiftCombat.Start({ { Id = "a", Power = 30, MaxHP = 40 } }, 100, false)
		RiftCombat.EnemyAttack(state, state.EndsAt)
		expect.equal(state.Phase, "Defeat")
		expect.equal(state.DefeatReason, "Timeout")
	end)

	t.test("defeating the fourth enemy wins after the boss", function()
		local RiftCombat = require(game.ReplicatedStorage.Shared.RiftCombat)
		local state = RiftCombat.Start({ { Id = "a", Power = 1000, MaxHP = 100 } }, 100, false)

		while state.Phase == "Fight" do
			RiftCombat.PlayerAttack(state, 100)
		end

		expect.equal(state.Phase, "Victory")
		expect.truthy(state.Enemies[4].IsBoss)
	end)

	t.test("replacement at the timeout is rejected as a defeat", function()
		local RiftCombat = require(game.ReplicatedStorage.Shared.RiftCombat)
		local state = RiftCombat.Start({
			{ Id = "a", Power = 30, MaxHP = 40 },
			{ Id = "b", Power = 20, MaxHP = 50 },
		}, 100, false)

		RiftCombat.DamageCreature(state, 999, 100)
		expect.falsy(RiftCombat.SelectReplacement(state, "b", state.EndsAt))
		expect.equal(state.Phase, "Defeat")
		expect.equal(state.DefeatReason, "Timeout")
	end)

	t.test("empty or entirely knocked out rosters cannot start", function()
		local RiftCombat = require(game.ReplicatedStorage.Shared.RiftCombat)
		local empty = RiftCombat.Start({}, 100, false)
		expect.equal(empty.Phase, "Defeat")
		expect.equal(empty.DefeatReason, "RosterExhausted")

		local allKnockedOut = RiftCombat.Start({
			{ Id = "a", Power = 30, KOUntil = 110 },
			{ Id = "b", Power = 20, KOUntil = 120 },
		}, 100, false)
		expect.equal(allKnockedOut.Phase, "Defeat")
		expect.equal(allKnockedOut.DefeatReason, "RosterExhausted")
	end)

	t.test("invalid and duplicate creature ids are excluded from the roster", function()
		local RiftCombat = require(game.ReplicatedStorage.Shared.RiftCombat)
		local state = RiftCombat.Start({
			{ Id = "a", Power = 30 },
			{ Id = "a", Power = 99 },
			{ Id = 12, Power = 99 },
			{ Id = "b", Power = 20 },
		}, 100, false)

		expect.equal(state.ActiveCreature.Id, "a")
		expect.equal(#state.Reserve, 1)
		expect.equal(state.Reserve[1].Id, "b")
	end)

	t.test("auto combat respects its cadence", function()
		local RiftCombat = require(game.ReplicatedStorage.Shared.RiftCombat)
		local state = RiftCombat.Start({ { Id = "a", Power = 100, MaxHP = 100 } }, 100, false)
		local enemyHP = state.Enemy.HP

		expect.truthy(RiftCombat.AutoTick(state, 100) > 0)
		expect.truthy(state.Enemy.HP < enemyHP)
		local afterFirstHit = state.Enemy.HP
		expect.equal(RiftCombat.AutoTick(state, 100.1), 0)
		expect.equal(state.Enemy.HP, afterFirstHit)
	end)

	t.test("tactical stance changes the next automatic exchange", function()
		local RiftCombat = require(game.ReplicatedStorage.Shared.RiftCombat)
		local power = RiftCombat.Start({ { Id = "a", Power = 100, MaxHP = 100 } }, 100, false)
		local guard = RiftCombat.Start({ { Id = "a", Power = 100, MaxHP = 100 } }, 100, false)

		expect.truthy(RiftCombat.ChooseBonus(power, "Power"))
		expect.truthy(RiftCombat.ChooseBonus(guard, "Guard"))
		expect.falsy(RiftCombat.ChooseBonus(guard, "Unknown"))
		expect.truthy(RiftCombat.AutoTick(power, 100) > RiftCombat.AutoTick(guard, 100))
		expect.truthy(guard.PlayerHP > power.PlayerHP)
	end)
end
