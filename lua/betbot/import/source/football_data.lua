-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2010,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      football_data.lua                            --
-- Description:   football-data.co.uk source of matches              --
--                                                                   --
-----------------------------------------------------------------------

local downloader  = require "betbot.import.method.download"
local log         = require "betbot.log" 
local lfs         = require "lrun.util.lfs" 
local table       = require "lrun.util.table"
local string      = require "lrun.util.string"
local config      = require "lrun.util.config"

local _G, assert, type, tonumber, tostring, ipairs, pairs, unpack, setmetatable, math, string, io, os =
      _G, assert, type, tonumber, tostring, ipairs, pairs, unpack, setmetatable, math, string, io, os

local print = print

module "betbot.import.provider.football_data.source"

_NAME = "football_data"
_DESCRIPTION = "Source for match results from football-data.co.uk"

local BASEURL = "http://football-data.co.uk";
local LOCATIONS =
{
	"England",
	"Scotland",
	"Germany",
	"Italy",
	"Spain",
	"France",
	"Netherlands",
	"Belgium",
	"Portugal",
	"Turkey",
	"Greece",
}

local BOOKMAKERS =
{
	{id="B365", title="Bet365", website="www.fixme.com"},
	{id="BS",   title="Blue Square", website="www.fixme.com"},
	{id="BW",   title="Bet&Win", website="www.fixme.com"},
	{id="GB",   title="Gamebookers", website="www.fixme.com"},
	{id="IW",   title="Interwetten", website="www.fixme.com"},
	{id="LB",   title="Ladbrokes", website="www.fixme.com"},
	{id="SO",   title="Sporting Odds", website="www.fixme.com"},
	{id="SB",   title="Sportingbet", website="www.fixme.com"},
	{id="SJ",   title="Stan James", website="www.fixme.com"},
	{id="SY",   title="Stanleybet", website="www.fixme.com"},
	{id="VC",   title="VC Bet", website="www.fixme.com"},
	{id="WH",   title="William Hill", website="www.fixme.com"},
}

local function showprogress(fract, speed)
	local function formatsize(nbytes)
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
	
	local barsize = 40
	local pluses = math.floor(barsize*fract)
	io.write(string.format("[%s%d%%%s] %s    \r", string.rep("+", pluses), 100*fract, string.rep(" ", barsize-pluses), formatsize(speed or 0).."/s"))
	io.flush()
end

local function competitionsiterator(locname)
	local datadir = lfs.concatfilenames(config.get(_G._conf, "provider.football_data.csvdir"), _NAME)
	-- yes, it is ..m.php
	local html = assert(downloader.download(BASEURL.."/"..string.lower(locname).."m.php", showprogress))
	local linesiter = string.gfind(html, "(.-)\n")
	local line = linesiter()
	local competitions = {}
	while true do
		while line and not string.match(line, "<I>Season %d+/%d+</I><BR>") do
			line = linesiter()
		end
		if not line then
			break
		end
		local myear
		string.gsub(line, "Season (%d+)/(%d+)", function (_y1, _y2)
			myear = _y1.."-".._y2
		end)
		assert(myear, line.." don't match string `Season (%d+)/(%d+)'")
		local cdir = lfs.concatfilenames(datadir, locname, myear)
		line = linesiter()
		while string.len(string.trim(line)) > 0 and not string.match(line, "<I>Season %d+/%d+</I><BR>") do
			local uri, ctitle
			string.gsub(line, "<A HREF=\"(.-)\">(.-)</A>", function (_uri, _ctitle)
				uri, ctitle = _uri, _ctitle
			end)
			assert(uri, line.." don't match string `<A HREF=\"(.-)\">(.-)</A>'")
			if not table.indexof(competitions, ctitle) then
				table.insert(competitions, ctitle)
			end
			lfs.mkdir(cdir)
			local csvfile = lfs.concatfilenames(cdir, ctitle)..".csv"
			if not lfs.isfile(csvfile) or lfs.filesize(csvfile) == 0 then
				assert(downloader.downloadfile(BASEURL.."/"..uri, csvfile, showprogress))
			end
			line = linesiter()
		end
	end
	return table.elementiterator(competitions)
end

