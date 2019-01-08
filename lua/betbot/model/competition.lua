-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2009,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      competition.lua                                    --
-- Description:   Competition class definition                       --
--                                                                   --
-----------------------------------------------------------------------

local om        = require "lrun.model.om"
local sqlds     = require "lrun.model.datasrc.sql"
local sqlgens   = require "lrun.model.schema.sqlgen.all"
local log       = require "betbot.log" 
local Location  = require "betbot.model.location"
local Provider  = require "betbot.model.provider" 

module ("betbot.model.competition", package.seeall)

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

-- creates new competition object
function new(competition)
	om.validate(OM, competition)
	return setmetatable(competition, _M)
end

-- compares two competition objects
function __eq(c1, c2)
	return om.compare(OM, c1, c2, {"id"}) == 0
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
			sql = "SELECT id, title, locationID, providerID FROM Competition WHERE title = "..Q(id).." AND locationID = "..loc.id
		else
			assert(type(id) == "number")
			sql = "SELECT id, title, locationID, providerID FROM Competition WHERE id = "..id
		end
		local row = sqlds.new(dbc, sql):once()
		if row then
			row.id = tonumber(row.id)
			row.location = Location.load(dbc, tonumber(row.locationID))
			row.provider = Provider.load(dbc, tonumber(row.providerID))
			key = row.location.title.."-"..row.id
			_M[key] = new(row)
			_M[row.location.title.."-"..row.title] = _M[key]
		end
	end
	return _M[key]
end

-- update this object to DB
function save(self, dbc)
	local competition = load(dbc, self.title, self.location)
	if not competition then
		local sqlgen = sqlgens[dbc.driver]:new()
		local competition = om.new(OM, self)
		om.map(DBMAP, competition)
		sqlgen:insertobject("Competition", competition)
		log.sql(tostring(sqlgen))
		assert(sqlgen:execute(dbc))
		local row = sqlds.new(dbc, "SELECT MAX(id) as 'id' FROM Competition"):once()
		self.id = tonumber(row.id)
		local key = self.location.title.."-"..self.id
		assert(not _M[key])
		_M[key] = self
		_M[self.location.title.."-"..self.title] = _M[key]
	else
		self.id = competition.id
	end
	return self
end

-- get all competitions from DB
function getall(dbc)
	local src = sqlds.new(dbc, "SELECT id, title, locationID, providerID FROM Competition ORDER BY locationID"):source()
	return function ()
		local row = src()
		if row then
			row.id = tonumber(row.id)
			row.location = assert(Location.load(dbc, tonumber(row.locationID)), "location id="..row.locationID.." is missing")
			row.provider = assert(Provider.load(dbc, tonumber(row.providerID)), "provider id="..row.providerID.." is missing")
			return new(row)
		end
	end
end

return _M
