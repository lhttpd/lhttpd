------------------------------------------------------------
-- minimal oop
------------------------------------------------------------
local function addsupers(target,supers)
	for i=1,#supers do -- faster than ipairs
		local super = supers[i]
		for k,v in pairs(super) do
			if not target[k] then
				target[k] = v
			end
		end
		addsupers(target, super.__supers or {})
	end
end

local function instantiate(tk,...)
	local instance={}
	setmetatable(instance,tk.__classmeta)
	return instance:_init(...) or instance
end

local function fix_supers(tk,...)
	tk.__call = instantiate
	addsupers(tk,tk.__supers)
	return instantiate(tk,...)
end

class = setmetatable({}, {
	__index = function(klstab,kls)
		local GG = _ENV or getfenv(2)
		if rawget(GG, kls) then
			error("There is already '"..kls.."' in the global namespace!")
		end
		return function(...)
			local meta = {}
			local supers = {...}
			meta.__classmeta = {__index=meta} -- this is the actual metatable for instances
			meta.__class = kls -- class name, just for reference
			meta.__supers = supers -- list of superclasses
			meta.__index = supers[1]
			meta.__call = fix_supers
			rawset(GG, kls, setmetatable(meta, meta))
			return meta
		end
	end
})

return class
