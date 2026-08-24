local Incubation = {}

Incubation.MAX_PLACED = 3

-- Rayon du triangle de slots, calibrable après capture écran si la couveuse
-- s'avère plus petite que prévu.
Incubation.SLOT_RADIUS = 2.2

-- Décalage XZ d'un slot, pour raycaster le sol au droit de chaque œuf
-- (le raycast central tomberait sur l'œuf décoratif posé sur le socle).
function Incubation.SlotOffset(index: number): Vector3
	local angle = (index - 1) * (2 * math.pi / Incubation.MAX_PLACED) - math.pi / 2
	return Vector3.new(math.cos(angle), 0, math.sin(angle)) * Incubation.SLOT_RADIUS
end

-- Slots compacts posés SUR le plateau : triangle régulier, chaque œuf face au centre.
function Incubation.SlotCFrame(origin: Vector3, index: number): CFrame
	local offset = Incubation.SlotOffset(index)
	return CFrame.lookAt(origin + offset, origin)
end

return Incubation
