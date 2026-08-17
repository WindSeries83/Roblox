local TutorialBridge = {
	state = {
		MenuOpen = false,
	},
}

local event = Instance.new("BindableEvent")

function TutorialBridge.Set(key: string, value: any)
	TutorialBridge.state[key] = value
	event:Fire(key)
end

function TutorialBridge.Changed(callback: (string) -> ())
	return event.Event:Connect(callback)
end

return TutorialBridge
