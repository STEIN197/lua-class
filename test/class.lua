local LuaUnit = dofile "lib/luaunit.lua"
dofile "src/class.lua"

class "A" {

	returnSelf = function (self)
		return self
	end;

	methodA = function (self)
		return "A"
	end;
}

class "B" {

	returnSelf = function (self)
		return self
	end;

	methodB = function (self)
		return "B"
	end;
}

class "Constructor" {

	a = nil;
	b = nil;
	sum = nil;

	constructor = function (self, a, b)
		self.a = a
		self.b = b
		self.sum = a + b
	end;
}

TestClass = {
	testExistence = function ()
		LuaUnit.assertTable(A)
		LuaUnit.assertTable(B)
		LuaUnit.assertNil(C)
	end;
	testInstantiating = function ()
		LuaUnit.assertTable(A())
		LuaUnit.assertTable(B())
	end;
	testConstructor = function ()
		local var = Constructor(2, 3)
		LuaUnit.assertEquals(var.a, 2)
		LuaUnit.assertEquals(var.b, 3)
		LuaUnit.assertEquals(var.sum, 5)
	end;
	testInstantiaingNotModifyingClass = function ()
		Constructor(2, 3)
		LuaUnit.assertNil(Constructor.a)
	end;
	testClassesInGlobal = function ()
		LuaUnit.assertEquals(_G['A'], A)
		LuaUnit.assertEquals(_G['Constructor'], Constructor)
	end;
	testInstanceof = function ()
		local a = A()
		local b = B()
		LuaUnit.assertTrue(a:instanceof "A")
		LuaUnit.assertTrue(a:instanceof(A))
		LuaUnit.assertTrue(b:instanceof "B")
		LuaUnit.assertTrue(b:instanceof(B))
		LuaUnit.assertFalse(a:instanceof "B")
		LuaUnit.assertFalse(a:instanceof(B))
		LuaUnit.assertFalse(B:instanceof "A")
		LuaUnit.assertFalse(B:instanceof(A))
		LuaUnit.assertTrue(a:instanceof "Object")
		LuaUnit.assertTrue(a:instanceof(Object))
		LuaUnit.assertTrue(b:instanceof "Object")
		LuaUnit.assertTrue(b:instanceof(Object))
		LuaUnit.assertTrue(a:instanceof(a:getClass()))
		LuaUnit.assertTrue(b:instanceof(b:getClass()))
	end;
	testGetClass = function ()
		local a = A()
		local b = B()
		LuaUnit.assertEquals(a:getClass(), A)
		LuaUnit.assertEquals(b:getClass(), B)
	end;
	testClassRedeclareThrowsError = function ()
		LuaUnit.assertErrorMsgContains(
			"Cannot declare class. Variable or class with name \"A\" already exists",
			function ()
				class "A" {}
			end
		)
	end;
	testClassInvalidNameThrowsError = function ()
		LuaUnit.assertErrorMsgContains(
			"Cannot declare class. Classname \"invalid name\" contains invalid characters",
			function ()
				class "invalid name" {}
			end
		)
		LuaUnit.assertErrorMsgContains(
			"Cannot declare class. Classname \"0numeric0\" contains invalid characters",
			function ()
				class "0numeric0" {}
			end
		)
	end;
	testGetMetaOnInstanceIsEmpty = function ()
		LuaUnit.assertEquals(A():getMeta(), {})
	end;
	testGetMetaOnClass = function ()
		LuaUnit.assertEquals(A.getMeta(), {name = "A"})
		LuaUnit.assertEquals(Constructor.getMeta().name, "Constructor")
		LuaUnit.assertEquals(Object.getMeta().name, "Object")
		LuaUnit.assertEquals(B():getClass().getMeta().name, "B")
	end;
}

local runner = LuaUnit.LuaUnit.new()
runner:setOutputType("text")
os.exit(runner:runSuite())
