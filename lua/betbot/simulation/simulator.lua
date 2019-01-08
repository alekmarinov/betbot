-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2010,  AVIQ Systems AG                              --
--                                                                   --
-- Project:       LRun                                               --
-- Filename:      simulator.lua                                      --
-- Description:   Simulates running various betting strategies       --
--                                                                   --
-----------------------------------------------------------------------

local string      = require "lrun.util.string"
local config      = require "lrun.util.config"
local competition = require "betbot.model.competition"
local engine      = require "betbot.strategy.engine"
local matchset    = require "betbot.analysis.matchset"
local charts      = require "lrun.ai.util.charts" 
local lfs         = require "lrun.util.lfs"
local log         = require "betbot.log" 

local _G, setmetatable, assert, io, tonumber, table, os, string, ipairs, unpack, tostring =
	  _G, setmetatable, assert, io, tonumber, table, os, string, ipairs, unpack, tostring
local print = print

module "betbot.simulation.simulator"

function simulate(self, strategyclass)
	local ms = matchset.new(self.dbc)

	local matchsetconstraints = config.get(_G._conf, "analysis.simulate.matchset."..self.matchsetname)
	if not matchsetconstraints then
		return nil, "analysis.simulate.matchset."..self.matchsetname.." is not set in configuration"
	end
	assert(ms:filterbyconstraints(matchsetconstraints))
	local matchsrc = assert(ms:source())
	local matchsetsize = assert(ms:count())

	local logfilename = lfs.concatfilenames(config.get(_G._conf, "analysis.simulate.dir"),
		self.matchsetname, 
		strategyclass._NAME.."-"..os.date("%y-%m-%d_%H%M"))..".log"

	lfs.mkdir(lfs.dirname(logfilename))
	local logfile, err = io.open(logfilename, "w")
	if not logfile then
		return nil, err
	end

	local strategy = strategyclass.new(self.matchsetname)
	local stat = { wins = 0, profit = 0, matchcount = 0, matchskipped = 0, investment = 0, betcount = 0, nbx = 0, nb1 = 0, nb2 = 0, nx = 0, n1 = 0, n2 = 0}
	local chartdata = {}
	local current = 0
	for match in matchsrc do
		local tid1, tid2, team1, team2, goals1, goals2, home, draw, away =
				tonumber(match.team1ID), tonumber(match.team2ID),
				match.team1, match.team2,
				tonumber(match.goals1), tonumber(match.goals2),
				tonumber(match.home), tonumber(match.draw), tonumber(match.away)

		current = current + 1

		local bet1, bet2, bet3 = strategy(team1, team2, home, draw, away)
		local bets = {}
		if bet1 then table.insert(bets, bet1) end
		if bet2 then table.insert(bets, bet2) end
		if bet3 then table.insert(bets, bet3) end

		local matchexit
		if goals1 == goals2 then
			matchexit = "X"
			stat.nx = stat.nx + 1
		elseif goals1 > goals2 then
			matchexit = "1"
			stat.n1 = stat.n1 + 1
		elseif goals1 < goals2 then
			matchexit = "2"
			stat.n2 = stat.n2 + 1
		end

		local payout = 0
		local matchbets = {}
		if #bets == 0 then
			stat.matchskipped = stat.matchskipped + 1
		else
			for _, bet in ipairs(bets) do
				local matchexitbet, amount = unpack(bet)
				matchexitbet = string.upper(tostring(matchexitbet))
				table.insert(matchbets, matchexitbet.."-"..amount)
				payout = payout - amount
				stat.investment = stat.investment + amount
				if matchexitbet == "X" then
					if goals1 == goals2 then
						payout = payout + amount * draw
						stat.wins = stat.wins + 1
					end
					stat.nbx = stat.nbx + 1
				elseif matchexitbet == "1" then
					if goals1 > goals2 then
						payout = payout + amount * home
						stat.wins = stat.wins + 1
					end
					stat.nb1 = stat.nb1 + 1
				elseif matchexitbet == "2" then
					if goals1 < goals2 then
						payout = payout + amount * away
						stat.wins = stat.wins + 1
					end
					stat.nb2 = stat.nb2 + 1
				end
				stat.betcount = stat.betcount + 1
			end
			stat.profit = stat.profit + payout
		end
		stat.matchcount = stat.matchcount + 1
		local actionmsg = "skip betting"
		if #matchbets > 0 then
			actionmsg = "betting money ["..table.concat(matchbets, ",").."]"
		end
		local msg = string.format("%.1f%% "..match.date.." %s-%s [%.2f/%.2f/%.2f], %s. Result is [%s (%d-%d)], payout [%.2f], in pocket [%.2f]\n",
			100*current/matchsetsize, team1, team2, home, draw, away, actionmsg, matchexit, goals1, goals2, payout, stat.profit)
		log.info(strategyclass._NAME..": "..msg)
		logfile:write(msg)
		table.insert(chartdata, stat.profit)
	end
	logfile:write(stat.nbx.."-X bets, "..stat.nb1.."-1 bets and "..stat.nb2.."-2 bets, from "..stat.nx.."-X "..stat.n1.."-1 and "..stat.n2.."-2 in total\n")
	logfile:write(stat.wins.." wins, "..stat.profit.." profit, "..stat.matchcount.." matches, "..stat.matchskipped.." skipped, "..
		stat.investment.." total investment, "..stat.betcount.." bets total, "..string.format("%.2f%%", 100*stat.profit/stat.investment).." performance\n")
	logfile:close()
	local chartfilename = lfs.concatfilenames(config.get(_G._conf, "analysis.simulate.dir"), self.matchsetname, strategyclass._NAME)..".png"
	return charts.generate{outfile = chartfilename, data = chartdata, text = strategyclass._NAME}
end

function new(dbc, matchsetname, destdir)
	return setmetatable({
		dbc = dbc,
		matchsetname = matchsetname,
		destdir = destdir or ""
		}, {__index=_M})
end
