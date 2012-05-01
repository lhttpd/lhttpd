-----------------------------------------------
-- we're scheming, HARD WAY
-----------------------------------------------

local tinsert = table.insert

-- map() applies `lambda` to each value in `tab`
-- table with same keys, but transformed values is returned.
-- if lambda returns nil, the result will not be stored in table (thus behaving like filter)
-- dst - is the destination table, can be same as the source
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
filter=map


-- imap()/ifilter() is almost the same as map(), but:
-- * key indices are sequential integers only, no generator
-- * you can define `start`, `stop` and `step` for indices
-- * `lambda` returning nil skips given indice in result, behaving as filter()
function	imap(tab, lambda, start, stop, step)
	local res = {}
	local n = 1
	for i=start or 1,stop or #tab,step or 1 do
		local r = lambda(v)
		if r ~= nil then
			res[n]=r
			n=n+1
		end
	end
	return res
end
ifilter=imap

-- fold() "collects" values from a table. order is not certain
function	fold(tab, val, lambda, gen)
	for k, v in (gen or pairs)(tab) do
		val = lambda(val, k, v)
	end
	return val
end

-- ifold() "collects" values from a list
function	foldl(tab, val, lambda, start, stop, step)
	for i=start or 1, stop or #tab, step do
		val = lambda(val, tab[i])
	end
	return val
end

-- fold right.
function	foldr(tab, val, lambda)
	return fold(tab, val, lambda, #start, 1, -1)
end


function	dflatten(dst,tab)
	if type(tab)~='table' then
		return tinsert(dst,tab)
	end
	return foldl(tab, dst, dflatten)
end

function	flatten(tab)
	local res = {}
	return dflatten(res, tab)
end
