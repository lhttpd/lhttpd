require "lhttpd.oop"
require "lhttpd.fun"
require "lhttpd.tab"
require "lhttpd.str"
url = require "socket.url"

local run_server

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

local function find_match(list, path)
	for i=1,#list do
		local matches = {path:match(list[i][1])}
		if #matches > 0 then
			return list[i][1], list[i][2], matches
		end
	end
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

local function send_buffer(data)
	client:send(data)
end

local code2str = {
	[200] = "OK",
	[404] = "Not found",
	[403] = "Forbidden",
	[501] = "Internal server error",
}

local function send_response(code,data)
	local codestr = code2str[tonumber(code)] or "Unknown code"
	local len = header["Content-Length"] or #data
	io.stdout:write("%s - - [%s] \"%s\" %s %d \"%s\" \"%s\"\n" % { remote_addr, os.date(), request_line, tostring(code), len, headers.referer or "-", headers.user_agent or "-" })
	send_buffer("HTTP/1.0 %d %s\r\n%s" % {code,codestr,data})
end

local function serialize_headers(htab)
	return concat(fold(htab, {}, function(t,k,v)
		for i=1,#v do
			append(t, "%s: %s" % {k,tostring(v[i])})
		end
		return t
	end))
end

local function process_request()
	local path = assert(uri)
	-- serve static content
	local match, val, args = find_match(server.static, path)
	if match then
		local realpath = server.root +"/"+ path:gsub(match, val)
		local ext = realpath:match(".*%.([^.]*)$")
		local ctype = mime[ext] or "text/plain"
		local f = assert(io.open(realpath, "rb"), "404 File not found")
		local data = f:read("*a")
		if data then
			send_response(200, "Content-Type: "+ctype+"\r\n\r\n"+data)
		else
			error("403 Access denied")
		end
		f:close()
		client.socket:close()
		return
	end
	-- serve dynamic content
	local match, val, args = find_match(server.dynamic, path)
	if match then
		val(args)
		local buf = concat(flatten(buffer))
		header["Content-Length"] = #buf
		send_response(200, serialize_headers(headers)+"\r\n")
		send_buffer(buf)
		client.socket:close()
		return
	end
	error("501 No handler found")
end


function run_server(server)
	-- our own (only for development) httpd
	copas.addserver(assert(socket.bind(server.addr,server.port)), function(c)
		c = copas.wrap(c)
		local request_line = c:receive("*l")
		local method, uri, http = request_line:match("([^ \t]*) ([^ \t]*) ([^ \t]*)")
		local raw_headers,headers = {},{}
		while true do
			local s = c:receive("*l"):strip()
			if s=="" then break end
			local hdrname, hdrval = s:match("([^:]*):[ \t]*(.*)")
			setfield(raw_headers, hdrname, hdrval)
			setfield(headers, hdrname:lower():gsub("%-","_"), hdrval)
		end
		local urlinfo = url.parse(uri)
		local get = parse_params(urlinfo.query or "")
		local clihost, cliport = c.socket:getpeername()
		local path = urlinfo.path:gsub("/%.%.","") -- XXX traverse properly?
		local context = {
			request_line = request_line,
			buffer = {},
			headers = headers,
			header = {},
			server = server,
			client = c,
			host = getfield(headers.host) or "*",
			remote_addr = clihost,
			remote_port = cliport,
			request_method = method,
			request_uri = uri,
			headers = headers,
			get = get,
			parsed_url = urlinfo,
			uri = path,
		}
		setmetatable(_G, {__index=context, __newindex=context})
		coxpcall(process_request, function(errdata)
			local code, msg = errdata:match("[^ ]* ([0-9]*) ([^\n]*)")
			if not code then
				io.stderr:write(errdata + "\n")
				code = 501
				msg = "Internal server error"
			end
			send_response(tonumber(code), "Content-Type: text/html\r\n\r\n<h1>%s</h1>" % msg)
			c.socket:close()
		end)
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
		static = { "^/static/.*", "www/static/%1" },
	})
	assert(params.root, "`root` must be specified!")
	assert(params.dynamic, "`dynamic` handlers must be specified!")
	run_server(params)
end


