-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2010,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      soccerstand.lua.lua                                --
-- Description:   soccerstand source of matches                      --
--                                                                   --
-----------------------------------------------------------------------

local downloader  = require "betbot.import.method.download"
local log         = require "betbot.log" 
local table       = require "lrun.util.table"

local assert, type, tonumber, tostring, ipairs, pairs, setmetatable, math, string, io =
      assert, type, tonumber, tostring, ipairs, pairs, setmetatable, math, string, io

module "betbot.import.provider.soccerstand.source"

_NAME = "soccerstand"
_DESCRIPTION = "Source for match results from www.soccerstand.com"

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

local function locationsiterator()
	local html = downloader.download("http://www.soccerstand.com/soccer/en/all/live", showprogress)
	return string.gfind(html, "<a href=\"/soccer/results/country/(%d+)/(.-)\">")
end

local function competitionsiterator(locid, locname)
	local function getmastercompets(s)
		local compets = {}
		string.gsub(s, "<option value=\"(%d+)\"", function (id)
			table.insert(compets, id)
		end)
		return compets
	end

	local function getyears(s)
		local years = {}
		string.gsub(s, "<option value=\"(%d+)\"", function (id)
			table.insert(years, id)
		end)
		return years
	end

	local function getcompets(s)
		local compets = {}
		string.gsub(s, "<option value=\"(%d+)\"[^>]*>(.-)</option>", function (id, name)
			table.insert(compets, {name = name, id = id})
		end)
		return compets
	end

	local function getselects(html)
		local selects = {}
		string.gsub(html, "<select(.-)</select>", function (s)
			table.insert(selects, s)
		end)
		assert(#selects == 4)		
		return selects
	end

	local html = downloader.download(string.format("http://www.soccerstand.com/soccer/en/results/country/%s/%s", locid, locname), showprogress)
	local selects = getselects(html)

	local competmapids = {}
	local masterids = getmastercompets(selects[2])
	-- for each master competition, get years
	for _, mid in ipairs(masterids) do
		html = downloader.download(string.format("http://www.soccerstand.com/soccer/en/results/country/%s/%s/%s", locid, locname, mid), showprogress)
		selects = getselects(html)
		local yearsids = getyears(selects[3])

		-- for each year get competitions
		for _, yid in ipairs(yearsids) do
			html = downloader.download(string.format("http://www.soccerstand.com/soccer/en/results/country/%s/%s/%s/%s", locid, locname, mid, yid), showprogress)
			local selects = getselects(html)
			local competsids = getcompets(selects[4])
			for _, cid in ipairs(competsids) do
				competmapids[cid.name] = competmapids[cid.name] or {}
				table.insert(competmapids[cid.name], table.concat({mid, yid, cid.id}, "/"))
			end
		end
	end

	local competitions = {}
	for name, ids in pairs(competmapids) do
		table.insert(competitions, { name = name, ids = ids} )
	end
	return table.elementiterator(competitions)
end

return setmetatable(_M, {__call = function ()
	local lociter, iter, citer, iditer, locid, locname, competition
	
	return function ()
		lociter = locationsiterator()
		while true do
			if not iter then
				if not iditer then
					if not citer then
						locid, locname = lociter()
						if not locid then
							return nil
						end
						citer = competitionsiterator(locid, locname)
					end
					competition = citer()
					if not competition then
						citer = nil
					else
						iditer = table.elementiterator(competition.ids)
					end
				else
					local id = iditer()
					if not id then
						iditer = nil
					else
						local html, err = downloader.download("http://www.soccerstand.com/soccer/en/results/country/"..locid.."/"..locname.."/"..id, showprogress)
						if not html then
							return nil, err
						end
						iter = string.gfind(html, "(<td class=\"tcenter\">%d+%-%d+%-%d+ %d+:%d+</td>.-</tr>)")
					end
				end
			else
				local mstr = iter()
				if not mstr then
					iter = nil
				else
					local rows = {}
					string.gsub(mstr, "<td(.-)</td>", function (s)
						table.insert(rows, s)
					end)

					local matchinfo = {}

					string.gsub(rows[1], "(%d+%-%d+%-%d+ %d+:%d+)", function (datetime)
						matchinfo.date = datetime
					end)

					string.gsub(rows[5], ">(.*)", function (r)
						string.gsub(r, "(%d+)%-(%d+)", function (g1, g2)
							matchinfo.goals1 = tonumber(g1)
							matchinfo.goals2 = tonumber(g2)
						end)
					end)

					if matchinfo.goals1 and matchinfo.goals2 then
						string.gsub(rows[4], ">(.*)", function (t1)
							matchinfo.team1 = t1
						end)
						string.gsub(rows[7], ">(.*)", function (t2)
							matchinfo.team2 = t2
						end)
					else
						string.gsub(rows[3], ">(.*)", function (t1)
							matchinfo.team1 = t1
						end)
						string.gsub(rows[4], ">(.*)", function (t2)
							matchinfo.team2 = t2
						end)
						matchinfo.goals1 = -1
						matchinfo.goals2 = -1
					end

					if matchinfo.date and matchinfo.team1 and matchinfo.team2 then
						return {
							provider = _NAME,
							match = {
								location = locname,
								competition = competition.name,
								team1 = matchinfo.team1,
								team2 = matchinfo.team2,
								goals1 = matchinfo.goals1,
								goals2 = matchinfo.goals2,
								date = matchinfo.date,
							}
						}
					end
				end
			end
		end
	end
end})
