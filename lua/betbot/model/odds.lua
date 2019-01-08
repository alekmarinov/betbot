-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2009,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      odds.lua                                           --
-- Description:   Odds class definition                              --
--                                                                   --
-----------------------------------------------------------------------

local om        = require "lrun.model.om" 
local sqlds     = require "lrun.model.datasrc.sql"
local sqlgens   = require "lrun.model.schema.sqlgen.all"
local log       = require "betbot.log" 
local Bookmaker = require "betbot.model.bookmaker"
local Match     = require "betbot.model.match"
local Provider = require "betbot.model.provider"

module ("betbot.model.odds", package.seeall)

OM =
{
	{"bookmaker", "required", Bookmaker.OM},
	{"match", "required", Match.OM},
	{"provider", "required", Provider.OM},
	{"home", "required", "number"},
	{"draw", "required", "number"},
	{"away", "required", "number"},
}

DBMAP =
{
	{"bookmaker", "bookmakerID",  function(b) return b.id end},
	{"match", "matchID", function(m) return m.id end},
	{"provider", "providerID", function(p) return p.id end},
}

__index = _M

-- creates new odds object
function new(rom)
	om.validate(OM, rom)
	return setmetatable(rom, _M)
end

-- compares two odds objects
function __eq(r1, r2)
	return om.compare(OM, r1, r2) == 0
end

-- delete odds from DB
function delete(self, dbc)
	local sqlgen = sqlgens[dbc.driver]:new()
	sqlgen:delete("Odds", string.format("bookmakerid = %d AND matchid = %d", self.bookmaker.id, self.match.id))
	log.sql(tostring(sqlgen))
	assert(sqlgen:execute(dbc))
end

-- load odds by bookmaker and match
function load(dbc, bookmaker, match)
	om.validate(Bookmaker.OM, bookmaker)
	om.validate(Match.OM, match)

	local row = sqlds.new(dbc, "SELECT home, draw, away, providerID FROM Odds WHERE bookmakerID = "..bookmaker.id.." AND matchID = "..match.id):once()
	if row then
		local provider = Provider.load(dbc, tonumber(row.providerID))
		local home, draw, away = tonumber(row.home), tonumber(row.draw), tonumber(row.away)
		return new{
			bookmaker = bookmaker,
			match = match,
			provider = provider,
			home = home,
			draw = draw,
			away = away
		}
	end
end

-- save odds to DB
function save(self, dbc)
	local sqlgen = sqlgens[dbc.driver]:new()
	local odds = load(dbc, self.bookmaker, self.match)
	if odds then
		if odds.home ~= self.home or odds.draw ~= self.draw or odds.away ~= self.away then
			sqlgen:update("Odds",
				{"home", "draw", "away"}, 
				{self.home, self.draw, self.away},
				"bookmakerID = "..self.bookmaker.id.." AND matchID = "..self.match.id)
			log.sql(tostring(sqlgen))
			assert(sqlgen:execute(dbc))
		end
	else
		odds = om.new(OM, self)
		om.map(DBMAP, odds)
		sqlgen:insertobject("Odds", odds)
		log.sql(tostring(sqlgen))
		assert(sqlgen:execute(dbc))
	end
	return self
end

return _M
