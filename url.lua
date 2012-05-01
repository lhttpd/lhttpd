require "oop"

local URL = class.URL()

local protoports = {
	http = 80,
	https = 443,
}

-- splits url to:
-- 1 proto - http or https
-- 2 user
-- 3 pass
-- 4 host
-- 5 port
-- 6 path - as /path
-- 7 qs - as table of k,v
function URL:new(path)
	if type(path) == "string" then
		path = { URL.parse_url(path) }
	end
	if (type(path[7])=="string") then
		path[7] = URL.parse_qs(path[4])
	end
	update(self, path)
end

-- RFC 1738 is tricky
function URL.parse_url(uri)
	local port, user, pass
	local proto, host, path, qs = uri:match "([^:]*)://([^/]*)([^?]*)%??(.*)"
	if not proto then-- lets try some heuristics
		return URL.parse_url('http://'+uri)
	end
	host, path, qs = uri:match("([^/]*)([^?]*)%??(.*)")
	if not host then error("incomplete url `%s`"%uri,2) end
	local a, b = host:match "([^@]*)@?(.*)"
	host, lp = b or a, b and a
	host, port = host:match "(.*):?([0-9]*)"
	port = port or protoports[proto]
	user, pass = (lp or ""):match "([^:]*):?(.*)"
	return proto, user, pass, host, port, path or "/", qs
end

function URL.parse_qs(qs)
	local res={}
	qs:gsub("([^&=]+)=([^&=]*)&?", function(k,v)
		setfield(res, URL.unescape(k), URL.unescape(v))
	end)
	return res
end

function URL.unescape(s)
	return ngx.unescape_uri(s)
end

function URL.escape(s)
	return ngx.escape_uri(s)
end

