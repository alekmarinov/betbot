-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2010,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      importer.lua                                       --
-- Description:   Imports smarterbetting.com data to the local DB    --
--                                                                   --
-----------------------------------------------------------------------

local MatchOddsParser = require "betbot.import.provider.smarterbetting.matchoddsparser"
local webservice      = require "betbot.import.method.webservice"
local TitleMapper     = require "betbot.import.titlemapper"
local bookmaker       = require "betbot.model.bookmaker"
local location        = require "betbot.model.location"
local competition     = require "betbot.model.competition"
local team            = require "betbot.model.team"
local match           = require "betbot.model.match"
local odds            = require "betbot.model.odds"
local log             = require "betbot.log" 

module("betbot.import.provider.smarterbetting.importer", package.seeall)

_NAME = "smarterbetting"
_DESCRIPTION = "Imports recent data from www.smarterbetting.com"

-- TitleMapper instance
local titlemapper

-- URL to the web service
local WS_URL = "http://agent.smarterbetting.com/webservices/bookieagentservices.asmx"

-- Base URL
local WS_BASE_URL = "http://tempuri.org/"

-- web service functions
local function getbookmakers()
	local wsresult, err = webservice.call(WS_URL, WS_BASE_URL, "loadBetsSites")
	if not wsresult then
		return nil, err
	end
	local result = {}
	for i, bookmakerinfo in ipairs(wsresult) do
		local id = tonumber(bookmakerinfo[1][1])
		local name = bookmakerinfo[2][1]
		result[id] = name
	end
	return result
end

local function getlocations()
	local wsresult, err = webservice.call(WS_URL, WS_BASE_URL, "loadLocation")
	if not wsresult then
		return nil, err
	end
	local result = {}
	for i, locationinfo in ipairs(wsresult) do
		local id = tonumber(locationinfo[1][1])
		local name = locationinfo[2][1]
		result[id] = name
	end
	return result
end

local function getcompetitions(locationid)
	assert(type(locationid) == "number")

	local wsresult, err = webservice.call(WS_URL, WS_BASE_URL, "loadComByLocation", {strLocationID = locationid})
	if not wsresult then
		return nil, err
	end
	local result = {}
	for i, competinfo in ipairs(wsresult) do
		local id = tonumber(competinfo[1][1])
		local name = competinfo[2][1]
		result[id] = name
	end
	return result
end

local function getteams(locationid)
	assert(type(locationid) == "number")

	local wsresult, err = webservice.call(WS_URL, WS_BASE_URL, "loadTeamsByLocation", {locationID = locationid})
	if not wsresult then
		return nil, err
	end
	local result = {}
	for i, teaminfo in ipairs(wsresult) do
		local id = tonumber(teaminfo[1][1])
		local name = teaminfo[2][1]
		result[id] = name
	end
	return result
end

local function getmatchodds()
	local wsresult, err = webservice.call(WS_URL, WS_BASE_URL, "getBookieBrainXML")
	if not wsresult then
		return nil, err
	end
	return MatchOddsParser.parse(wsresult[1])
end

-- importing functions
local function importbookmakers()
	local bookmakers, err = getbookmakers()
	if not bookmakers then
		return nil, err
	end
	local result = {}
	local stats = {saved = 0, unmapped = 0}
	for id, title in pairs(bookmakers) do
		title = titlemapper:mapbookmaker(title)
		if title then
			local bookie = bookmaker.load(_dbc, title)
			if not bookie then
				bookie = bookmaker.new{title = title, website = "<unknown>"}
				bookie:save(_dbc)
				stats.saved = stats.saved + 1
			end
			result[id] = bookie
		else
			stats.unmapped = stats.unmapped + 1
		end
	end
	return result, stats
end

local function importlocations()
	local locations, err = getlocations()
	if not locations then
		return nil, err
	end
	local result = {}
	local stats = {saved = 0, unmapped = 0}
	for id, title in pairs(locations) do
		title = titlemapper:maplocation(title)
		if title then
			local loc = location.load(_dbc, title)
			if not loc then
				loc = location.new{title = title}
				loc:save(_dbc)
				stats.saved = stats.saved + 1
			end
			result[id] = loc
		else
			stats.unmapped = stats.unmapped + 1
		end
	end
	return result, stats
end

local function importcompetitions(locations)
	local result = {}
	local stats = {saved = 0, unmapped = 0}
	for lid, loc in pairs(locations) do
		local competitions, err = getcompetitions(lid)
		if not competitions then
			return nil, err
		end
		result[loc.title] = result[loc.title] or {}
		for id, title in pairs(competitions) do
			title = titlemapper:mapcompetition(title, loc.title)
			if title then
				local compet = competition.load(_dbc, title, loc.title)
				if not compet then
					compet = competition.new{title = title, location = loc}
					compet:save(_dbc)
					stats.saved = stats.saved + 1
				end
				result[loc.title][id] = compet
			else
				stats.unmapped = stats.unmapped + 1
			end
		end
	end
	return result, stats
end

