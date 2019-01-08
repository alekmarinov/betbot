-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2009,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      location.lua                                       --
-- Description:   Location class definition                          --
--                                                                   --
-----------------------------------------------------------------------

local om       = require "lrun.model.om"
local sqlds    = require "lrun.model.datasrc.sql"
local sqlgens  = require "lrun.model.schema.sqlgen.all"
local log      = require "betbot.log" 
local Provider = require "betbot.model.provider" 

module ("betbot.model.location", package.seeall)

OM =
{
	{"id", "optional", "number"},
	{"title", "required", "string"},
	{"provider", "required", Provider.OM},
}

DBMAP =
{
	{"provider", "providerID", function(t) return t.id end},
}

__index = _M

-- creates new location object
function new(rom)
	om.validate(OM, rom)
	return setmetatable(rom, _M)
end

-- compares two location objects
function __eq(l1, l2)
	return om.compare(OM, l1, l2, {"id"}) == 0
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

-- load object by id or title
function load(dbc, id)
	assert(id, "location id expected")
	if not _M[id] then
		local sql
		if type(id) == "string" then
			sql = "SELECT id, title, providerID FROM Location WHERE title = "..Q(id)
		else
			assert(type(id) == "number", "id number expected, got "..type(id))
			sql = "SELECT id, title, providerID FROM Location WHERE id = "..id
		end
		local row = sqlds.new(dbc, sql):once()
		if row then
			row.id = tonumber(row.id)
			row.provider = Provider.load(dbc, tonumber(row.providerID))
			_M[row.id] = new(row)
			_M[row.title] = _M[row.id]
		end
	end
	return _M[id]
end

-- update this object to DB
function save(self, dbc)
	local loc = load(dbc, self.title)
	if not loc then
		local sqlgen = sqlgens[dbc.driver]:new()
		local location = om.new(OM, self)
		om.map(DBMAP, location)
		sqlgen:insertobject("Location", location)
		log.sql(tostring(sqlgen))
		assert(sqlgen:execute(dbc))
		local row = sqlds.new(dbc, "SELECT MAX(id) AS 'id' FROM Location"):once()
		self.id = tonumber(row.id)
		_M[self.id] = self
		_M[self.title] = self
	else
		self.id = loc.id
	end
	return self
end

return _M
