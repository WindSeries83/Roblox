local Incubation = {}

Incubation.MAX_PLACED = 3

-- Slots circulaires de rayon 4 autour de l'origine, angles réguliers,
-- orientés vers l'extérieur (dos à la couveuse). y = origin.y : le service
-- pose l'œuf au-dessus via un offset vertical.
function Incubation.SlotCFrame(origin: Vector3, index: number): CFrame
	local angle = (index - 1) * (2 * math.pi / Incubation.MAX_PLACED)
	local offset = Vector3.new(math.cos(angle), 0, math.sin(angle)) * 4
	local position = origin + offset
	return CFrame.lookAt(position, origin + offset * 2)
end

return Incubation
