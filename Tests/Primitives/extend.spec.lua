describe("extend", function()
	it("should still work if the prototype object doesn't have a metatable", function()
		local child = {}
		local parent = {}
		function parent:hello() end

		extend(child, parent)
		assertEquals(child.hello, parent.hello)
	end)

	it("should set up a metatable such that the child inherits the prototype's functionality", function()
		local child = {}
		local parent = {}
		function parent:thisFunctionShouldBeInherited() end

		extend(child, parent)
		assertEquals(child.thisFunctionShouldBeInherited, parent.thisFunctionShouldBeInherited)
	end)

	it("should copy all existing fields from the prototype's metatable", function()
		local child = {}
		local parent = {}
		local parentOfParent = {}
		function parent:thisFunctionShouldBeInherited() end
		function parentOfParent:thisFunctionShouldAlsoBeInherited() end

		extend(parent, parentOfParent)
		extend(child, parent)

		assertEquals(child.thisFunctionShouldBeInherited, parent.thisFunctionShouldBeInherited)
		assertEquals(child.thisFunctionShouldAlsoBeInherited, parentOfParent.thisFunctionShouldAlsoBeInherited)
		assertEquals(parent.thisFunctionShouldAlsoBeInherited, parentOfParent.thisFunctionShouldAlsoBeInherited)
	end)
end)
