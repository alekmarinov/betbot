-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2010,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      smarterbetting.lua                                 --
-- Description:   Export DB to smarterbetting.com format             --
--                                                                   --
-----------------------------------------------------------------------

local sqlds     = require "lrun.model.datasrc.sql"

module ("betbot.export", package.seeall)

local function xmlesc(s)
	s = string.gsub(s, "&", "&amp;")
	return s
end

function export(filename)
	assert(type(filename) == "string", "filename argument expected")
	local file = assert(io.open(filename, "w"))

	local function fprint(...)
		local value = table.concat({...}, "")
		file:write(value.."\n")
	end

fprint[[
<?xml version="1.0" encoding="utf-8" ?> 
<string xmlns="http://tempuri.org/">
  <bets>
    <football> 
]]

local total = 0
for row in assert(sqlds.new(_dbc, "SELECT COUNT(*) AS cnt FROM Match"):source()) do
	total = tonumber(row.cnt)
end

local current = 0
for match in assert(sqlds.new(_dbc, [[
SELECT
	m.id as id,
	l.title as location,
	c.title as competition,
	m.date,
	t1.title as team1,
	t2.title as team2,
	m.goals1,
	m.goals2
FROM
	Match m
		LEFT JOIN Team t1 ON t1.id = m.team1ID
		LEFT JOIN Team t2 ON t2.id = m.team2ID
		LEFT JOIN Competition c ON c.id = m.competitionID
		LEFT JOIN Location l ON l.id = c.locationID]]):source())
do
    fprint(string.format([[
	<match id="%s" location="%s" competition="%s" datetime="%s" home="%s" away="%s" homegoals="%s" awaygoals="%s">]],
		match.id, xmlesc(match.location), xmlesc(match.competition), match.date, xmlesc(match.team1), xmlesc(match.team2), match.goals1, match.goals2))
	
	for odd in assert(sqlds.new(_dbc, [[
SELECT
	odd.home, odd.draw, odd.away, b.title as bookmaker, b.website as website
FROM
	Odds odd LEFT JOIN Bookmaker b ON b.id = odd.bookmakerID
WHERE
	odd.matchid = ]]..match.id):source())
	do
	    fprint(string.format([[
		<outcome company="%s" website="%s" captureTime="%s">
		  <homeodd>%s</homeodd><drawodd>%s</drawodd><awayodd>%s</awayodd>
		</outcome>]], xmlesc(odd.bookmaker), xmlesc(odd.website), os.date(), odd.home, odd.draw, odd.away))
	end
    fprint([[
	</match>]])

	current = current + 1
	io.stderr:write(string.format("\r%d of %d matches exported (%d%%)      ", current, total, 100*current/total)) io.stderr:flush()
end

fprint[[
    </football> 
  </bets>
</string>
]]
	file:close()

	return true
end

return _M
