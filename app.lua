local orig = getfenv(0)
setfenv(0, _G)

require "lfs"
require "tab"
require "fun"
require "oop"
require "sql"
require "log"
require "str"
require "web"

setfenv(0, orig)

local appcache = {}

local function needreload(appname)
	local appinfo=appcache[appname]
	if not appinfo then return true end
	for name,mtime in pairs(appinfo.files) do
		if lfs.attributes(appinfo.files[name], "modification") ~= mtime then
			return true
		end
	end
end

local global = _G

local function loadapp(appname, appdir)
	local info = {
		files = {},
		fns = {},
	}
	local files = info.files
	local fns = info.fns

	-- load all app components.
	for n in lfs.dir(appdir) do
		if n:ends(".lua") then
			local fname = appdir + '/' + n
			append(fns, loadfile(fname))
			files[fname] = lfs.attributes(fname, "modification")
		end
	end
	appcache[appname] = info
end

local strict = function(t,k,v)
	error("use rawset(_G|current, `%s`, ...) to create new globals at runtime" % k, 2)
end

return function()
	local appname = ngx.var.app
	local appdir = ngx.var.appdir
	xpcall(function()
		if needreload(appname) then
			loadapp(appname, appdir)
		end
		assert(appcache[appname])
		local info = appcache[appname]
		local current = getfenv(0)
		current.current = current
		update(current, current.ngx)
		local fns = info.fns
		for i=1,#fns do
			setfenv(fns[i], current)()
		end
		getmetatable(current).__newindex = strict
		current.main()
	end, function(err)
		ngx.header.content_type = 'text/plain'
		ngx.print(debug.traceback(err))
	end)
end

