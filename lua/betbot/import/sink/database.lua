-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2010,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      database.lua                                       --
-- Description:   DB sink                                            --
--                                                                   --
-----------------------------------------------------------------------

local Provider    = require "betbot.model.provider"
local Bookmaker   = require "betbot.model.bookmaker"
local Location    = require "betbot.model.location"
local Competition = require "betbot.model.competition"
local Team        = require "betbot.model.team"
local Match       = require "betbot.model.match"
local Odds        = require "betbot.model.odds"
local log         = require "betbot.log" 
local db          = require "lrun.model.db"
local config      = require "lrun.util.config"

local _G, assert, pairs, setmetatable, os =
      _G, assert, pairs, setmetatable, os

module "betbot.import.sink.database"

_NAME = "database"
_DESCRIPTION = "Sink data chunk to database"

local sinks
sinks = {
	bookmaker = function (dbc, object, provider)
		if not object.bookmaker then
			return nil, "property bookmaker is missing"
		end
		return Bookmaker.new{
			title = object.bookmaker,
			website = object.website,
			provider = provider
		}:save(dbc)
	end,
	location = function (dbc, title, provider)	
		return Location.new{
			title = title,
			provider = provider
		}:save(dbc)
	end,
	competition = function (dbc, object, provider)
		local location, competition, err
		if not object.location then
			return nil, "property location is missing"
		end
		location, err = sinks.location(dbc, object.location, provider)
		if not location then
			return nil, err
		end
		return Competition.new{
			title = object.competition,
			location = location,
			provider = provider
		}:save(dbc)
	end,
	team = function (dbc, object, provider)
		local location, team, err
		location, err = sinks.location(dbc, object.location, provider)
		if not location then
			return nil, err
		end
		if not object.team then
			return nil, "property team is missing"
		end
		return Team.new{
			title = object.team,
			location = location,
			provider = provider
		}:save(dbc)
	end,
	match = function (dbc, object, provider)
		local location, err
		location, err = sinks.location(dbc, object.location, provider)
		if not location then
			return nil, err
		end

		local competition
		competition, err = sinks.competition(dbc, object, provider)
		if not competition then
			return nil, err
		end

		local team1
		team1, err = sinks.team(dbc, {team = object.team1, location = object.location}, provider)
		if not team1 then
			return nil, err
		end

		local team2
		team2, err = sinks.team(dbc, {team = object.team2, location = object.location}, provider)
		if not team2 then
			return nil, err
		end

		if not object.goals1 then
			return nil, "property goals1 is missing"
		end

		if not object.goals2 then
			return nil, "property goals1 is missing"
		end

		if not object.date then
			return nil, "property date is missing"
		end
		return Match.new{
			date = object.date,
			competition = competition,
			team1 = team1,
			team2 = team2,
			goals1 = object.goals1,
			goals2 = object.goals2,
			provider = provider
		}:save(dbc)
	end,
	odds = function (dbc, object, provider)
		local bookmaker, err = sinks.bookmaker(dbc, object, provider)
		if not bookmaker then
			return nil, err
		end
		local match, err = sinks.match(dbc, object.match, provider)
		if not match then
			return nil, err
		end
		if not object.oddhome then
			return nil, "property oddhome is missing"
		end
		if not object.odddraw then
			return nil, "property odddraw is missing"
		end
		if not object.oddaway then
			return nil, "property oddaway is missing"
		end
		return Odds.new{
			bookmaker = bookmaker,
			match = match,
			home = object.oddhome,
			draw = object.odddraw,
			away = object.oddaway,
			provider = provider
		}:save(dbc)
	end
}

return setmetatable(_M, {__call = function ()

	-- initialize sink database
	local dbc = assert(db.new{
		driver = config.get(_G._conf, "db.driver"),
		database = os.date(config.get(_G._conf, "db.sink.database"))
	})

	return function (chunk)
		if not chunk then
			-- end of stream
			dbc:close()
			return nil
		end
		local provider = assert(Provider.load(dbc, chunk.provider))
		for t, v in pairs(chunk) do
			t = t:lower()
			if t ~= "provider" then
				local ok, err = sinks[t](dbc, v, provider)
				if not ok then
					log.error(err)
				end
			end
		end
		return chunk
	end
end})
