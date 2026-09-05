--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local PublicWall = require(ReplicatedStorage.Shared.PublicWall)
local SafeStore = require(script.Parent.SafeStore)

local RecognitionService = {}

local secretStore = SafeStore.Get(Config.SECRET_WALL_STORE, {})
local supportStore = SafeStore.Get(Config.SUPPORT_WALL_STORE, {})
local walls: { [string]: { Body: TextLabel, Title: TextLabel } } = {}

local function Read(store: any): { any }
	local ok, entries = pcall(function()
		return store:GetAsync("Entries")
	end)
	if not ok or type(entries) ~= "table" then
		return {}
	end
	local result = {}
	for _, entry in entries do
		if
			type(entry) == "table"
			and type(entry.Id) == "string"
			and type(entry.Name) == "string"
			and type(entry.Text) == "string"
		then
			table.insert(result, entry)
		end
	end
	return result
end

local function Render(kind: string, entries: { any }, emptyText: string)
	local wall = walls[kind]
	if not wall then
		return
	end
	local lines = {}
	for index = 1, math.min(12, #entries) do
		local entry = entries[index]
		table.insert(lines, `{index}. {entry.Name} — {entry.Text}`)
	end
	wall.Title.Text = if #entries > 0
		then `{wall.Title:GetAttribute("BaseTitle")} ({#entries})`
		else wall.Title:GetAttribute("BaseTitle")
	wall.Body.Text = if #lines > 0 then table.concat(lines, "\n") else emptyText
end

local function Refresh()
	Render("Secrets", Read(secretStore), "Aucun Secret révélé pour le moment.")
	Render("Support", Read(supportStore), "Le mur attend son premier soutien.")
end

local function CreateWall(root: Folder, key: string, title: string, position: Vector3, color: Color3, emptyText: string)
	local wall = Instance.new("Part")
	wall.Name = key
	wall.Size = Vector3.new(32, 12, 2)
	wall.Position = position
	wall.Anchored = true
	wall.Material = Enum.Material.Marble
	wall.Color = color
	wall.Parent = root

	local surface = Instance.new("SurfaceGui")
	surface.Name = "Display"
	surface.Face = Enum.NormalId.Front
	surface.LightInfluence = 0
	surface.PixelsPerStud = 35
	surface.CanvasSize = Vector2.new(1120, 420)
	surface.Parent = wall

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.BackgroundTransparency = 1
	titleLabel.Size = UDim2.new(1, -32, 0, 72)
	titleLabel.Position = UDim2.fromOffset(16, 10)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextColor3 = Color3.fromRGB(255, 230, 150)
	titleLabel.TextScaled = true
	titleLabel.Text = title
	titleLabel:SetAttribute("BaseTitle", title)
	titleLabel.Parent = surface

	local body = Instance.new("TextLabel")
	body.Name = "Entries"
	body.BackgroundTransparency = 1
	body.Size = UDim2.new(1, -48, 1, -100)
	body.Position = UDim2.fromOffset(24, 88)
	body.Font = Enum.Font.Gotham
	body.TextColor3 = Color3.fromRGB(245, 245, 250)
	body.TextSize = 26
	body.TextWrapped = true
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.Text = emptyText
	body.Parent = surface

	walls[key] = { Body = body, Title = titleLabel }
end

local function BuildWalls()
	if Workspace:FindFirstChild("PublicRecognition") then
		return
	end
	local root = Instance.new("Folder")
	root.Name = "PublicRecognition"
	root.Parent = Workspace
	CreateWall(
		root,
		"Secrets",
		"Détenteurs des Secrets",
		Config.SECRET_WALL_POSITION,
		Color3.fromRGB(55, 30, 75),
		"Aucun Secret révélé pour le moment."
	)
	CreateWall(
		root,
		"Support",
		"Mur des soutiens",
		Config.SUPPORT_WALL_POSITION,
		Color3.fromRGB(80, 65, 35),
		"Le mur attend son premier soutien."
	)
end

local function StoreEntry(store: any, entry: { [string]: any }): boolean
	local ok, updated = pcall(function()
		return store:UpdateAsync("Entries", function(old)
			return PublicWall.Upsert(old, entry, Config.PUBLIC_WALL_LIMIT)
		end)
	end)
	if ok and type(updated) == "table" then
		return true
	end
	return false
end

function RecognitionService:RecordSecret(player: Player, speciesName: string, creatureId: string, mutation: string?)
	local detail = if mutation and mutation ~= "" then `{speciesName} ({mutation})` else speciesName
	local saved = StoreEntry(secretStore, {
		Id = creatureId,
		Name = player.Name,
		Text = detail,
	})
	if not saved then
		warn(`[RecognitionService] Secret wall unavailable for {player.UserId}`)
		return
	end
	Render("Secrets", Read(secretStore), "Aucun Secret révélé pour le moment.")
end

function RecognitionService:RecordSupport(player: Player, tier: string, receiptKey: string): boolean
	local saved = StoreEntry(supportStore, {
		Id = receiptKey,
		Name = player.Name,
		Text = `Soutien {tier}`,
	})
	if saved then
		Render("Support", Read(supportStore), "Le mur attend son premier soutien.")
	end
	return saved
end

function RecognitionService:Start()
	BuildWalls()
	Refresh()
	task.spawn(function()
		while true do
			task.wait(60)
			Refresh()
		end
	end)
end

return RecognitionService
