--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local RemoteRegistry = require(script.Parent.RemoteRegistry)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

assert(RemoteRegistry.Validate(RemoteRegistry.Names), "Invalid remote registry")
local Net = {}

local function Event(name: string): RemoteEvent
	local existing = Remotes:FindFirstChild(name)
	if existing then
		return existing :: RemoteEvent
	end
	if not RunService:IsServer() then
		error(`Missing server remote: {name}`)
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = Remotes
	return remote
end

for _, name in RemoteRegistry.Names do
	Net[name] = Event(name)
end

return Net
