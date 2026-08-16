local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Net = {}

local function Event(name: string): RemoteEvent
	local existing = Remotes:FindFirstChild(name)
	if existing then
		return existing :: RemoteEvent
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = Remotes
	return remote
end

Net.BuyEgg = Event("BuyEgg")
Net.HatchEgg = Event("HatchEgg")
Net.RiftAttack = Event("RiftAttack")
Net.Sync = Event("Sync")
Net.HatchResult = Event("HatchResult")
Net.RareDrop = Event("RareDrop")
Net.RiftSync = Event("RiftSync")
Net.RiftEnded = Event("RiftEnded")
Net.RiftWorld = Event("RiftWorld")

return Net
