local MyApp = {}

function MyApp:OnEvent(eventID, payload)
	print("OnEvent triggered", eventID)
	print("Dumping payload...")

	dump(payload)

	print("Time to say goodbye! Exiting now...")
end

-- dump(_G)
-- local C_EventSystem = require("C_EventSystem")
C_EventSystem.AddEventListener("APPLICATION_SHUTDOWN", MyApp)

print("Registered a new listener for APPLICATION_SHUTDOWN")

return 42
