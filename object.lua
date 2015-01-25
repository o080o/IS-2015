local Object = {}
--function Object.class( parent )
function Object.class( parent )
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
	objMt.__index = class


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

function Object.typeOf(obj)
	return getmetatable(obj).__index
end

return Object
