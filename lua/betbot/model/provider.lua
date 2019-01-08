-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2009,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      provider.lua                                       --
-- Description:   Provider class definition                          --
--                                                                   --
-----------------------------------------------------------------------

local om      = require "lrun.model.om" 
local sqlds   = require "lrun.model.datasrc.sql"
local sqlgens = require "lrun.model.schema.sqlgen.all"
local log     = require "betbot.log" 

module ("betbot.model.provider", package.seeall)

OM =
{
	{"id", "optional", "number"},
	{"title", "required", "string"},
}

__index = _M

-- creates new provider object
function new(bom)
	om.validate(OM, bom)
	return setmetatable(bom, _M)
end

-- compares two team objects
function __eq(b1, b2)
	return om.compare(OM, b1, b2, {"id"}) == 0
end

-- convert object to string
function __tostring(self)
	return self.title
end

--- quote string
function Q(arg)
	assert(type(arg) == "string")

	return "'" .. arg:gsub("'", "''") .. "'"
end

-- load provider from DB
function load(dbc, id)
	if not _M[id] then
		local sql
		if type(id) == "string" then
			sql = "SELECT id, title FROM Provider WHERE title = "..Q(id)
		else
			assert(type(id) == "number", "id number expected, got "..type(id))
			sql = "SELECT id, title FROM Provider WHERE id = "..id
		end

		local row = sqlds.new(dbc, sql):once()
		if row then
			row.id = tonumber(row.id)
			_M[row.id] = new(row)
			_M[row.title] = _M[row.id]
		end
	end
	return _M[id]
end

-- update this object to DB
function save(self, dbc)
	local provider = load(dbc, self.title)
	if not provider then
		sqlgen:insertobject("Provider", self)
		log.sql(tostring(sqlgen))
		assert(sqlgen:execute(dbc))
		local row = sqlds.new(dbc, "SELECT MAX(id) as 'id' FROM Provider"):once()
		self.id = tonumber(row.id)
		_M[self.title] = self
		_M[self.id] = self
	else
		self.id = provider.id
	end
	return self
end

return _M
