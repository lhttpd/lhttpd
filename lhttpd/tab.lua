------------------------------------------------------------
-- table tools, pythonic Set() and List() and ordered Dict()
------------------------------------------------------------
local class = require "lhttpd.oop"
local tinsert = table.insert
local tsort = table.sort
local tremove = table.remove
local tforeach = table.foreach
local tforeachi = table.foreachi
local tconcat = table.concat

-- export table stuff
foreach = tforeach
foreachi = tforeachi

---------------------------------------------------------
-- append value to an array
function append(t,val)
	tinsert(t,val)
	return t
end

---------------------------------------------------------
-- update key -> multiple value field
-- `t` table to update
-- `k` key to use
-- `v` value to add
-- if `k` is not set, perform t[k] = v
-- otherwise t[k] = { unpack(t[k]), v }
function setfield(t,k,v)
	local ov=t[k]
	if ov==nil then
		t[k]=v
		return t
	end
	local ot=type(ov)
	if ov=="table" then
		return append(t[k],v)
	end
	t[k]={t[k],v}
	return t
end

function getfield(tv)
	if type(tv)=="table" and tv[1] then
		return tv[1]
	end
	return tv
end

---------------------------------------------------------
-- insert value into a table
-- `t` table to insert into
-- `pos?` position
-- `val` value to insert
insert = function(t,pos,val)
	if val==nil then
		return append(t,pos)
	end
	tinsert(t,pos,val)
	return t
end

---------------------------------------------------------
-- alias for `append`
push = append

---------------------------------------------------------
-- alias for `table.remove`
pop = tremove

---------------------------------------------------------
-- alias for `table.concat`
concat = tconcat

---------------------------------------------------------
-- alias for `table.sort`
sort = function(t,comp)
	tsort(t,comp)
	return t
end

---------------------------------------------------------
-- update key/values in one table from another
-- `dst` destination table
-- `src` source table
-- if destination key already exists, it is overrwriten!
function update(dst,src)
	for k,v in pairs(src) do
		dst[k] = v
	end
	return dst
end

---------------------------------------------------------
-- set default key to value
-- `tab` table
-- `key` key to check
-- `val` value to set if its not defined
function setdefault(tab,key,val)
	local v=tab[key]
	return v or (rawset(tab, key, val) and val)
end

---------------------------------------------------------
-- set default key/values into one table from another
-- `dst` destination table
-- `src` source table
function setdefaults(dst,src)
	for k,v in pairs(src) do
		if not dst[k] then
			dst[k] = v
		end
	end
	return dst
end



---------------------------------------------------------
-- import key/values into one table from another
-- `dst` destination table
-- `src` source table
-- if destination key already exists, an error is raised!
function import(dst,src)
	for k,v in pairs(src) do
		if dst[k] then
			error("key `"..tostring(k).."` already exists!")
		end
		dst[k] = v
	end
	return dst
end

---------------------------------------------------------
-- append values from one array at the end of another
-- `dst` destination array
-- `src` source array
function extend(dst,src)
	for i=1,#src do
		append(dst,v)
	end
	return dst
end

---------------------------------------------------------
-- return table keys as an array
-- `tab` a table, it's keys are returned
function keys(tab)
	local res = {}
	for k,_ in pairs(tab) do
		tinsert(res, k)
	end
	return res
end

---------------------------------------------------------
-- return table values as an array
-- `tab` a table, it's values are returned
function values(tab)
	local res = {}
	for _,v in pairs(tab) do
		tinsert(res, v)
	end
	return res
end

---------------------------------------------------------
-- find given value, and return its key
-- `tab` table to search
-- `val` value to look for
-- `pred?` optional predicate pred(t,k,v,val)
function find(tab, val, pred)
	if not pred then
		for k,v in pairs(tab) do if v==val then return k end end
	else
		for k,v in pairs(tab) do if pred(t,k,v,val) then return k end end
	end
