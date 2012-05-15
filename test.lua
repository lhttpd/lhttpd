#!./lua
-- server settings
templates = "www"
static = {
	{ "^/static/.*", "www/%1" }
}

function front_page()
	write(HTML {
		HEAD {
			TITLE { "test page" }
		},
		BODY {
			H1 { "this is a test page!" }
		}
	})
end

root = "."

dynamic = {
	{ "^/$", front_page }
}

require("lhttpd")()
