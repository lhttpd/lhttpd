require "tab"
require "str"
require "json"

local tags = [[
a abbr acronym address area b base bdo big blockquote body br button caption
cite code col colgroup dd del dfn div dl  dt em fieldset form h1 h2 h3 h4 h5
h6 head html hr i img input ins kbd label legend li link map meta noscript
object ol optgroup option p param pre q samp script select small span strong
style sub sup table tbody td textarea tfoot th thead title tr tt ul var
]]

local ent2html = {
	["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;",
	["'"] = "&apos;", ["\""] = "&quot;",
}

local html2ent = transpose(ent2html)

function htmlescape(s)
	return s:gsub("[%s]" % keys(mustescape), mustescape)
end

function htmlunescape(s)
	error("TBD",2)
end

foreachi(tags:split(), function(_,tag)
	_G[tag:upper()] = function(sub)
		local res = {}
		local args = {}
		local attrs = {}
		if sub ~= nil then
			for i=1,#sub do
				local v=sub[i]
				if type(v) == "function" then
					v=v()
				end
				append(res, v)
				sub[i]=nil
			end
			for k,v in pairs(sub) do
				append(attrs, " "..k.."=\""..htmlescape(v).."\"")
			end
		end
		if (#res ~= 0) or sub then
			res = {"<",tag,attrs,">",htmlescape(res),"</",tag,">"}
		else
			res = {"<",tag,attrs,">"}
		end
		return res
	end
end)


-- register variables
function	register_vars(dst, tab, pfx)
	pfx = pfx or ""
	foreach(tab, function(k,v)
		k = "_"..k
		if not k:starts(pfx) or dst[k] then return end
		if not dst[k] then
			dst[k]=v
		end
	end)
end

function	register_get_vars(ctx,pfx)
	ctx.get = ngx.req.get_uri_args()
	return register_vars(ctx, ctx.get,pfx)
end

function	register_post_vars(ctx,pfx)
	ctx.post = ngx.req.get_post_args()
	return register_vars(ctx, ctx.post,pfx)
end

-- register standard stuff
function register(ctx,pfx)
	register_get_vars(ctx,pfx)
	register_post_vars(ctx,pfx)
	ctx.args = extend(extend({},ctx.get), ctx.post)
	ctx.header["X-Powered-By"] = "lhttpd.com/0.4"
end



