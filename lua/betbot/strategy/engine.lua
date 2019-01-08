-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2010,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      engine.lua                                         --
-- Description:   Strategy engine                                    --
--                                                                   --
-----------------------------------------------------------------------

local sqlds      = require "lrun.model.datasrc.sql"
local bookmaker  = require "betbot.model.bookmaker"
local string     = require "lrun.util.string"
local log        = require "betbot.log" 
local config     = require "lrun.util.config" 
local lfs        = require "lrun.util.lfs" 
local charts     = require "lrun.ai.util.charts" 
local Const      = require "betbot.constants"

module ("betbot.strategy.engine", package.seeall)

local function getoutputfilename(strategy, location, competition)
	local filename = strategy
	
	if location then
		filename = filename.."-"..location.."-"..competition
	end

	filename = string.gsub(filename, " ", "_")
	local basedir = lfs.concatfilenames(config.get(_conf, "dir.log"), strategy)
	if not lfs.isdir(basedir) then
		lfs.mkdir(basedir)
	end
	return lfs.concatfilenames(basedir, filename)
end

local function makechart(strategy, location, competition, data)
	local text = strategy
	if competition then
		text = text .. "("..competition..")"
	end
	charts.generate{outfile = getoutputfilename(strategy, location, competition)..".png", data = data, text = text}
end

local function openlogfilename(strategy, location, competition)
	return assert(io.open(getoutputfilename(strategy, location, competition)..".log", "w"))
end

