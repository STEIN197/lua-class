function string.split(self, separator)
	separator = separator or "%s"
	local parts = {}
	for part in self:gmatch("([^"..separator.."]*)") do
		table.insert(parts, part)
	end
	return parts
end

function table.slice(tbl, from, to)
	local sliced = {}
	from = from or 1
	to = to or #tbl
	if from < 0 then
		from = #tbl + from + 1
	end
	if to < 0 then
		to = #tbl + to + 1
	end
	for i = from, to do
		table.insert(sliced, tbl[i])
	end
	return sliced
end

Object = {

	instanceof = function (self, classname)
		local classref = ClassUtil.findClass(classname)
		local metatable = getmetatable(self)
		while metatable ~= nil and metatable.__index ~= classref do
			metatable = getmetatable(metatable.__index)
		end
		return metatable ~= nil
	end;

	getClass = function (self)
		local metatable = getmetatable(self)
		if metatable then
			return metatable.__index
		end
		return nil
	end
}

ClassUtil = {

	findClass = function (name)
		local classtype = type(name)
		if classtype == "string" then
			return _G[name]
		elseif classtype == "table" then
			return name
		else
			error("Classname \""..name.."\" is not a string nor a table")
		end
	end;

	Naming = {

		isValid = function (identifier, includedots)
			local pattern
			if includedots then
				pattern = "^[a-zA-Z][a-zA-Z0-9%.]*$"
			else
				pattern = "^[a-zA-Z][a-zA-Z0-9]*$"
			end
			return identifier:match(pattern)
		end;
	};
}

function class(name)
	if not ClassUtil.Naming.isValid(name) then
		error("Classname \""..name.."\" contains invalid characters")
	end
	if ClassUtil.findClass(name) then
		error("Cannot override existing class \""..name.."\"")
	end
	_G[name] = setmetatable({}, {__index = Object})
	return function (descriptor)
		_G[name] = setmetatable(descriptor, {
			__index = _G[name];
			__call = function (...)
				local object = setmetatable({}, {__index = descriptor})
				if descriptor.constructor then
					descriptor.constructor(object, table.unpack(table.slice({...}, 2)))
				end
				return object
			end
		})
	end
end
