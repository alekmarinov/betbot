-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2009,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      match.lua                                          --
-- Description:   Match class definition                             --
--                                                                   --
-----------------------------------------------------------------------

local om          = require "lrun.model.om"
local sqlds       = require "lrun.model.datasrc.sql"
local sqlgens     = require "lrun.model.schema.sqlgen.all"
local log         = require "betbot.log" 
local Team        = require "betbot.model.team"
local Bookmaker   = require "betbot.model.bookmaker"
local Competition = require "betbot.model.competition"
local Provider    = require "betbot.model.provider" 

module ("betbot.model.match", package.seeall)

local function isdate(s) return string.match(s, "%d%d%d%d%-%d%d%-%d%d") end

OM =
{
	{"id", "optional", "number"},
	{"date", "required", "string", isdate},
	{"competition", "required", Competition.OM},
	{"team1", "required", Team.OM},
	{"team2", "required", Team.OM},
	{"goals1", "required", "number"},
	{"goals2", "required", "number"},
	{"provider", "required", Provider.OM},
}

DBMAP =
{
	{"competition", "competitionID", function(c) return c.id end},
	{"team1", "team1ID", function(t) return t.id end},
	{"team2", "team2ID", function(t) return t.id end},
	{"provider", "providerID", function(t) return t.id end},
}

__index = _M

-- creates new match object
function new(match)
	om.validate(OM, match)
	return setmetatable(match, _M)
end

-- compares two match objects
function __eq(m1, m2)
	return om.compare(OM, m1, m2, {"id", "odds"}) == 0
end

local function getteam(dbc, teamdef)
	if type(teamdef) == "table" then
		return teamdef
	else
		assert(type(teamdef) == "string" or type(teamdef) == "number")
		return Team.load(dbc, teamdef)
	end
end

function getteamsbycompetition(dbc, comp)
	local compid
	if type(comp) == "number" then
		compid = comp
	elseif type(comp) == "string" then
		compid = assert(Competition.load(dbc, comp)).id
	else
		compid = comp.id
	end
	local teammap = {}
	local teams = {}
	-- extract all distinct teams from current competition
	local sql = "SELECT m.team1ID AS id FROM match m LEFT JOIN Team t ON t.id = m.team1ID WHERE competitionid = "..compid.." ORDER BY t.title"
	for row in assert(sqlds.new(dbc, sql):source()) do
		local id = tonumber(row.id)
		if not teammap[id] then
			teammap[id] = true
			table.insert(teams, id)
		end
	end
	return teams
end

-- load match by date, team1, team2
function load(dbc, team1, team2, date)
	team1 = getteam(dbc, team1)
	team2 = getteam(dbc, team2)
	local bydate = date and ("date(m.date) = date('"..date.."') AND ") or ""
	local result = {}
	local row = sqlds.new(dbc, "SELECT m.* FROM Match m WHERE "..bydate.."m.team1ID = "..team1.id.." AND m.team2ID = "..team2.id):once()
	if row then
		row.id = tonumber(row.id)
		row.team1 = team1
		row.team2 = team2
		row.competition = Competition.load(dbc, tonumber(row.competitionID))
		row.provider = Provider.load(dbc, tonumber(row.providerID))
		return new(row)
	end
end

-- save match to DB
function save(self, dbc)
	local sqlgen = sqlgens[dbc.driver]:new()
	local match = load(dbc, self.team1, self.team2, self.date)
	if match then
		self.id = match.id
		if self == match then
			return self
		else
			-- update match
			match = om.new(OM, self)
			om.map(DBMAP, match)
			sqlgen:updateobject("Match", match)
			log.sql(tostring(sqlgen))
			assert(sqlgen:execute(dbc))
		end
	else
		-- insert new match
		match = om.new(OM, self)
		om.map(DBMAP, match)
		sqlgen:insertobject("Match", match)
		log.sql(tostring(sqlgen))
		assert(sqlgen:execute(dbc))
		row = sqlds.new(dbc, "SELECT MAX(id) as 'id' FROM Match"):once()
		self.id = tonumber(row.id)
	end
	return self
end

function getallmatches(dbc, team1, team2)
	if not team1 then
		team1 = team2
		team2 = nil
	end
	assert(team1)
	if type(team1) == "string" then
		team1 = team.load(dbc, team1)
	end
	if type(team2) == "string" then
		team2 = team.load(dbc, team2)
	end

	local matches = {}
	local sql
	if team1 and team2 then
		sql = "SELECT m.date, t1.title AS 'team1', t2.title AS 'team2' FROM Match m LEFT JOIN Team t1 ON t1.id = m.team1ID LEFT JOIN Team t2 ON t2.id = m.team2ID WHERE (team1ID = "..team1.id.." AND team2ID = "..team2.id..") OR "..
			"(team1ID = "..team2.id.." AND team2ID = "..team1.id..") ORDER BY m.date DESC"
	else
		sql = "SELECT m.date, t1.title AS 'team1', t2.title AS 'team2' FROM Match m LEFT JOIN Team t1 ON t1.id = m.team1ID LEFT JOIN Team t2 ON t2.id = m.team2ID WHERE team1ID = "..team1.id.." OR team2ID = "..team1.id.." ORDER BY m.date DESC"
	end
	for row in sqlds.new(dbc, sql):source() do
		table.insert(matches, load(dbc, row.team1, row.team2, row.date))
	end
	return matches
end

function getteamoponents(dbc, team)
	team = getteam(dbc, team)
	local teams = {}
	local inserted = {}
	for row in sqlds.new(dbc, "SELECT t1.title AS 'team1', t2.title AS 'team2' FROM Match m LEFT JOIN Team t1 ON t1.id == m.team1ID LEFT JOIN Team t2 ON t2.id == m.team2ID WHERE m.team1ID = "..team.id.." OR m.team2ID = "..team.id):source() do
		local title
		if row.team1 ~= team.title then
			title = row.team1
		else
			assert(row.team2 ~= team.title)
			title = row.team2
		end
		if not inserted[title] then
			table.insert(teams, title)
		end
		inserted[title] = true
	end
	table.sort(teams)
	return teams
end

function getlastmatchdate(dbc)
	local row = sqlds.new(dbc, "SELECT MAX(date) AS date FROM match"):once()
	if row then
		return row.date
	end
end

function __tostring(self)
	return self.title
end

return _M
