require "tab"

local str = require "string"
local mt = getmetatable("")

function mt:__index(idx)
	return rawget(str,idx) or (type(idx)=="number" and str.sub(self,idx,idx)) or error("unknown string method `%s`" % idx, 2)
end

function mt:__mod(args)
	if type(args)=='table' then
		return str.format(self, unpack(args))
	else
		return str.format(self, args)
	end
end
mt.__mul = str.rep
mt.__add = function(a,b)
	return a .. b
end

function str:starts(pfx)
	pfx=pfx or ""
	return self:sub(1,#pfx) == pfx
end
function str:ends(pfx)
	pfx=pfx or ""
	return self:sub(-#pfx) == pfx
end

function str:split(pat)
	local t = {}
	local fpat = "(.-)" .. (pat or "[ \t\r\n]+")
	local last_end = 1
	local s, e, cap = self:find(fpat, 1)
	while s do
		if s ~= 1 or cap ~= "" then
			append(t, cap)
		end
		last_end = e+1
		s, e, cap = self:find(fpat, last_end)
	end
	if last_end <= #self then
		cap = self:sub(last_end)
		append(t, cap)
	end
	return t
end

function string:strip()
	return self:match "^%s*(.-)%s*$"
end

function string:appendto(tab)
	append(tab, self)
	return self
end

function pformat(t, name, indent)
	local res = {}
	local function out(...)
		concat{...}:appendto(res)
	end
	local tableList = {}
	local function table_r (t, name, indent, full)
		local spacing = '  '
		local serial=string.len(full) == 0 and name
				or type(name)~="number" and '["'..tostring(name)..'"]' or '['..name..']'
		out(indent,serial,' = ') 
		if type(t) == "table" then
			if tableList[t] ~= nil then out('{}; -- ',tableList[t],' (self reference)\n')
			else
				tableList[t]=full..serial
				if next(t) then -- Table not empty
					out('{\n')
					for key,value in pairs(t) do table_r(value,key,indent..spacing,full..serial) end 
					out(indent,'};\n')
				else out('{};\n') end
			end
		else out(type(t)~="number" and type(t)~="boolean" and '"'..tostring(t)..'"' or tostring(t),';\n') end
	end
	table_r(t,name or '__unnamed__',indent or '','')
	return concat(res)
end

function pprint(t)
	print(pformat(t))
end
pp = pprint


