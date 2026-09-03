local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local TutorialBridge = require(ReplicatedStorage.Shared.TutorialBridge)

-- État FTUE unique : ObjectiveBanner est le seul renderer.
Net.Sync.OnClientEvent:Connect(function(state)
	if not state or state.TutorialDone then
		TutorialBridge.Set("TutorialActive", false)
		return
	end
	TutorialBridge.Set("TutorialActive", true)
	TutorialBridge.Set("TutorialState", state)
end)

return nil
