-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2010,  AVIQ Systems AG                              --
--                                                                   --
-- Project:       LRun                                               --
-- Filename:      select.lua                                         --
-- Description:   Select match sets                                  --
--                                                                   --
-----------------------------------------------------------------------

require "lrun.stream.all"
local matchset = require "betbot.analysis.matchset"
local config   = require "lrun.util.config"
local log      = require "betbot.log"

local _G, lrun, print, select, setmetatable, table, string, pairs, ipairs, setfenv, loadstring =
      _G, lrun, print, select, setmetatable, table, string, pairs, ipairs, setfenv, loadstring

module "betbot.command.select"

_NAME = "select"
_DESCRIPTION = "Select various match sets"
_HELP = [[

SYNTAX: select <query> [args...], where

<query> ::= matchsetname | <matchsetdef>
<matchsetdef> ::= { (<model>:<model>.title || <model>.<attribute> '<' | '>' | '<=' | '>=' <value>) ';' }
<model> ::= Provider | Bookmaker | Location | Competition | Team | Match
<value> ::= <number> | <string> | <date>

EXAMPLES:

	select ManCity_Sunderland
	select TeamVsTeam ManCity Sunderland
	select Provider:football_data;Bookmaker:Bet365;Location:England;Competition:Premier League;Team:Man City,Sunderland;Match.date>2005-01-01
]]

return setmetatable(_M, { __call = function (this, ...)
	local query = table.concat({...}, " ")
	if query == "--help" then
		-- display help
		print(_HELP)
		return true
	else
		local matchsetconstraints = config.get(_G._conf, "analysis.matchset."..select(1, ...)) or config.get(_G._conf, "analysis.train.matchset."..select(1, ...)) or query
		if table.getn({...}) > 1 then
			matchsetconstraints = string.format(matchsetconstraints, select(2, ...))
		end

		local ms = matchset.new(_G._dbc)
		local ok, err = ms:filterbyconstraints(matchsetconstraints)
		if not ok then
			return nil, err
		end
		local matchsrc, err = ms:source()
		if not matchsrc then
			return nil, err
		end
		for m in matchsrc do
			local matchprn = {}
			table.insert(matchprn, m.date)
			table.insert(matchprn, " ")
			table.insert(matchprn, m.team1)
			table.insert(matchprn, " vs ")
			table.insert(matchprn, m.team2)
			table.insert(matchprn, " ")
			table.insert(matchprn, m.goals1)
			table.insert(matchprn, ":")
			table.insert(matchprn, m.goals2)
			table.insert(matchprn, " odds ")
			table.insert(matchprn, "(")
			table.insert(matchprn, m.home)
			table.insert(matchprn, ",")
			table.insert(matchprn, m.draw)
			table.insert(matchprn, ",")
			table.insert(matchprn, m.away)
			table.insert(matchprn, ")")
			print(table.concat(matchprn))
		end
		return true
	end
end})
