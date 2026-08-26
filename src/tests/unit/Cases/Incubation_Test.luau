return function(t)
	local expect = t.expect
	local Incubation = require(game.ReplicatedStorage.Shared.Incubation)

	t.test("MAX_PLACED vaut 3", function()
		expect.equal(Incubation.MAX_PLACED, 3)
	end)

	-- Slots compactes posés sur le plateau : rayon constant, angles réguliers, à plat.
	t.test("slots à rayon constant, angles réguliers, y constant", function()
		local origin = Vector3.new(10, 5, -3)
		local positions = {}
		for i = 1, Incubation.MAX_PLACED do
			local pos = Incubation.SlotCFrame(origin, i).Position
			expect.near((pos - origin).Magnitude, Incubation.SLOT_RADIUS, 0.01)
			expect.near(pos.Y, origin.Y, 0.01)
			table.insert(positions, pos)
		end
		local d12 = (positions[1] - positions[2]).Magnitude
		local d23 = (positions[2] - positions[3]).Magnitude
		local d31 = (positions[3] - positions[1]).Magnitude
		expect.near(d12, d23, 0.01)
		expect.near(d23, d31, 0.01)
	end)

	-- Pas de chevauchement : distance centre-à-centre > diamètre coquille (1,4).
	t.test("distance inter-slots supérieure au diamètre d'un oeuf", function()
		local a = Incubation.SlotCFrame(Vector3.zero, 1).Position
		local b = Incubation.SlotCFrame(Vector3.zero, 2).Position
		expect.truthy((a - b).Magnitude > 1.4)
	end)

	t.test("SlotOffset cohérent avec SlotCFrame", function()
		local origin = Vector3.new(1, 5, 2)
		for i = 1, Incubation.MAX_PLACED do
			expect.near(
				(Incubation.SlotCFrame(origin, i).Position - origin - Incubation.SlotOffset(i)).Magnitude,
				0,
				0.001
			)
		end
	end)

	t.test("index 4 == index 1 (cycle complet)", function()
		local first = Incubation.SlotCFrame(Vector3.zero, 1).Position
		local wrapped = Incubation.SlotCFrame(Vector3.zero, Incubation.MAX_PLACED + 1).Position
		expect.near((first - wrapped).Magnitude, 0, 0.01)
	end)
end
