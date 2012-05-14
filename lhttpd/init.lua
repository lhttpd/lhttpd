require "lhttpd.oop"
require "lhttpd.fun"
require "lhttpd.tab"
require "lhttpd.str"
url = require "socket.url"

---------------------------------------------------------
-- every blocking coroutine switch must be wrapped
---------------------------------------------------------
local function g_switch(fun)
	return function(...)
		local sav = getmetatable(_G)
		local ret={fun(...)}
		setmetatable(_G, sav)
		return unpack(ret)
	end
end

local function parse_params(s, params)
	params = params or {}
	for p in s:gmatch "([^&]+)" do
		local k,v = fmap(url.unescape, p:match "(.*)=(.*)")
		if k and v then
			params[k] = v
		end
	end
	return params
end

---------------------------------------------------------
-- standalone server part
---------------------------------------------------------
if not ngx then
	require "copas"
	-- load mime types for /static
	local mime={}
	for l in io.open("/etc/mime.types","r"):lines() do
		local p=l:split()
		if p[1] and p[1][1] ~= "#" then
			for i=2,#p do
				mime[p[i]]=p[1]
			end
		end
	end
	-- setup copas environment switching
	decorate_metaclass(copas.wrap("tcp"), g_switch)
	decorate_metaclass(copas.wrap("udp"), g_switch)

function run_server(server)
	-- our own (tiny) httpd
	copas.addserver(assert(socket.bind(server.addr,server.port)), function(c)
		c = copas.wrap(c)
		s = c:receive("*l")
		local method, uri, http = s:match("([^ \t]*) ([^ \t]*) ([^ \t]*)")
		local raw_headers,headers = {},{}
		while true do
			s = c:receive("*l"):strip()
			if s=="" then break end
			local hdrname, hdrval = s:match("([^:]*):[ \t]*(.*)")
			setfield(raw_headers, hdrname, hdrval)
			setfield(headers, hdrname:lower():gsub("%-","_"), hdrval)
		end
		local urlinfo = url.parse(uri)
		local get = parse_params(urlinfo.query)
		local clihost, cliport = c.socket:getpeername()
		local context = {
			host = getfield(headers.host) or "*",
			remote_addr = clihost,
			remote_port = cliport,
			request_method = method,
			request_uri = uri,
			headers = headers,
			get = get,
			parsed_url = urlinfo,
			uri = urlinfo.path,
		}
		print(context)
		c:send("HTTP/1.0 200 OK\r\nContent-Type: text/plain\r\n\r\nblah")
		c.socket:close()
	end)
	copas.loop()
end


---------------------------------------------------------
-- this is the nginx-only part
---------------------------------------------------------
else
	-- perform nginx environment switching
	decorate_class(ngx._reqsock_meta.__index, g_switch)
	decorate_class(ngx._tcp_meta.__index, g_switch)
	decorate_metaclass(ngx.req, g_switch)
	decorate_method(ngx, "exec", g_switch)
	decorate_method(ngx.location, "capture", g_switch)
	decorate_method(ngx.location, "capture_multi", g_switch)
function run_server(params)
end
end


---------------------------------------------------------
-- main invocation
---------------------------------------------------------
return function(params)
	params = params or setmetatable({}, {__index=_G})
	-- initialize default values
	setdefaults(params, {
		port = 8088,
		addr = "*",
		templates = "www",
		static = { "^/static/.*", "www/static/$1" },
	})
	assert(params.root, "`root` must be specified!")
	assert(params.dynamic, "`dynamic` handlers must be specified!")
	run_server(params)
end


