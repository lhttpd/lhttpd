local function addsupers(target,supers)
	for i=1,#supers do -- faster than ipairs
		local super = supers[i]
		for k,v in pairs(super) do
			if not target[k] then
				target[k] = v
			end
		end
		addsupers(target, super.supers or {})
	end
end

local function instantiate(tk,...)
	local instance={}
	setmetatable(instance,tk.classmeta)
	return instance:new(...) or instance
end

local function fix_supers(tk,...)
	tk.__call = instantiate
	addsupers(tk,tk.supers)
	return instantiate(tk,...)
end

class = setmetatable({}, {
	__index = function(klstab,kls)
--		if rawget(_G, kls) then
--			error("There is already '"..kls.."' in the global namespace!")
--		end
		return function(...)
			local meta = {}
			local supers = {...}
			meta.classmeta = {__index=meta} -- this is the actual metatable for instances
			meta.class = kls -- class name, just for reference
			meta.supers = supers -- list of superclasses
			meta.__index = supers[1]
			meta.__call = fix_supers
			rawset(_G, kls, setmetatable(meta, meta))
			return meta
		end
	end
})

return class

