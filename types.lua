local o = require("object")


local LookupTree
function getEmptyTree(self, key, private)
	-- use "value" a special value that will *not* be affected by this
	-- function
	if key == "value" then
		return nil
	else
	-- put a new tree into this blank index
	local tree = LookupTree()
	self[key] = tree
	return tree
	end
end
LookupTree = o.class(nil, getEmptyTree)
-- empty constructor avoids infinite loops when the getter makes a new tree,
-- attempting to find "__init". if there is no "__init" in the class then the
-- getter will attempt to find "__init" in the object, causing a recusive
-- loop.
function LookupTree:__init()
end
function LookupTree:get(list, n)
	n = n or 1
	if n > #list then
		return self.value
	else
		return self[ list[n] ]:get(list, n+1)
	end
end
function LookupTree:set(list, value, n)
	n = n or 1
	if n > #list then
		self.value = value
	else
		self[list[n]]:set(list, value, n+1 )
	end
end

local types = {}
types.LookupTree = LookupTree
return types
