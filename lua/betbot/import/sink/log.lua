-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2010,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      log.lua                                            --
-- Description:   sink to log                                        --
--                                                                   --
-----------------------------------------------------------------------

local log = require "betbot.log"

local table, pairs, assert, type, setmetatable =
      table, pairs, assert, type, setmetatable

local print = print

module "betbot.import.sink.log"

_NAME = "log"
_DESCRIPTION = "Sink data chunk to log"

local sinks = {
	bookmaker = function (logf, object, provider)
		logf(provider.."> Bookmaker "..object.bookmaker.."/"..object.website)
	end,
	location = function (logf, title, provider)
		logf(provider.."> Location "..title)
	end,
	competition = function (logf, object, provider)
		logf(provider.."> Competition "..object.location.."/"..object.competition)
	end,
	team = function (logf, object, provider)
		logf(provider.."> Team "..object.location.."/"..object.team)
	end,
	match = function (logf, object, provider)
		logf(provider.."> Match "..object.location.."/"..object.competition.." "..
			object.date.." "..object.team1.." "..object.goals1..":"..object.goals2.." "..object.team2)
	end,
	odds = function (logf, object, provider)
		print(object.match.location, object.match.competition, object.match.date, object.match.team1, object.match.team2, object.bookmaker)
		logf(provider.."> Odds by "..object.bookmaker.." "..object.match.location.."/"..object.match.competition.." "..
			object.match.date.." "..object.match.team1.." "..object.match.goals1..":"..object.match.goals2.." "..
			object.match.team2.." ("..object.oddhome.."/"..object.odddraw.."/"..object.oddaway..")")
	end
}

return setmetatable(_M, {__call = function (_, loglevel)
	loglevel = loglevel or "debug"
	local logf = log[loglevel]
	assert(type(logf) == "function", "Invalid log level "..loglevel)
	return function (chunk)
		if not chunk then
			return nil
		end
		for t, v in pairs(chunk) do
			t = t:lower()
			if t ~= "provider" then
				sinks[t](logf, v, chunk.provider)
			end
		end
		return chunk
	end
end})
