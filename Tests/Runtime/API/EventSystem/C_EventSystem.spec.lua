describe("C_EventSystem", function()
	describe("AddEventListener", function()
		it("should raise an error if passed a nil value", function()
			local expectedErrorMessage = "Usage: AddEventListener(eventID : string, listener : table)"
			assertThrows(function()
				C_EventSystem.AddEventListener()
			end, expectedErrorMessage)
			assertThrows(function()
				C_EventSystem.AddEventListener(nil, {})
			end, expectedErrorMessage)
			assertThrows(function()
				C_EventSystem.AddEventListener("DOES_NOT_EXIST")
			end, expectedErrorMessage)
		end)

		it("should raise an error if the listener passed isn't an event handler", function()
			local expectedErrorMessage =
				"Failed to AddEventListener for TEST_EVENT (listener must implement an OnEvent method)"
			assertThrows(function()
				C_EventSystem.AddEventListener("TEST_EVENT", {})
			end, expectedErrorMessage)
		end)
	end)

	describe("RemoveEventListener", function()
		it("should raise an error if passed a nil value", function()
			local expectedErrorMessage = "Usage: RemoveEventListener(eventID : string, listener : table)"
			assertThrows(function()
				C_EventSystem.RemoveEventListener()
			end, expectedErrorMessage)
			assertThrows(function()
				C_EventSystem.RemoveEventListener(nil, {})
			end, expectedErrorMessage)
			assertThrows(function()
				C_EventSystem.RemoveEventListener("DOES_NOT_EXIST")
			end, expectedErrorMessage)
		end)

		it("should return true when successfully unregistering an event listener", function()
			local tempObject = {}
			mixin(tempObject, C_EventSystem.EventListenerMixin)
			C_EventSystem.AddEventListener("TEST_EVENT", tempObject)
			assertTrue(C_EventSystem.RemoveEventListener("TEST_EVENT", tempObject))
			assertEquals(C_EventSystem.GetRegisteredEventListeners("TEST_EVENT"), {})
		end)
	end)

	describe("TriggerEvent", function()
		it("should raise an error if no eventID is passed", function()
			assertThrows(function()
				C_EventSystem.TriggerEvent()
			end, "Usage: TriggerEvent(eventID : string, payload : table?)")
		end)

		it("should raise an error if a non-table payload argument is passed", function()
			assertThrows(function()
				C_EventSystem.TriggerEvent("TEST", 42)
			end, "Usage: TriggerEvent(eventID : string, payload : table?)")
		end)

		it("should notify all event listeners that have been registered for the given event", function()
			local triggeredEvents = {
				["TEST_EVENT"] = {},
			}

			local tempObject = {}
			function tempObject:OnEvent(eventID, payload)
				triggeredEvents[eventID] = triggeredEvents[eventID] or {}
				local eventLogEntry = {
					name = eventID,
					arguments = payload,
				}
				table.insert(triggeredEvents[eventID], eventLogEntry)
			end

			assertEquals(#triggeredEvents["TEST_EVENT"], 0)

			C_EventSystem.AddEventListener("TEST_EVENT", tempObject)
			assertEquals(#triggeredEvents["TEST_EVENT"], 0)

			C_EventSystem.TriggerEvent("TEST_EVENT")
			assertEquals(#triggeredEvents["TEST_EVENT"], 1)
			C_EventSystem.TriggerEvent("TEST_EVENT")
			assertEquals(#triggeredEvents["TEST_EVENT"], 2)
			C_EventSystem.TriggerEvent("TEST_EVENT")
			assertEquals(#triggeredEvents["TEST_EVENT"], 3)

			C_EventSystem.RemoveEventListener("TEST_EVENT", tempObject)
		end)
	end)

	describe("GetRegisteredEventListeners", function()
		it("should return an empty table if no event listeners have been registered for the given event", function()
			assertEquals(C_EventSystem.GetRegisteredEventListeners("DOES_NOT_EXIST"), {})
		end)

		it("should return a list of event listeners if at least one has been registered for the given event", function()
			local tempObject = {}
			local anotherObject = {}
			mixin(tempObject, C_EventSystem.EventListenerMixin)
			mixin(anotherObject, C_EventSystem.EventListenerMixin)

			C_EventSystem.AddEventListener("TEST_EVENT", tempObject)
			C_EventSystem.AddEventListener("TEST_EVENT", anotherObject)
			assertEquals(
				C_EventSystem.GetRegisteredEventListeners("TEST_EVENT"),
				{ [tempObject] = tempObject, [anotherObject] = anotherObject }
			)

			assertTrue(C_EventSystem.RemoveEventListener("TEST_EVENT", tempObject))
			assertTrue(C_EventSystem.RemoveEventListener("TEST_EVENT", anotherObject))
			assertEquals(C_EventSystem.GetRegisteredEventListeners("TEST_EVENT"), {})
		end)

		it("should return an empty table if no event ID was passed", function()
			assertEquals(C_EventSystem.GetRegisteredEventListeners(), {})
		end)
	end)
end)