end

---------------------------------------------------------
-- find a value in array, and return its index
-- `tab` table to search
-- `val` value to look for
-- `pred?` optional predicate pred(t,idx,v,val)
function ifind(tab, val, pred)
	if not pred then
		for i=1,#v do if tab[i]==val then return i end end
	else
		for i=1,#v do if pred(t,i,v,val) then return i end end
	end
end

local function fixup(t,k)
	if k < 0 then 
		local tl = #t
		k = (k % tl) + tl
	end
	return k
end


---------------------------------------------------------
-- return a slice of an array
-- Like string.sub, bot i1 and i2 can be negative
-- `t` the array
-- `i1` the start index
-- `i2` the end index, default #t
function sub(t,i1,i2)
	if i2==nil then i2=#t end
	if i1==nil then i1=1 end
	i1=fixup(t,i1)
	i2=fixup(t,i2)
	local res,k={},1
	for i=i1,i2,i2>i1 and 1 or -1 do
		res[k] = t[i]
		k=k+1
	end
	return res
end

local function quote (v)
    if type(v) == 'string' then
        return ('%q'):format(v)
    else
        return tostring(v)
    end
end

local tbuff
function tbuff(t,buff,k)
    local used
    local function append (v)
        buff[k] = v
        k = k + 1
    end
    local function table_out (value)
        if not buff.tables[value] then
            buff.tables[value] = true
            k = tbuff(value,buff,k)
        else
            append("<cycle>")
        end
    end
    append "{"
    if #t > 0 then -- dump out the array part
        used = {}
        for i,value in ipairs(t) do
            if type(value) == 'table' then
                table_out(value)
            else
                append(quote(value))
            end
            append ","
            used[i] = true
        end
    end
    for key,value in pairs(t) do
        if not used or not used[key] then
            -- non-identifiers need []
            if buff.stupid or type(key)~='string' or not key:match '^[%a_][%w_]*$' then
                if type(key)=='table' then
                    key = ml.tstring(key)
                else
                    key = quote(key)
                end
                key = "["..key.."]"
            end
            append(key..'=')
            if type(value) ~= 'table' then
                append(quote(value))
            else
                table_out(value)
            end
            append ","
        end
    end
    if buff[k-1] == "," then k = k - 1 end
    append "}"
    return k
end


---------------------------------------------------------
-- return a string representation of a Lua value.
-- @param t the table
-- @param stupid put out all keys as [..]
-- @return a string
function tstring(t,stupid)
    if type(t) == 'table' and not (getmetatable(t) and getmetatable(t).__tostring) then
        local buff = {tables={[t]=true},stupid=stupid}
        pcall(tbuff,t,buff,1)
        return tconcat(buff)
    else
        return quote(t)
    end
end



---------------------------------------------------------
-- return table with keys and values swapped
-- `tab` a table
-- returns new table
function transpose(tab)
	local res = {}
	for k,v in pairs(tab) do
		res[v] = k
	end
	return res
end

class.List {
	concat = tconcat, 
	insert = insert,
	append = append,
	remove = tremove,
	push = push,
	pop = pop,
	find = find,
	extend = extend,
	sort = sort,
}

update(List, imap({
	ifilter, sub, indexby
}, bind(compose, List)))

function List:_init(t,...)
	if t then
		local meta=getmetatable(t)
		if meta==List then return t end
		if type(t) == "table" then
			return t
		end
		return setmetatable({t,...}, List.__classmeta)
	end
end

function List:clone() return self:sub(1) end
function List:sorted(f) return self:sub(1):sort(f) end

-- negative indexing works forst lists
List.__classmeta = {
	__index = function(t,k)
		if type(k)~="number" then return rawget(List, k) end
		return rawget(t, fixup(t,k))
	end,
	__newindex = function(t,k,v)
		if type(k)~="number" then rawset(t, k) end
		rawset(t, fixup(t,k))
	end
}

