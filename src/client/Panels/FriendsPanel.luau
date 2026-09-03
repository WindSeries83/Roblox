local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiKit = require(script.Parent.Parent.UiKit)
local Net = require(ReplicatedStorage.Shared.Net)

local FriendsPanel = {}

local page: ScrollingFrame?
local status: TextLabel?
local friends: { any } = {}
local pendingInvites: { [string]: any } = {}
local inviteViews: { [string]: { Remaining: TextLabel, Buttons: { TextButton } } } = {}

local FRIEND_ACTIONS = {
	FriendsSync = true,
	JoinFriend = true,
	InviteFriend = true,
	RespondFriendInvite = true,
	VisitPlot = true,
}

local function SetStatus(text: string, color: Color3?)
	if status then
		status.Text = text
		status.TextColor3 = color or UiKit.TINTS.WHITE
	end
end

local function RemainingText(expiresAt: number): string
	local remaining = math.max(0, expiresAt - os.time())
	return if remaining > 0 then `Expire dans {remaining}s` else "Expirée"
end

local function SetInviteButtonsEnabled(buttons: { TextButton }, enabled: boolean)
	for _, button in buttons do
		button.Active = enabled
		button.Selectable = enabled
		button.TextColor3 = if enabled then UiKit.TINTS.WHITE else Color3.fromRGB(150, 150, 160)
	end
end

