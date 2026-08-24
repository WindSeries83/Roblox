local Incubation = {}

Incubation.MAX_PLACED = 3

-- Rayon du triangle de slots, calibrable après capture écran si la couveuse
-- s'avère plus petite que prévu.
Incubation.SLOT_RADIUS = 1.2

-- Slots compacts posés SUR le plateau : triangle régulier, chaque œuf face au centre.
function Incubation.SlotCFrame(origin: Vector3, index: number): CFrame
	local angle = (index - 1) * (2 * math.pi / Incubation.MAX_PLACED) - math.pi / 2
	local offset = Vector3.new(math.cos(angle), 0, math.sin(angle)) * Incubation.SLOT_RADIUS
	return CFrame.lookAt(origin + offset, origin)
end

return Incubation
