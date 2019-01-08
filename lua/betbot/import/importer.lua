-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2010,  AVIQ Systems AG                              --
--                                                                   --
-- Project:       LRun                                               --
-- Filename:      importer.lua                                       --
-- Description:   Importing component                                ----
--                                                                   --
-----------------------------------------------------------------------

require "lrun.stream.all"

local _G, lrun, print, setmetatable, table, string, pairs, ipairs, setfenv, loadstring =
      _G, lrun, print, setmetatable, table, string, pairs, ipairs, setfenv, loadstring

local log = require "betbot.log"

local sources =
{
	soccerstand   = require "betbot.import.source.soccerstand",
	football_data = require "betbot.import.source.football_data",
}

local sinks =
{
	database      = require "betbot.import.sink.database",
	log           = require "betbot.import.sink.log",
}

local filters =
{
	validator     = require "betbot.import.filter.validator",
	titles        = require "betbot.import.filter.titles"
}

module "betbot.import.import"

_NAME = "importer"
_DESCRIPTION = "Advanced importing system from any sources to any sinks"
_HELP =[[

SYNTAX: import <expr>, where

<expr> ::= P ( <src>, <sink> )
<src>  ::= <srcname> | F ( <filter>, <src> ) | C ( <src> {',' <src>} )
<sink> ::= <sinkname> | D( <sink> {',' <sink>} )
<srcname>  ::= %s
<sinkname> ::= %s
<filter>   ::= %s

-- Sources:
%s

-- Sinks:
%s

-- Filters:
%s

EXAMPLES:

	import P(smarterbetting, log)
Imports data from source 'smarterbetting' sinked to 'log'

	import P(F(titles, F(validator, C(smarterbetting, soccerstand))), D(log, database))
Imports data from concatenated sources 'smarterbetting' and 'soccerstand' filtered first by 'validator' then by 'titles' and finaly demultiplexed to 'log' and 'database'
]]

local function names(t)
	local keys = {}
	for k in pairs(t) do
		table.insert(keys, k)
	end
	table.sort(keys)
	return table.concat(keys, " | ")
end

local function descriptions(t)
	local descr = {}
	for name, obj in pairs(t) do
		table.insert(descr, obj._NAME.." - "..obj._DESCRIPTION)
	end
	return table.concat(descr, "\n")
end

_HELP = string.format(_HELP,
	names(sources), names(sinks), names(filters),
	descriptions(sources), descriptions(sinks), descriptions(filters)
)

local function logd(s)
	log.debug(s..string.rep(" ", 40-s:len()))
end

local function register(env, functab, class)
	for name, func in pairs(functab) do
		logd("Registering "..class.." "..name)
		env[name] = func()
	end
end

return setmetatable(_M, { __call = function (this, expr)
	log.debug(_NAME..": executing command "..expr)
	local env = {
		_conf = _G._conf,
		_dbc = _G._dbc,
		P = lrun.stream.pump.all,
		F = lrun.stream.source.filter,
		D = lrun.stream.sink.demux,
	}

	register(env, sources, "source")
	register(env, sinks, "sink")
	register(env, filters, "filter")

	local chunk, err = loadstring(expr)
	if not chunk then
		return nil, err
	end
	setfenv(chunk, setmetatable(env, {
		__index = function (t, n)
			return rawget(t, n)
		end
	}))
	chunk()
	log.debug(_NAME..": finished")
	return true
end})