local function AddActions(parent: Frame, labels: { string }, callback: (string) -> ())
	local actions = UiKit.Create("Frame", {
		Name = "Actions",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 44),
		Parent = parent,
	}) :: Frame
	UiKit.Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = actions,
	})
	local buttons = {}
	for index, label in labels do
		local button = UiKit.Button(actions, label, UDim2.new(1 / #labels, -6, 0, 44))
		button.LayoutOrder = index
		button.BackgroundColor3 = UiKit.TINTS.DARK
		button.Activated:Connect(function()
			callback(label)
		end)
		table.insert(buttons, button)
	end
	return actions, buttons
end

local function Render()
	if not page then
		return
	end
	UiKit.Clear(page)
	UiKit.Title(page, "Amis")

	local inviteIds = {}
	for inviteId in pendingInvites do
		table.insert(inviteIds, inviteId)
	end
	table.sort(inviteIds)
	if #inviteIds > 0 then
		UiKit.SectionTitle(page, "Invitations reçues")
	end
	inviteViews = {}
	for _, inviteId in inviteIds do
		local invite = pendingInvites[inviteId]
		local cell = UiKit.Cell(page)
		cell.Name = `Invite_{inviteId}`
		UiKit.Create("UIListLayout", {
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = cell,
		})
		UiKit.Create("TextLabel", {
			BackgroundTransparency = 1,
			TextColor3 = UiKit.TINTS.WHITE,
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.fromScale(1, 0),
			TextWrapped = true,
			Text = `{invite.FromName or "Un ami"} t'invite à rejoindre sa session.`,
			Parent = cell,
		})
		local remaining = UiKit.Create("TextLabel", {
			BackgroundTransparency = 1,
			TextColor3 = UiKit.TINTS.ACCENT,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, 0, 0, 20),
			Text = RemainingText(invite.ExpiresAt),
			Parent = cell,
		}) :: TextLabel
		local _, buttons = AddActions(cell, { "Accepter", "Refuser" }, function(label)
			if invite.ExpiresAt <= os.time() then
				SetStatus("Cette invitation a expiré.", UiKit.TINTS.RED)
				return
			end
			local accepted = label == "Accepter"
			SetInviteButtonsEnabled(buttons, false)
			Net.RespondFriendInvite:FireServer(inviteId, accepted)
		end)
		inviteViews[inviteId] = { Remaining = remaining, Buttons = buttons }
	end

	UiKit.SectionTitle(page, "Amis dans Rift Beasts")
	if #friends == 0 then
		UiKit.Title(page, "Aucun ami en ligne pour l'instant.", 13)
		return
	end
	for _, friend in friends do
		if type(friend) == "table" and type(friend.UserId) == "number" then
			local cell = UiKit.Cell(page)
			UiKit.Create("UIListLayout", {
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = cell,
			})
			local location = if friend.Here then "dans ce serveur" else "autre serveur"
			UiKit.Create("TextLabel", {
				BackgroundTransparency = 1,
				TextColor3 = if friend.Here then UiKit.TINTS.GREEN else UiKit.TINTS.WHITE,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromScale(1, 0),
				TextWrapped = true,
				Text = `{friend.Name or "Ami"} — {location}`,
				Parent = cell,
			})

			local labels = {}
			if friend.Here and friend.PlotAvailable then
				table.insert(labels, "Visiter")
			elseif friend.Here then
				UiKit.Create("TextLabel", {
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(170, 170, 180),
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					Size = UDim2.new(1, 0, 0, 20),
					Text = "Plot momentanément indisponible.",
					Parent = cell,
				})
			elseif not friend.Here then
				table.insert(labels, "Rejoindre")
			end
			table.insert(labels, "Inviter")
			AddActions(cell, labels, function(label)
				if label == "Visiter" then
					Net.VisitPlot:FireServer(friend.UserId)
				elseif label == "Rejoindre" then
					Net.JoinFriend:FireServer(friend.UserId)
				else
					Net.InviteFriend:FireServer(friend.UserId)
				end
			end)
		end
	end
end

local function Refresh()
	SetStatus("Actualisation…")
	Net.FriendsSync:FireServer()
end

function FriendsPanel.Create(parent: Instance): Frame
	local panel = UiKit.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = parent,
	}) :: Frame

	local header = UiKit.Create("Frame", {
		Name = "Header",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 50),
		Parent = panel,
	}) :: Frame
	local refresh = UiKit.Button(header, "Actualiser", UDim2.fromOffset(112, 44))
	refresh.Activated:Connect(Refresh)
	status = UiKit.Create("TextLabel", {
		Name = "Status",
		BackgroundTransparency = 1,
		TextColor3 = UiKit.TINTS.WHITE,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Position = UDim2.fromOffset(120, 0),
		Size = UDim2.new(1, -120, 0, 44),
		Text = "",
		Parent = header,
	}) :: TextLabel

	page = UiKit.Scroller(panel, UDim2.fromOffset(0, 56), UDim2.new(1, 0, 1, -56))
	page.Name = "FriendsPage"
	Render()

	Net.FriendsSync.OnClientEvent:Connect(function(payload)
		friends = if payload and type(payload.Online) == "table" then payload.Online else {}
		SetStatus(
			if payload and payload.Warning then payload.Warning else `Liste actualisée ({#friends} ami(s)).`,
			if payload and payload.Warning then UiKit.TINTS.ACCENT else UiKit.TINTS.GREEN
		)
		Render()
	end)

	Net.FriendInvite.OnClientEvent:Connect(function(payload)
		if
			type(payload) ~= "table"
			or type(payload.InviteId) ~= "string"
			or type(payload.ExpiresAt) ~= "number"
			or payload.ExpiresAt <= os.time()
		then
			return
		end
		pendingInvites[payload.InviteId] = {
			FromName = if type(payload.FromName) == "string" then payload.FromName else "Un ami",
			ExpiresAt = payload.ExpiresAt,
		}
		SetStatus(`Invitation reçue de {pendingInvites[payload.InviteId].FromName}.`, UiKit.TINTS.ACCENT)
		Render()
	end)

	Net.ActionResult.OnClientEvent:Connect(function(result)
		if type(result) ~= "table" or not FRIEND_ACTIONS[result.Action] then
			return
		end
		if result.Action == "RespondFriendInvite" and type(result.InviteId) == "string" then
			pendingInvites[result.InviteId] = nil
		end
		if result.Success then
			local message = {
				FriendsSync = "Liste d'amis actualisée.",
				JoinFriend = "Session de l'ami rejointe.",
				InviteFriend = "Invitation envoyée.",
				RespondFriendInvite = if result.Accepted then "Invitation acceptée." else "Invitation refusée.",
				VisitPlot = "Visite ouverte en lecture seule.",
			}
			SetStatus(message[result.Action] or "Action sociale terminée.", UiKit.TINTS.GREEN)
		else
			SetStatus(result.Reason or "Action sociale refusée.", UiKit.TINTS.RED)
		end
		Render()
	end)

	task.spawn(function()
		while page and page.Parent do
			for inviteId, view in inviteViews do
				local invite = pendingInvites[inviteId]
				if invite then
					local remaining = math.max(0, invite.ExpiresAt - os.time())
					view.Remaining.Text = RemainingText(invite.ExpiresAt)
					if remaining <= 0 then
						view.Remaining.TextColor3 = UiKit.TINTS.RED
						SetInviteButtonsEnabled(view.Buttons, false)
					end
				end
			end
			task.wait(1)
		end
	end)

	task.spawn(function()
		task.wait(1)
		Refresh()
	end)

	return panel
end

return FriendsPanel