function run(dbc, competitions, stratinfo)
	local algo, name, args, matchtablename =
		  stratinfo.algo, stratinfo.name or stratinfo.algo, stratinfo.args or {}, stratinfo.table or "Match"

	log.info("Running "..name.."("..table.concat(args, ",")..") on "..matchtablename)
	local strategy = require ("betbot.strategy.algo."..algo)
	local competitionIDs = {}
	for _, comp in ipairs(competitions) do
		table.insert(competitionIDs, comp.id)
	end
	local wheresql = ""
	if #competitionIDs > 0 then
		wheresql = " WHERE c.id in ("..table.concat(competitionIDs, ",")..")"
	end

	local bmIDs = {}
	local bookmakers = string.explode(config.get(_conf, "bookmakers"), ",")
	for _, bookmaker in ipairs(bookmakers) do
		table.insert(bmIDs, Const.Bookmaker[string.upper(bookmaker)])
	end

	local summarylogfile = openlogfilename(name)
	local stats = { totalprofit = 0, totalinvestment = 0, totalmatchcount = 0, totalmatchplayed = 0, totalmatchskipped = 0, totalexactguesses = 0, totalprofithistory = {} }
	local sql = "SELECT c.id, c.title, l.title as location FROM Competition c LEFT JOIN Location l ON l.id == c.locationid"..wheresql.." ORDER BY c.id"
	for comp in assert(sqlds.new(dbc, sql):source()) do
		local stat = { exactguesses = 0, profit = 0, matchcount = 0, matchskipped = 0, investment = 0, matchplayed = 0, profithistory = {} }
		stats[comp.title] = stat
		local logfile = openlogfilename(name, comp.location, comp.title)

		local row = sqlds.new(dbc, "SELECT COUNT(*) AS cnt FROM "..matchtablename.." m WHERE m.competitionID = "..comp.id):source()()
		local count = tonumber(row.cnt)
		local current = 0
		for match in assert(sqlds.new(dbc, "SELECT m.id, m.team1ID, m.team2ID, t1.title AS team1, t2.title AS team2, m.goals1, m.goals2, odd.home, odd.draw, odd.away FROM "..matchtablename.." m LEFT JOIN Team t1 ON t1.id == m.team1ID LEFT JOIN Team t2 ON t2.id == m.team2ID INNER JOIN Odds odd ON odd.matchID == m.id AND odd.bookmakerID in ("..table.concat(bmIDs, ",")..") WHERE m.competitionID = "..comp.id.." ORDER BY date"):source()) do
			local tid1, tid2, team1, team2, goals1, goals2, home, draw, away =
				tonumber(match.team1ID), tonumber(match.team2ID),
				match.team1, match.team2,
				tonumber(match.goals1), tonumber(match.goals2),
				tonumber(match.home), tonumber(match.draw), tonumber(match.away)

				current = current + 1

				local matchexit
				if goals1 == goals2 then
					matchexit = "X"
				elseif goals1 > goals2 then
					matchexit = "1"
				elseif goals1 < goals2 then
					matchexit = "2"
				end

				local bet1, bet2, bet3 = strategy(home, draw, away, tid1, tid2, unpack(args))
				local bets = {}
				if bet1 then table.insert(bets, bet1) end
				if bet2 then table.insert(bets, bet2) end
				if bet3 then table.insert(bets, bet3) end

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
						if matchexitbet == "X" and goals1 == goals2 then
							payout = payout + amount * draw
							stat.exactguesses = stat.exactguesses + 1
						elseif matchexitbet == "1" and goals1 > goals2 then
							payout = payout + amount * home
							stat.exactguesses = stat.exactguesses + 1
						elseif matchexitbet == "2" and goals1 < goals2 then
							payout = payout + amount * away
							stat.exactguesses = stat.exactguesses + 1
						end
						stat.matchplayed = stat.matchplayed + 1
					end
					stat.profit = stat.profit + payout
				end
				stat.matchcount = stat.matchcount + 1
				local webetonmsg = "skip betting"
				if #matchbets > 0 then
					webetonmsg = "betting money ["..table.concat(matchbets, ",").."]"
				end
				local msg = string.format("%.1f%% %s-%s [%.2f/%.2f/%.2f], %s. Result is [%s (%d-%d)], payout [%.2f], in pocket [%.2f]\n", 100*current/count, team1, team2, home, draw, away, webetonmsg, matchexit, goals1, goals2, payout, stat.profit)
				log.debug(name..": "..msg)
				logfile:write(msg)
				table.insert(stat.profithistory, stat.profit)
				table.insert(stats.totalprofithistory, stats.totalprofit + stat.profit)
		end
		local totalmsg = string.format(comp.title .. ", " .. comp.location..": investment=%d, profit=%d (%.2f%%) in %d bets on %d matches, exact guesses = %d (%.2f%% accuracy)",
									   stat.investment, stat.profit, 100*stat.profit/stat.investment, stat.matchplayed, stat.matchcount, stat.exactguesses, 100*stat.exactguesses/stat.matchplayed)
		log.info(totalmsg)
		logfile:write("\n"..totalmsg.."\n")
		summarylogfile:write(totalmsg.."\n")
		logfile:close()
		makechart(name, comp.location, comp.title, stat.profithistory)

		stats.totalprofit = stats.totalprofit + stat.profit
		stats.totalinvestment = stats.totalinvestment + stat.investment
		stats.totalmatchcount = stats.totalmatchcount + stat.matchcount
		stats.totalmatchskipped = stats.totalmatchskipped + stat.matchskipped
		stats.totalexactguesses = stats.totalexactguesses + stat.exactguesses
		stats.totalmatchplayed = stats.totalmatchplayed + stat.matchplayed
	end


	local totalmsg = string.format("Budget started with %d, budget ended with %.2f, (%.2f%% profit) in %d bets on %d matches, exact guesses = %d (%.2f%% accuracy)\n",
									stats.totalinvestment, stats.totalprofit + stats.totalinvestment, 100*stats.totalprofit/stats.totalinvestment,
									stats.totalmatchplayed, stats.totalmatchcount, stats.totalexactguesses, 100*stats.totalexactguesses/stats.totalmatchplayed)

	log.info(totalmsg)
	summarylogfile:write(totalmsg.."\n")
	summarylogfile:close()
	makechart(name, nil, nil, stats.totalprofithistory)
	return stats
end
