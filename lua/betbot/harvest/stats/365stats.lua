-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2009,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      365stats.lua                                       --
-- Description:   www.365stats.com harvester class                   --
--                                                                   --
-----------------------------------------------------------------------

local om          = require "lrun.model.om" 
local http        = require "socket.http"
local team        = require "betbot.model.team"
local bookmaker   = require "betbot.model.bookmaker"
local competition = require "betbot.model.competition"
local odds        = require "betbot.model.odds"
local match       = require "betbot.model.match"
local log         = require "betbot.log"
require "lrun.stream.all"

module ("betbot.harvest.stats.365stats", package.seeall)

DATE_EARLIEST = "2002-01-01"
URL           = "http://www.365stats.com/football/index.php?p=results"
USER_AGENT    = "Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US; rv:1.9.2.6) Gecko/20100625 Firefox/3.6.6 ( .NET CLR 3.5.30729; .NET4.0C)"

function formatsize(nbytes)
	assert(type(nbytes) == "number")
	local suffixes = {"B", "KB", "MB", "GB", "TB"};
	local suffix, degree = "B", 1
	local d = 1
	for _, s in ipairs(suffixes) do
		if nbytes > d then
			degree = d
			d = d * 1024
			suffix = s
		end
	end
	return string.format("%.1f %s", nbytes/degree, suffix)
end

local function getmatcheshtml(comp, datefrom, dateto)
	om.validate(competition.OM, comp)
	local d1, m1, y1, d2, m2, y2 =
		tonumber(datefrom:sub(9, 10)), tonumber(datefrom:sub(6, 7)), tonumber(datefrom:sub(1, 4)),
		tonumber(dateto:sub(9, 10)), tonumber(dateto:sub(6, 7)), tonumber(dateto:sub(1, 4))

	local divs = {
		["PREMIER LEAGUE"] = "E0",
		["CHAMPIONSHIP"] = "E1",
		["LEAGUE ONE"] = "E2",
		["LEAGUE TWO"] = "E3",
		["SERIE A"] = "I1",
		["PRIMERA LIGA"] = "SP1",
		["BUNDESLIGA"] = "D1",
		["LIGUE 1"] = "F1",
		["SCOTTISH PREMIER LEAGUE"] = "SC0",
		["A-LEAGUE"] = "AUS",
	}

	local div = divs[comp.title:upper()]
	if not div then
		return nil, "Division "..comp.title.." is not supported"
	end

	vars = {
		"div="..div, "day_from="..d1, "month_from="..m1, "year_from="..y1, "day_to="..d2, "month_to="..m2, "year_to="..y2,
		"price_from=", "price_to=", "price_from2=", "price_to2=", "price_fromX=", "price_toX=",
		"rating_from=-999", "rating_to=999"
	}

	local result = {}
	local downloadsize = 0
	local postdata = table.concat(vars, "&")
	local ok, code, headers, err = socket.http.request {
		method = "POST",
		url = URL,
		source = ltn12.source.string(postdata.."\r\n"),
		sink = function(chunk)
			if chunk then
				table.insert(result, chunk)
				downloadsize = downloadsize + chunk:len()
				io.write("downloading data... "..formatsize(downloadsize)..string.rep(" ", 10).."\r") io.flush()
			end
			return 1
		end,
		headers = {
			["user-agent"] = USER_AGENT,
			["accept-charset"] = "ISO-8859-1,utf-8;q=0.7,*;q=0.7",
			["content-length"] = string.len(postdata),
			["content-type"] = "application/x-www-form-urlencoded",
			--["accept-encoding"] = "gzip,deflate",
			["accept-language"] = "en-us,en;q=0.5",
			["accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
			["referer"] = URL,
			["keep-alive"] = "115"
		}
	}

	if tonumber(code) == 200 then
		return table.concat(result)
	else
		return nil, err or code
	end
end

local function updateteam(title)
	local o = team.load(_dbc, title)
	if not o then
		o = team.new{title=title}
		o:save(_dbc)
	end
	return o
end

local function parsematches(comp, html)
	local f = string.gfind(html, "<td%salign=\"center\">(%d+)/(%d+)/(%d+)</td>(.-)</tr>")
	return function ()
		local day, month, year, matchinfo = f()
		while matchinfo do
			local mom = {}
			local matchdate = year.."-"..month.."-"..day
			local team1, team2, goals1, goals2
			local counter = 1
			for entry in string.gfind(matchinfo, "([^>]-)</a>") do
				if counter == 1 then
					team1 = entry
				elseif counter == 2 then
					string.gsub(entry, "(%d+)%-(%d+)", function (g1, g2)
						goals1, goals2 = tonumber(g1), tonumber(g2)
					end)
				elseif counter == 3 then
					team2 = entry
				end
				counter = counter + 1
			end
			assert(counter == 4)
			
			counter = 1
			local oddhome, odddraw, oddaway
			for entry in string.gfind(matchinfo, "<td%salign=\"center\">([%d%.]+)</td>") do
				if counter == 1 then
					oddhome = tonumber(entry)
				elseif counter == 2 then
					odddraw = tonumber(entry)
				elseif counter == 3 then
					oddaway = tonumber(entry)
				end
				counter = counter + 1
			end

			if counter ~= 4 then
				log.warn("invalid html format detected in match "..team1.." vs "..team2.." on "..matchdate)
				day, month, year, matchinfo = f()
			else
				mom.date = matchdate
				mom.team1 = updateteam(assert(team1))
				mom.team2 = updateteam(assert(team2))
				mom.goals1 = goals1
				mom.goals2 = goals2		

				if oddhome < 1 or odddraw < 1 or oddaway < 1 then
					log.warn("\ninvalid odds while parsing "..team1.." vs "..team2.." on "..matchdate..
						". oddhome="..oddhome..", odddraw="..odddraw..", oddaway="..oddaway.." while all must be >= 1")
					day, month, year, matchinfo = f()
				else
					mom.odds = {
						odds.new{bookmaker=assert(bookmaker.load(_dbc, "365stats")), match=mom, home=oddhome, draw=odddraw, away=oddaway}
					}
					mom.competition = comp
					return match.new(mom)
				end
			end
		end
	end
end

function update(datefrom, dateto)
	datefrom = datefrom or match.getlastmatchdate(_dbc) or DATE_EARLIEST
	dateto = dateto or os.date("%Y-%m-%d")
	log.info("<< "..URL)
	log.info("Updating all matches since "..datefrom.." to "..dateto)
	local newmatches = 0
	for comp in competition.getall(_dbc) do
		log.info("Updating matches from "..comp.title..", "..comp.location.title)
		local html, err = getmatcheshtml(comp, datefrom, dateto)
		if not html then
			log.warn(err)
		else
			for match in parsematches(comp, html) do
				if match:save(_dbc) then
					newmatches = newmatches + 1
					log.info("Added "..comp.location.title.."/"..comp.title..": "..match.team1.title.." vs "..match.team2.title.." "..match.goals1..":"..match.goals2.." "..
						string.format("%5.2f %5.2f %5.2f", match.odds[1].home, match.odds[1].draw, match.odds[1].away))
				end
			end
		end
	end
	if newmatches > 0 then
		log.info(newmatches.." matches successfuly updated")
	else
		log.info("no new match updates")
	end
	return true
end

return _M
