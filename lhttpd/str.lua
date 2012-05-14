---------------------------------------------------------
-- string tools
---------------------------------------------------------
require "lhttpd.tab"

local string = require "string"
local mt = getmetatable("")

function mt:__index(idx)
	return rawget(string,idx) or (type(idx)=="number" and string.sub(self,idx,idx)) or error("unknown string method `%s`" % idx, 2)
end

function mt:__mod(args)
	if type(args)=='table' then
		return string.format(self, unpack(args))
	else
		return string.format(self, args)
	end
end
mt.__mul = string.rep
mt.__add = function(a,b)
	return a .. b
end

---------------------------------------------------------
-- return true if string starts with `pfx`
-- `pfx` prefix to check
function string:starts(pfx)
	pfx=pfx or ""
	return self:sub(1,#pfx) == pfx
end

---------------------------------------------------------
-- return true if `string` ends with `pfx`
-- `pfx` postfix to check
function string:ends(pfx)
	pfx=pfx or ""
	return self:sub(-#pfx) == pfx
end

local find,sub,append = string.find, string.sub, table.insert
---------------------------------------------------------
-- split a string into a array of strings
-- `re?` a Lua string pattern; defaults to '%s+'
-- `n?` maximum number of splits
function string:split(re,n)
	local i1,ls = 1,{}
	if not re then re = '%s+' end
	if re == '' then return {s} end
	while true do
		local i2,i3 = find(self,re,i1)
		if not i2 then
			local last = sub(self,i1)
			if last ~= '' then append(ls,last) end
			if #ls == 1 and ls[1] == '' then
				return List{}
			else
				return List(ls)
			end
		end
		append(ls,sub(self,i1,i2-1))
	        if n and #ls == n then
			ls[#ls] = sub(self,i1)
			return List(ls)
		end
		i1 = i3+1
	end
end

---------------------------------------------------------
-- strip trailing whitespace
function string:strip()
	return self:match "^%s*(.-)%s*$"
end

---------------------------------------------------------
-- alias for `table.insert`(`tab`,givenstring)
-- `tab` table to append to
function string:appendto(tab)
	append(tab, self)
	return self
end

local o_print = print
function print(...)
	return o_print(unpack(imap({...}, tstring)))
end


