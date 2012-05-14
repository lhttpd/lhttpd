---------------------------------------------------------
-- functional programming tools
---------------------------------------------------------
local tinsert = table.insert

---------------------------------------------------------
-- compose two functions.
-- For instance, `printf` can be defined as `compose(io.write,string.format)`
-- `f1` a function
-- `f2` a function
function compose(f1,f2)
	return function(...)
		return f1(f2(...))
	end
end

---------------------------------------------------------
-- bind the value `v` to the first argument of a function
-- `f` a function of at least one argument
-- `v` a value
function bind(f,v)
	return function(...)
		return f(v,...)
	end
end

---------------------------------------------------------
-- bind the value `v` to the 2nd argument of a function
-- `f` a function of at least one argument
-- `v` a value
function bind2(f,v)
	return function(x,...)
		return f(x,v,...)
	end
end

---------------------------------------------------------
-- decorate a function value with a decorator
-- `funval` function to decorate
-- `dec` the decorator
function decorate(funval, dec)
	-- decorate only functions
	if type(funval) ~= "function" then return funval end
	return dec(funval)
end

---------------------------------------------------------
-- decorate a class method with a decorator
-- `tab` table containing the class
-- `name` method name
-- `fun` the decorator function
function decorate_method(tab,name,fun)
	rawset(tab, name, decorate(rawget(tab, name), fun))
end

---------------------------------------------------------
-- decorate a class value (i.e. meta.__index)
-- `index` the __index of a class
-- `fun` a decorator function to apply to each method
function decorate_class(index, fun)
	for k,v in pairs(index) do
		decorate_method(index, k, fun)
	end
end

---------------------------------------------------------
-- decorate the class of given object
-- `obj` an object, its class methods will be decorated
-- `fun` decorator function
function decorate_metaclass(obj, fun)
	local index = getmetatable(obj).__index
	return decorate_class(index, fun)
end


---------------------------------------------------------
-- applies a function to each value in a hash table
-- `tab` table of key/value pairs
-- `lambda` to be called: tab[k] = lambda(k,v)?
-- `gen?` is the table generator used, defaults to `pairs`
-- `dst?` is the destination table (defaults to `tab`)
-- if `lambda` returns nil, the result is not stored
function	map(tab, lambda, dst, gen)
	local res = dst or {}
	for k, v in (gen or pairs)(tab) do
		k,v = lambda(k, v)
		if k ~= nil then
			res[k] = v
		end
	end
	return res
end

---------------------------------------------------------
-- this is equal to `map` (just return `nil`)
filter=map

---------------------------------------------------------
-- similiar to `map`, but for arrays:
-- `tab` array of values (hash part is ignored)
-- `lambda` to be called: dst:append(lambda(v)?)
-- `gen?` is the table generator used, defaults to `pairs`
-- `dst?` is the destination table (defaults to empty)
-- `start?` starting index
-- `stop?` stop index
-- `step?` increment (can be negative to go backwards)
function	imap(tab, lambda, start, stop, step)
	local res = {}
	local n = 1
	for i=start or 1,stop or #tab,step or 1 do
		local v=tab[i]
		local r = lambda(v)
		if r ~= nil then
			res[n]=r
			n=n+1
		end
	end
	return res
end

function	fmap(fun, ...)
	local res={}
	local list = {...}
	for i=1,#list do
		local v =fun(list[i])
		append(res, v)
	end
	return unpack(res)
end

---------------------------------------------------------
-- this is equal to `imap` (just return `nil`)
ifilter=imap


---------------------------------------------------------
-- `val` = `lambda`(`val`,`k`,`v`) for `k`/`v` in tab
-- `tab` table to fold
-- `val` initial value
-- `lambda` function to call
-- `gen?` generator (defaults to `pairs`)
function	fold(tab, val, lambda, gen)
	for k, v in (gen or pairs)(tab) do
		val = lambda(val, k, v)
	end
	return val
end

---------------------------------------------------------
-- same as `fold` but over a list, with integer indices
-- `tab` array to fold
-- `val` initial value
-- `lambda` function to call
-- `start?` starting index
-- `stop?` stop index
-- `step?` increment (can be negative to go backwards)
function	foldl(tab, val, lambda, start, stop, step)
	for i=start or 1, stop or #tab, step do
		val = lambda(val, tab[i])
	end
	return val
end

---------------------------------------------------------
-- alias for `foldl` backwards (ie right-to-left)
-- `tab` array to fold
-- `val` initial value
-- `lambda` function to call
function	foldr(tab, val, lambda)
	return foldl(tab, val, lambda, #start, 1, -1)
end

local dflatten
function	dflatten(dst,tab)
	if type(tab)~='table' then
		return tinsert(dst,tab)
	end
	return foldl(tab, dst, dflatten)
end

---------------------------------------------------------
-- recursively flatten arbitrarily-deep table
-- `tab` a table to flatten
-- circular references are not accounted for!
function	flatten(tab)
	local res = {}
	return dflatten(res, tab)
end