local function importteams(locations)
	local result = {}
	local stats = {saved = 0, unmapped = 0}
	for lid, loc in pairs(locations) do
		local teams, err = getteams(lid)
		if not teams then
			return nil, err
		end
		result[loc.title] = result[loc.title] or {}
		for id, title in pairs(teams) do
			title = titlemapper:mapteam(title, loc.title)
			if title then
				local tm = team.load(_dbc, title)
				if not tm then
					tm = team.new{title = title}
					tm:save(_dbc)
					stats.saved = stats.saved + 1
				end
				result[loc.title][id] = tm
			else
				stats.unmapped = stats.unmapped + 1
			end
		end
	end
	return result, stats
end

local function importmatchodds()
	local function loadbookmaker(title)
		title = titlemapper:mapbookmaker(title)
		if title then
			return bookmaker.load(_dbc, title)
		end
	end
	local function loadlocation(title)
		title = titlemapper:maplocation(title)
		if title then			
			return location.load(_dbc, title)
		end
	end
	local function loadcompetition(title, locationtitle)
		title = titlemapper:mapcompetition(title, locationtitle)
		if title then
			locationtitle = titlemapper:maplocation(locationtitle)
			if locationtitle then
				return competition.load(_dbc, title, loadlocation(locationtitle))
			end
		end
	end
	local function loadteam(title, locationtitle)
		title = titlemapper:mapteam(title, locationtitle)
		if title then
			return team.load(_dbc, title)
		end
	end
	local matchodds, err = getmatchodds()
	if not matchodds then
		return nil, err
	end
	local result = {}
	local stats = {saved = 0, unmapped = 0}
	for i, matchinfo in ipairs(matchodds) do
		stats.unmapped = stats.unmapped + 1
		local loc = loadlocation(matchinfo.location)
		if loc then
			local compet = loadcompetition(matchinfo.competition, loc.title)
			if compet then
				local team1 = loadteam(matchinfo.team1, loc.title)
				local team2 = loadteam(matchinfo.team2, loc.title)
				if team1 and team2 then
					local matchobj = match.new{
						date = matchinfo.date,
						competition = compet,
						team1 = team1,
						team2 = team2,
						goals1 = -1,
						goals2 = -1,
						odds = {}
					}

					-- iterate through match bookmakers odds
					for _, outcome in ipairs(matchinfo) do
						local bookie = loadbookmaker(outcome.company)
						if bookie then
							if bookie.website ~= outcome.website then
								-- update bookmaker's web site
								bookie.website = outcome.website
								bookie:save(_dbc)
							end
							local odd = odds.new{
								bookmaker = bookie,
								match = matchobj,
								home = outcome.oddhome,
								draw = outcome.odddraw,
								away = outcome.oddaway,
							}
							table.insert(matchobj.odds, odd)
						end
					end

					-- update match object
					local status = matchobj:save(_dbc)
					if status then
						stats.saved = stats.saved + 1
						stats.unmapped = stats.unmapped - 1
						if status == "insert" then
							status = "Adding"
						else
							status = "Updating"
						end
						log.info(status.." "..compet.location.title.."/"..compet.title..": "..matchobj.team1.title.." vs "..matchobj.team2.title.." "..matchobj.goals1..":"..matchobj.goals2.." with "..(#matchobj.odds).." bookmaker odds")
					end
					table.insert(result, matchobj)
				end
			end
		end
	end
	return result, stats
end

local function logimportstats(name, stats)
	log.info("Imported "..stats.saved.." "..name.." ("..stats.unmapped.." unmapped)")
end

function import(wantstr)
	wantstr = wantstr or "bookmakers,locations,competitions,teams,matches"
	local want = {}
	string.gsub(wantstr..",", "([^,]*),", function (w)
		want[w:lower()] = true
	end)

	titlemapper = TitleMapper.new(_NAME)
	local ok, err, stats

	if want.bookmakers then
		-- import match bookmakers
		ok, err = importbookmakers()
		if not ok then
			log.warn("Problems in importbookmakers:"..err)
		else
			stats = err
			logimportstats("bookmakers", stats)
		end
	end

	local locations
	if want.locations or want.competitions or want.teams then
		-- import match locations
		locations, err = importlocations()
		if not locations then
			log.warn("Problems in importlocations:"..err)
		else
			stats = err
			logimportstats("locations", stats)
		end
	end

	if want.competitions then
		-- import match competitions
		local ok, err = importcompetitions(locations)
		if not ok then
			log.warn("Problems in importcompetitions:"..err)
		else
			stats = err
			logimportstats("competitions", stats)
		end
	end

	if want.teams then		
		-- import match teams
		local ok, err = importteams(locations)
		if not ok then
			log.warn("Problems in importteams:"..err)
		else
			stats = err
			logimportstats("teams", stats)
		end
	end

	if want.matches then
		-- import match odds
		ok, err = importmatchodds()
		if not ok then
			log.warn("Problems in importmatchodds:"..err)
		else
			stats = err
			logimportstats("matches", stats)
		end
	end

	titlemapper:save()
	return true
end
