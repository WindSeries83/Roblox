--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local RemoteRegistry = require(script.Parent.RemoteRegistry)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

assert(RemoteRegistry.Validate(RemoteRegistry.Names), "Invalid remote registry")
local Net = {}

local function CleanServerRemotes()
	if not RunService:IsServer() then
		return
	end
	local expected: { [string]: boolean } = {}
	local seen: { [string]: boolean } = {}
	for _, name in RemoteRegistry.Names do
		expected[name] = true
	end
	for _, child in Remotes:GetChildren() do
		if not expected[child.Name] or not child:IsA("RemoteEvent") or seen[child.Name] then
			child:Destroy()
		else
			seen[child.Name] = true
		end
	end
end

CleanServerRemotes()

local function Event(name: string): RemoteEvent
	local existing = Remotes:FindFirstChild(name)
	if existing then
		assert(existing:IsA("RemoteEvent"), `Remote is not a RemoteEvent: {name}`)
		return existing
	end
	if not RunService:IsServer() then
		return Remotes:WaitForChild(name) :: RemoteEvent
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
