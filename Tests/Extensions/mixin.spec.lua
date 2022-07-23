describe("mixin", function()
	it("should mix in all function values of the passed mixins", function()
		local target = {}

		local mixin1 = { test1 = function() end }
		local mixin2 = { test2 = function() end }

		mixin(target, mixin1, mixin2)

		assertEquals(target.test1, mixin1.test1)
		assertEquals(target.test2, mixin2.test2)
	end)

	it("should skip any mixins passed that aren't table values", function()
		local target = {}

		local mixin1 = { test1 = function() end }
		local mixin2 = { test2 = function() end }

		mixin(target, 42, true, "hi", mixin1, print, mixin2)

		assertEquals(target.test1, mixin1.test1)
		assertEquals(target.test2, mixin2.test2)
	end)

	it("should do nothing if the target isn't a table value", function()
		mixin(42, { test = function() end })
	end)

	it("should not overwrite existing keys on the target table", function()
	local target = { test1 = function() end }

	local mixin1 = { test1 = function() end }
	local mixin2 = { test2 = function() end }

	mixin(target, mixin1, mixin2)

	assertEquals(target.test1, target.test1)
	assertEquals(target.test2, mixin2.test2)
	end)
end)