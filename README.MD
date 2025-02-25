# Lua class library
## Basic concepts
Sometimes there is a need to use classes in language that does not support them at all. Fortunately, lua allows us to use some sort of object-oriented paradigm by its dynamic nature. This simple lua package allows to use object-oriented paradigm by using usual keyword `class`.
## Table of contents
- [Basic usage](#basic-usage)
- [Inheritance](#inheritance)
- [Multiple inheritance](#multiple-inheritance)
- [Namespaces](#namespaces)
- [Import](#import)
- [Operator overloading](#operator-overloading)
- [Statements](#statements)
	- [Try-catch-finally](#try-catch-finally)
	- [Switch](#switch)
- [API](#api)
- [Testing](#testing)

## Basic usage
Import `class.lua` in project or you can install it via [LuaRocks](https://luarocks.org/):
```
luarocks install lua-class
```
and use it like this:
```lua
class "A" {

	-- Property
	a = 0;

	-- Constructor
	constructor = function (self, a)
		self.a = a
	end;

	-- Method
	echo = function ()
		print "Echo from A class"
	end
}
```
This code creates table named "A" in global space. To instantiate a class, call the table:
```lua
local a = A(1, 2)
a:echo() -- Prints "Echo from A class"
```
Since all classes are registered in global namespace `_G` - that's why we can access classes directly as a function name rather than string as it's done in class definition. All classes are derived from `Object` class. This class contains two useful methods - `instanceof()` and `getClass()`. The first one accepts either string or class reference directly, the second returns class reference:
```lua
a:instanceof "A" -- True
a:instanceof(A) -- True
a:instanceof(Object) -- True
a:instanceof(B) -- False
a:instanceof(a:getClass()) -- True
```
If there is a try to create already existing class, an error will be raised:
```lua
class "A" {--[[ ... ]]}
class "A" {} --> Raises error
```
There is a restriction on class names. They only can contain alphanumeric characters and cannot start with a number:
```lua
class "0 numeric.dot" {} --> Raises error
```
## Inheritance
This package also supports inheritance:
```lua
class "B" extends "A" {

	echo = function ()
		print "Echo from B class"
	end
}
```
The method `echo` overrides the parent's one. If we omit the method, then it'll return "Echo from A class". There is also support for constructor and property overriding.

## Multiple inheritance
Classes can also derive from multiple base classes:
```lua
class 'A' {

	a = function ()
		return "a"
	end;
}

class 'B' {

	b = function ()
		return "b"
	end;
}

class 'C' extends (A, 'B') {

	c = function ()
		return "c"
	end;
}
C():a() -- returns "a"
```
And also can override methods. But when there is an attempt to derive from already derived class (deep chain), error is raised:
```lua
class 'A' {}
class 'B' extends 'A'
class 'C' extends (B, A) {} -- Error is here because class A is already derived in B
```

## Namespaces
Namespaces can also be created by using `namespace` keyword (actually - function):
```lua
namespace 'system' {
	-- Declare classes
	class 'Print' {
		m = function (self)
			return self
		end;
	}
	-- Declare functions
	out = function () return 'out' end;
}
-- Use namespace:
local var = system.Print()
print(system.out())
```
Unlike classes, you can reuse ("redeclare") them:
```lua
namespace 'system' {class 'A' {--[[ ... ]]}}
namespace 'system' {class 'B' {--[[ ... ]]}}
```
With namespaces you can create classes with the same name but different namespaces:
```lua
class 'A' {--[[ ... ]]}
namespace 'system' {class 'A' {--[[ ... ]]}} -- No errors
A ~= system.A
```
And sure, you can nest them:
```lua
namespace 'a.b.c' {class 'A' {--[[ ... ]]}}
```
But nesting declarations are not allowed, because it is harder to read and implement, use dot to create nesting:
```lua
namespace 'A' {
	namespace 'B' {} -- Raises error
}
```

## Import
It is pretty common to represent namespaces as filesystem directories and classes as separate source code files. So the `import` function relies on this convention. Example of usage:
```lua
import "system.io.File" -- Import single class located in system/io/File.lua
import "system.draw.*" -- Import all classes located in system/draw
```
Pretty reminds of java, does not it?
When you use import statement, it looks for files in `src` directory first. So if you import class like "system.File" and your current directory looks like this:
```
project
|- src
   |- system
      |- File.lua
```
then the library will include `./src/system/File.lua` file. But you can define your own path by using `Type.setBasePath(<path>)` method:
```lua
Type.setBasePath("project/scripts")
import "system.File" -- Includes ./project/scripts/system/File.lua file
import "ns.*" -- Includes all *.lua files located in ./project/scripts/ns directory
```
> NOTE: If you want to replace the default src folder to different one, you MUST call this method FIRST before using all import statements

## Operator overloading
Since lua supports operator overloading, you can define own implementations for operators as usual metamethod name (as lua provides) or by explicit definintion as corresponding index:
```lua
class 'A' {
	__add = function (self, value)
		return "addition "..value
	end;
	["-"] = function (self, value)
		return "substraction "..value
	end;
}
A() + 1 --> "addition 1"
A() - 1 --> "substraction 1"
```
The following operators can be overloaded:
|Metamethod|Index name|
|---|---|
|`__newindex`|`[]`|
|`__call`|`()`|
|`__tostring`||
|`__concat`|`..`|
|`__metatable`||
|`__mode`||
|`__gc`||
|`__len`|`#`|
|`__pairs`||
|`__ipairs`||
|`__add`|`+`|
|`__sub`|`-`|
|`__mul`|`*`|
|`__div`|`/`|
|`__pow`|`^`|
|`__mod`|`%`|
|`__idiv`|`//`|
|`__eq`|`==`|
|`__lt`|`<`|
|`__le`|`<=`|
|`__band`|`&`|
|`__bor`|`|`|
|`__bxor`|`~`|
|`__bnot`|`not`|
|`__shl`|`<<`|
|`__shr`|`>>`|

> NOTE: Index definitions have a precedence over metamethod ones, so if you extend a class that defines 
operators and then you override them, index definitions will be taken into account.

## Statements
The package also comes up with a few pretty familiar statements that do not exist in Lua but do in other languages.

### Switch
You can create switch-like statements and even expressions using function `switch`:
```lua
local var = "b"
switch (var) {
	a = 1; -- Use string key
	[1] = 2; -- Or numeric one
	[Object()] = 3; -- Or even class instances
	[{"b", "c"}] = function () -- Use multiple values. Mostly functions will be used as code block
		print "Switch!" -- Prints "Switch!"
	end;
	[default] = function () -- Use default fallback
		var = 12
	end
}
-- Or even use it as expression
local var = switch "b" {
	a = 1;
	b = 2;
	c = 3;
	d = function ()
		return 4; -- If you wish you can also use function blocks and return values from them
	end;
}
print(var) -- Prints "2"
```

### Try-catch-finally
The library provies pretty standard try-catch-finally feature:
```lua
try(function ()
	error "Error"
end):catch(function (msg)
	print(msg) -- Prints error message from previous function
end):finally(function ()
	print "Finally" -- Always executes
end)
```
You can pass a table containing single function instead of a function to make syntax more "curly":
```lua
try {
	function ()
		error "Error"
	end
} :catch {
	function (msg)
		print(msg)
	end
} :finally {
	function ()
		print "Finally"
	end
}
```
Since `try`, `catch` and `finally` are just functions, the last closure can be used as an expression to assign or pass values:
```lua
local msg = try {
	function ()
		error "Error"
	end
} :finally {
	function ()
		return "Finally"
	end
}
print(msg) --> "Finally"
```
Note that you cannot do this to `catch` because it always returns a table that contain method `finally`, so using it as an expression could confuse you:
```lua
local msg = try {} :catch {
	function ()
		return "Catch"
	end
}
print(msg) --> {finally = function () ... end}
```
You can also pass values to next methods:
```lua
try {
	function ()
		return "try"
	end
} :catch {
	function ()
		return "catch"
	end
} :finally {
	function (msg)
		print(msg) --> "try"
	end
}
```

## API
This library provides simple API to manage hierarchies or to retrieve extra info.
### Type API
|Method|Description|
|---|---|
|`Type.find(<type>)`|Finds and returns type by its name. Nil if type wasn't found|
|`Type.delete(<type>)`|Completely deletes type from hierarchy and global scope. If type has child types, then they are going to die too|
|`Type.setBasePath(<path>)`|Includes specified path in `package.path` so all import statements will look for this path first. Calling this method overrides previous base path. It's done this way because otherwise if we use asterisk imports and the overriding at the same time, then the asterisk import will look for files in all previously set base paths and it could cause "not found" error. "src" by default|

### Object class API
Object is the toppest class that all classes derive automatically. It has the next useful methods:
|Method|Description|
|---|---|
|`Object():getClass()`|Returns reference to a class that created current instance|
|`Object():instanceof(<class>)`|Returns true if the object is instance of supplied class. Class name can be either string or direct reference to a class|
|`Object():clone()`|Makes deep object clone. Deeply clones table references and object instance references|

### Class wrapper API
There is also special Class API. This package defines own class `Class` which can be used to retrieve info about classes. To use it, pass any class to the constructor like `local aInfo = Class(A)`. This class contains next methods:
|Method|Description|
|---|---|
|`Class(<type>):getMeta([<key>])`|Returns metainfo about class as a table. If `key` is specified then the specified field is returned. The returned table contains fields `name`, `parents`, `type`, `children`, `namespace`|
|`Class(<type>):getName()`|Returns full type name including namespaces delimited by dot|
|`Class(<type>):delete()`|Completely deletes type|

## Testing
To run tests, call from terminal `.\test.bat` for Windows and `./test.sh` for Linux
You can pass an argument to tests to define memory test iterations count like this - `test 1024`
