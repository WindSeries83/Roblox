local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiKit = require(script.Parent.Parent.UiKit)
local Net = require(ReplicatedStorage.Shared.Net)

local FriendsPanel = {}

local page

local function Refresh()
	Net.FriendsSync:FireServer()
end

function FriendsPanel.Create(parent: Instance): Frame
	local panel = UiKit.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = parent,
	})

	local refresh = UiKit.Button(panel, "Actualiser", UDim2.fromOffset(120, 26), UDim2.fromOffset(0, 0))
	refresh.Activated:Connect(Refresh)

	page = UiKit.Scroller(panel, UDim2.fromOffset(0, 32), UDim2.fromScale(1, 1))
	page.Name = "FriendsPage"

	Net.FriendsSync.OnClientEvent:Connect(function(payload)
		UiKit.Clear(page)
		UiKit.Title(page, "Amis repérés (même serveur ou ailleurs)")
		local entries = payload and payload.Online or {}
		if #entries == 0 then
			UiKit.Title(page, "Aucun ami en ligne pour l'instant. Invité tes amis à rejoindre la meute !", 13)
			return
		end
		for _, friend in entries do
			local cell = UiKit.Cell(page)
			UiKit.Create("TextLabel", {
				BackgroundTransparency = 1,
				TextColor3 = if friend.Here then UiKit.TINTS.GREEN else UiKit.TINTS.WHITE,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Size = UDim2.fromScale(0.66, 1),
				Text = `{friend.Name} — {if friend.Here then "dans ce serveur" else "autre serveur"}`,
				TextWrapped = true,
				Parent = cell,
			})
			local button = UiKit.Button(
				cell,
				if friend.Here then "Visiter" else "Rejoindre",
				UDim2.new(0.3, 0, 0, 26),
				UDim2.new(0.68, 0, 0.5, -13)
			)
			button.BackgroundColor3 = UiKit.TINTS.DARK
			button.Activated:Connect(function()
				if friend.Here then
					Net.LeaderboardVisit:FireServer(friend.UserId)
				else
					Net.JoinFriend:FireServer(friend.UserId)
				end
			end)
		end
	end)

	task.spawn(function()
		task.wait(1)
		Refresh()
	end)

	return panel
end

return FriendsPanel
