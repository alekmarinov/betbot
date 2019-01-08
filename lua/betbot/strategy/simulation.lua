-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2010,  AVIQ Systems AG                              --
--                                                                   --
-- Project:       LRun                                               --
-- Filename:      simulation.lua                                     --
-- Description:   Simulation engine                                  --
--                                                                   --
-----------------------------------------------------------------------

local string      = require "lrun.util.string"
local config      = require "lrun.util.config"
local competition = require "betbot.model.competition"
local engine      = require "betbot.strategy.engine"
local matchset    = require "betbot.analysis.matchset"

local print = print

module ("betbot.strategy.simulation", package.seeall)

function simulate(...)
	print(...)
--[[
	-- create competitions from configuration
	local competitions = {}
	for location, compets in pairs(config.get(_conf, "competitions")) do
		for _, compet in ipairs(string.explode(compets, ",")) do
			table.insert(competitions, competition.load(_dbc, compet, location))
		end
	end

	-- run configured strategies over selected competitions
	for name, strat in pairs(config.get(_conf, "analysis")) do
		strat.name = name
		if strat.args then
			strat.args = string.explode(strat.args, ",")
		end
		engine.run(_dbc, competitions, strat)
	end
--]]
	local ms = matchset.new(_dbc)

	--[[
	assert(ms:filterbytitles("Location", "Scotland,England"))
	assert(ms:filterbytitles("Team", "Arsenal, Liverpool"))
	assert(ms:filterbytitles("Bookmaker", "Bet365"))
	assert(ms:filterbyoperator("Match.date", ">", "2000-01-01"))
	--]]
	assert(ms:filterbyconstraints("Provider:football_data;Bookmaker:Bet365;Location:England;Competition:Premier League;Team:Arsenal,Liverpool;Match.date>='2000-01-01';Match.date<=current_date"))
	assert(ms:orderby("match.date"))

	print(ms:getsql())
	local count = 0
	for row in assert(ms:source()) do
		print(row.date.." "..row.team1.." "..row.goals1.."-"..row.goals2.." "..row.team2.." "..row.home..", "..row.draw..", "..row.away)
		count = count + 1
	end
	print(count.." results")

	return true
end

return _M
