-- TODO, connection pooling

require "oop"
local sql = require "luasql.sqlite3"

class.DB {
}

function DB:new(file)
	self.file = file
	self.db = sql:connect(file)
end

return DB
