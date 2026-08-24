return function(t)
	local expect = t.expect
	local Incubation = require(game.ReplicatedStorage.Shared.Incubation)

	-- Plafond de slots d'incubation par joueur.
	t.test("MAX_PLACED vaut 3", function()
		expect.equal(Incubation.MAX_PLACED, 3)
	end)

	-- Chaque slot est à rayon 4 de l'origine, à plat, et les angles sont régulièrement espacés.
	t.test("slots à rayon 4, angles réguliers, y constant", function()
		local origin = Vector3.new(10, 5, -3)
		local positions = {}
		for i = 1, Incubation.MAX_PLACED do
			local pos = Incubation.SlotCFrame(origin, i).Position
			expect.near((pos - origin).Magnitude, 4, 0.01)
			expect.near(pos.Y, origin.Y, 0.01)
			table.insert(positions, pos)
		end
		local d12 = (positions[1] - positions[2]).Magnitude
		local d23 = (positions[2] - positions[3]).Magnitude
		local d31 = (positions[3] - positions[1]).Magnitude
		expect.near(d12, d23, 0.01)
		expect.near(d23, d31, 0.01)
	end)

	-- L'index cycle : un tour complet ramène au premier slot.
	t.test("index 4 == index 1 (cycle complet)", function()
		local origin = Vector3.zero
		local first = Incubation.SlotCFrame(origin, 1).Position
		local wrapped = Incubation.SlotCFrame(origin, Incubation.MAX_PLACED + 1).Position
		expect.near((first - wrapped).Magnitude, 0, 0.01)
	end)
end
