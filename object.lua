local Object = {}
-- generic getter/setters
-- all blank indexes are looked up with a "get"..key function in self
function Object.autoGet(self, private, key)
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
function Object.privateSet(self, private, key, value)
	private[key] = value
end

--function Object.class( parent )
function Object.class( parent ,getter, setter)
	local class = {}
	local objMt = class
	local classMt = {}
	if parent then
		for k,v in pairs(parent) do
			print("Copy:", k, v)
			objMt[k] = v
		end
		class.super = parent
		classMt.__index = parent
	else
		classMt.__index = nil
	end
	class.objType = class

	local private = {} -- private table that will be closed over in the __newindex and __index function, and not available elsewhere
	if setter then
		objMt.__newindex = function(self, key, value)
			setter(self, private, key, value)
		end
	end

	if getter then
		objMt.__index = function(self, key)
			local val = class[key]
			if not val then
				val = getter( self, class, private, key )
			end
			return val
		end
	else
		objMt.__index = class
	end


	function classMt.__call(class,...)
		local self = {}
		setmetatable(self, objMt)
		self.super = class
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
