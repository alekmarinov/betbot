-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2009,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      team.lua                                           --
-- Description:   Team class definition                              --
--                                                                   --
-----------------------------------------------------------------------

local om       = require "lrun.model.om" 
local sqlds    = require "lrun.model.datasrc.sql"
local sqlgens  = require "lrun.model.schema.sqlgen.all"
local log      = require "betbot.log" 
local Location = require "betbot.model.location"
local Provider = require "betbot.model.provider" 

module ("betbot.model.team", package.seeall)

OM =
{
	{"id", "optional", "number"},
	{"title", "required", "string"},
	{"location", "required", Location.OM},
	{"provider", "required", Provider.OM},
}

DBMAP =
{
	{"location", "locationID", function(t) return t.id end},
	{"provider", "providerID", function(t) return t.id end},
}

__index = _M

-- creates new team object
function new(rom)
	om.validate(OM, rom)
	return setmetatable(rom, _M)
end

-- compares two team objects
function __eq(t1, t2)
	return om.compare(OM, t1, t2, {"id"}) == 0
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
function load(dbc, id, loc)
	assert(id, "param id expected")

	local key = id
	if loc then
		if type(loc) == "table" then
			key = loc.title.."-"..id
		end
	end

	if not _M[key] then
		local sql
		if type(id) == "string" then
			assert(loc, "param loc expected")

			if type(loc) ~= "table" then
				loc = Location.load(dbc, loc)
			end
			assert(type(loc.id) == "number", "location ID number expected, got "..type(loc.id))
			sql = "SELECT id, title, locationID, providerID FROM Team WHERE title = "..Q(id).." AND locationID = "..loc.id
		else
			assert(type(id) == "number", "expected number, got "..type(id))
			sql = "SELECT id, title, locationID, providerID FROM Team WHERE id = "..id
		end
		local row = assert(sqlds.new(dbc, sql)):once()
		if row then
			row.id = tonumber(row.id)
			row.location = Location.load(dbc, tonumber(row.locationID))
			row.provider = Provider.load(dbc, tonumber(row.providerID))
			key = loc.title.."-"..row.id
			_M[key] = new(row)
			_M[loc.title.."-"..row.title] = _M[key]
		end
	end
	return _M[key]
end

-- update this object to DB
function save(self, dbc)
	local team = load(dbc, self.title, self.location)
	if not team then
		local sqlgen = sqlgens[dbc.driver]:new()
		team = om.new(OM, self)
		om.map(DBMAP, team)
		sqlgen:insertobject("Team", team)
		log.sql(tostring(sqlgen))
		assert(sqlgen:execute(dbc))
		local row = sqlds.new(dbc, "SELECT MAX(id) AS 'id' FROM Team"):once()
		self.id = tonumber(row.id)
		_M[self.id] = self
		_M[self.title] = self
	else
		self.id = team.id
	end
	return self
end

return _M
