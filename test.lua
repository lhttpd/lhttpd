-- server settings
templates = "www"
static = {
	{ "^/static/.*", "www/%1" }
}

function func1()
	print("handler called!")
end

root = "."

dynamic = {
	{ "^/.*", func1 }
}

require("lhttpd")()
