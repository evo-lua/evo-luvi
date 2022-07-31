local EventListenerMixin = C_EventSystem.EventListenerMixin

describe("EventListenerMixin", function()
	local function createNewEventListener()
		local tempObject = {}
		mixin(tempObject, EventListenerMixin)

		tempObject.numHelloWorldTriggers = 0
		tempObject.isPayloadPassed = false
		tempObject.isEventPassed = false

		function tempObject:OnHelloWorld(eventID, payload)
			tempObject.numHelloWorldTriggers = tempObject.numHelloWorldTriggers + 1

			-- This is for repeated triggers, to ensure they always pass the arguments
			assertEquals(eventID, "HELLO_WORLD")
			assertEquals(payload, { hi = 42, test = 123 })

			-- This only verifies that the above assertions haven't been skipped
			tempObject.isPayloadPassed = true
			tempObject.isEventPassed = true
		end

		return tempObject
	end

	describe("OnEvent", function()
		local listener = createNewEventListener()
		it("should forward the event ID and payload to the registered event listener", function()
			-- Can't hook the event handlers here, as the'yre stored as function values in the event registry (no lookup)
			assertEquals(listener.numHelloWorldTriggers, 0)
			assertFalse(listener.isPayloadPassed)
			assertFalse(listener.isEventPassed)

			listener:OnEvent("HELLO_WORLD", { hi = 42, test = 123 })
			assertEquals(listener.numHelloWorldTriggers, 1)
			assertTrue(listener.isPayloadPassed)
			assertTrue(listener.isEventPassed)

			listener:OnEvent("HELLO_WORLD", { hi = 42, test = 123 })
			assertEquals(listener.numHelloWorldTriggers, 2)
		end)
	end)

	describe("RegisterEvent", function()
		local listener = createNewEventListener()

		it("should add an event listener for the given event", function()
			listener:RegisterEvent("HELLO_WORLD")

			-- Can't hook the event handlers here, as the'yre stored as function values in the event registry (no lookup)
			assertEquals(listener.numHelloWorldTriggers, 0)
			assertFalse(listener.isPayloadPassed)
			assertFalse(listener.isEventPassed)

			C_EventSystem.TriggerEvent("HELLO_WORLD", { hi = 42, test = 123 })
			assertEquals(listener.numHelloWorldTriggers, 1)
			assertTrue(listener.isPayloadPassed)
			assertTrue(listener.isEventPassed)

			C_EventSystem.TriggerEvent("HELLO_WORLD", { hi = 42, test = 123 })
			assertEquals(listener.numHelloWorldTriggers, 2)

			listener:UnregisterEvent("HELLO_WORLD")
		end)

		it("should raise an error if the event listener has already been registered for the given event", function()
			EventListenerMixin:RegisterEvent("HELLO_WORLD_EVENT")
			local function registerDuplicateEvent()
				EventListenerMixin:RegisterEvent("HELLO_WORLD_EVENT")
			end
			assertThrows(
				registerDuplicateEvent,
				"Failed to AddEventListener for HELLO_WORLD_EVENT (already registered)"
			)

			EventListenerMixin:UnregisterEvent("HELLO_WORLD_EVENT")
		end)
	end)

	describe("UnregisterEvent", function()
		it("should have no effect if no event listener has been registered for the given event", function()
			local listener = createNewEventListener()

			assertEquals(listener.numHelloWorldTriggers, 0)
			assertFalse(listener.isPayloadPassed)
			assertFalse(listener.isEventPassed)

			C_EventSystem.TriggerEvent("HELLO_WORLD", { hi = 42, test = 123 })
			assertEquals(listener.numHelloWorldTriggers, 0)
			assertFalse(listener.isPayloadPassed)
			assertFalse(listener.isEventPassed)

			C_EventSystem.TriggerEvent("HELLO_WORLD", { hi = 42, test = 123 })
			assertEquals(listener.numHelloWorldTriggers, 0)
		end)
	end)

	describe("UnregisterAllEvents", function()
		local listener = createNewEventListener()
		listener:RegisterEvent("ASDF")
		listener:RegisterEvent("HI")
		it("should remove all registered event listeners", function()
			assertTrue(listener:IsEventRegistered("ASDF"))
			assertTrue(listener:IsEventRegistered("HI"))
			listener:UnregisterAllEvents()
			assertFalse(listener:IsEventRegistered("ASDF"))
			assertFalse(listener:IsEventRegistered("HI"))
		end)
	end)

	describe("IsEventRegistered", function()
		local listener = createNewEventListener()
		it("should return false if the given event has not been registered", function()
			assertFalse(listener:IsEventRegistered("HI"))
		end)

		it("should return true if the given event has been registered", function()
			listener:RegisterEvent("ASDF")
			assertTrue(listener:IsEventRegistered("ASDF"))

			listener:UnregisterEvent("ASDF")
		end)
	end)

	describe("GetDefaultListenerName", function()
		it("should return the default catchall handler name if no event ID was passed", function()
			assertEquals(EventListenerMixin:GetDefaultListenerName(), EventListenerMixin.DEFAULT_EVENT_HANDLER_NAME)
		end)

		it("should return the expected event handler name for the given event ID", function()
			assertEquals(EventListenerMixin:GetDefaultListenerName("APPLICATION_SHUTDOWN"), "OnApplicationShutdown")
		end)
	end)
end)
