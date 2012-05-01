--------------------------------
-- make tables more pythonic
-- yeah, HERESY!
--------------------------------
--module("tab", package.seeall)

local tinsert = table.insert
local tsort = table.sort
local tremove = table.remove
local tforeach = table.foreach
local tforeachi = table.foreachi
local tconcat = table.concat

-- export table stuff
foreach = tforeach
foreachi = tforeachi
append = function(t,val)
	tinsert(t,val)
	return t
end
setfield = function(t,k,v)
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
insert = function(t,pos,val)
	if val==nil then
		return append(t,pos)
	end
	tinsert(t,pos,val)
	return t
end
push = append
pop = tremove
concat = tconcat
sort = function(t,comp)
	tsort(t,comp)
	return t
end

function update(dst,src)
	tforeach(src, function(k,v)
		dst[k] = v
	end)
	return dst
end

function extend(dst,src)
	tforeachi(src, function(v)
		append(dst,v)
	end)
	return dst
end

function keys(tab)
	local res = {}
	for k,_ in pairs(tab) do
		tinsert(res, k)
	end
	return res
end

function values(tab)
	local res = {}
	for _,v in pairs(tab) do
		tinsert(res, v)
	end
	return res
end

function transpose(tab)
	local res = {}
	for k,v in pairs(tab) do
		res[v] = k
	end
	return res
end

