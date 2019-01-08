-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2009,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      bookmaker.lua                                      --
-- Description:   Bookmaker class definition                         --
--                                                                   --
-----------------------------------------------------------------------

local om       = require "lrun.model.om" 
local sqlds    = require "lrun.model.datasrc.sql"
local sqlgens  = require "lrun.model.schema.sqlgen.all"
local log      = require "betbot.log" 
local Provider = require "betbot.model.provider" 

module ("betbot.model.bookmaker", package.seeall)

OM =
{
	{"id", "optional", "number"},
	{"title", "required", "string"},
	{"website", "optional", "string"},
	{"provider", "required", Provider.OM},
}

DBMAP =
{
	{"provider", "providerID", function(t) return t.id end},
}

__index = _M

-- creates new bookmaker object
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
	local s = self.title
	if self.website then
		s = s.." ("..self.website..")"
	end
	return s
end

--- quote string
function Q(arg)
	assert(type(arg) == "string")

	return "'" .. arg:gsub("'", "''") .. "'"
end

-- load object from DB by id or title
function load(dbc, id)
	if not _M[id] then
		local sql
		if type(id) == "string" then
			sql = "SELECT id, title, website, providerID FROM Bookmaker WHERE title = "..Q(id)
		else
			assert(type(id) == "number", "id number expected, got "..type(id))
			sql = "SELECT id, title, website, providerID FROM Bookmaker WHERE id = "..id
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
	local bookmaker = load(dbc, self.title)
	if bookmaker then
		self.id = bookmaker.id
		self.website = self.website or bookmaker.website
		if self == bookmaker then
			return self
		end
	end

	local sqlgen = sqlgens[dbc.driver]:new()

	bookmaker = om.new(OM, self)
	om.map(DBMAP, bookmaker)

	if self.id then
		sqlgen:updateobject("Bookmaker", bookmaker)
	else
		sqlgen:insertobject("Bookmaker", bookmaker)
	end

	log.sql(tostring(sqlgen))
	assert(sqlgen:execute(dbc))
	local row = sqlds.new(dbc, "SELECT MAX(id) as 'id' FROM Bookmaker"):once()
	self.id = tonumber(row.id)
	_M[self.title] = self
	return self
end

return _M