local function matchesiterator(locname, competition)
	local function notempty(s)
		return string.len(s or "") > 0
	end

	local datadir = lfs.concatfilenames(config.get(_G._conf, "provider.football_data.csvdir"), _NAME)
	local locdir = lfs.concatfilenames(datadir, locname)
	local csvfiles = {}
	for yeardir in lfs.dir(locdir) do
		local csvfile = lfs.concatfilenames(locdir, yeardir, competition)..".csv"
		if lfs.isfile(csvfile) then
			table.insert(csvfiles, csvfile)
		end
	end

	local counter = 0
	local linesiter, csvfile, matchline
	local csviter = table.elementiterator(csvfiles)
	local headinfo
	local bookmakers
	return function ()
		while true do
			if not csvfile then
				csvfile = csviter()
				linesiter = nil
				matchline = nil
				if not csvfile then
					-- no more csv files, exiting
					return nil
				end
				counter = counter + 1
			end
			if not matchline then
				if not linesiter then
					linesiter = assert(io.lines(csvfile))
					local headline = linesiter()
					headinfo = string.explode(headline, ",")
					bookmakers = {}
					for i = 1, #headinfo do
						for _, bookinfo in ipairs(BOOKMAKERS) do
							if headinfo[i] == bookinfo.id.."H" then
								table.insert(bookmakers, {title=bookinfo.title, index = i})
							end
						end
					end
				end
			end
			if linesiter then
				matchline = linesiter()
				if not matchline then
					csvfile = nil
				else
					local matchinfo = string.explode(matchline, ",")
					if notempty(matchinfo[2]) and notempty(matchinfo[3]) and notempty(matchinfo[4]) and notempty(matchinfo[5]) and notempty(matchinfo[6]) then
						matchinfo.odds = {}
						for _, bm in ipairs(bookmakers) do
							if notempty(matchinfo[bm.index]) and notempty(matchinfo[bm.index+1]) and notempty(matchinfo[bm.index+2]) then
								table.insert(matchinfo.odds, {bookmaker=bm.title, website=bm.website, home=tonumber(matchinfo[bm.index]), draw=tonumber(matchinfo[bm.index+1]), away=tonumber(matchinfo[bm.index+2])})
							end
						end
						return matchinfo
					end
				end
			end
		end
	end
end

local function formatdate(date)
	local d, m, y = tonumber(string.sub(date, 1, 2)), tonumber(string.sub(date, 4, 5)), tonumber(string.sub(date, 7, 8))
	if y > 90 then
		y = y + 1900
	else
		y = y + 2000
	end
	return string.format("%04d-%02d-%02d", y, m, d)
end

return setmetatable(_M, {__call = function ()
	local lociter = table.elementiterator(LOCATIONS)
	local iter, citer, oddsiter, matchiter, matchinfo, locname, competition

	return function ()
		while true do
			if not oddsiter then
				if not matchiter then
					if not locname then
						locname = lociter()
						citer = nil
						if not locname then
							-- no more locations, exiting
							return nil
						end
					end
					if not competition then
						citer = citer or competitionsiterator(locname)
					end
					if citer then
						competition = citer()
						if not competition then
							locname = nil
						else
							matchiter = matchesiterator(locname, competition)
						end
					end
				else
					matchinfo = matchiter()
					if not matchinfo then
						matchiter = nil
						oddsiter = nil
					else
						if table.getn(matchinfo.odds) > 0 then
							oddsiter = table.elementiterator(matchinfo.odds)
						else
							return {
								provider = _NAME,
								match =
								{
									location = locname,
									competition = competition,
									team1 = matchinfo[3],
									team2 = matchinfo[4],
									goals1 = tonumber(matchinfo[5]),
									goals2 = tonumber(matchinfo[6]),
									date = formatdate(matchinfo[2])
								}
							}
						end
					end
				end
			else
				local odds = oddsiter()
				if not odds then
					oddsiter = nil
				else
					return {
						provider = _NAME,
						odds = {
							match =
							{
								location = locname,
								competition = competition,
								team1 = matchinfo[3],
								team2 = matchinfo[4],
								goals1 = tonumber(matchinfo[5]),
								goals2 = tonumber(matchinfo[6]),
								date = formatdate(matchinfo[2])
							},
							bookmaker = odds.bookmaker,
							website = odds.website,
							oddhome = odds.home,
							odddraw = odds.draw,
							oddaway = odds.away
						}
					}
				end
			end
		end
	end
end})
