local Object = {}
-- generic getter/setters
-- all blank indexes are looked up with a "get"..key function in self
function Object.autoGet(self, key, private)
	local class = self.objType
	local str = "get" .. key
	if rawget(self, str) then
		return self[str](private)
	end
	if class[str] then
		return class[str](private)
	end
end
-- all new indexes are made in a private table
function Object.privateSet(self, key, value, private)
	private[key] = value
end

--function Object.class( parent )
function Object.class( parent ,getter, setter)
	local class = {}
	local objMt = class
	local classMt = {}
	if parent then
		-- copy for some performance increase
		-- also allows METAMETHODS to be inherited!
		for k,v in pairs(parent) do
			print("Copy:", k, v)
			objMt[k] = v
		end
		class.super = parent
		classMt.__index = parent
	else
		class.super = nil
		classMt.__index = nil
	end
	class.objType = class -- TODO remove this line. (check to make sure nothing uses it)

	local private = {} -- private table that will be closed over in the __newindex and __index function, and not available elsewhere
	if setter then
		objMt.__newindex = function(self, key, value)
			setter(self, key, value, private)
		end
	end

	if getter then
		objMt.__index = function(self, key)
			local val = class[key]
			if not val then
				val = getter( self, key, private )
			end
			return val
		end
	else
		objMt.__index = class
	end
	objMt.class = class


	function classMt.__call(class,...)
		local self = {}
		setmetatable(self, objMt)
		if self.__init then self.__init(self,...) end
		return self
	end
	return setmetatable(class,classMt), objMt
end

--function Object.clone(Object) return Connector a copy of this connector
function Object.clone(self)
	local clone = {}
	for k,v in pairs(self) do
		clone[k] = v
	end
	return setmetatable(clone, getmetatable(self))
end

return Object
