-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2010,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      matchoddsparser.lua                                --
-- Description:   Parse XML returned by getBookieBrainXML            --
--                                                                   --
-----------------------------------------------------------------------

local lom = require "lxp.lom"

module ("betbot.import.provider.smarterbetting.matchoddsparser", package.seeall)

-----------------------------------------------------------------------
-- smarterbetting xml parser ------------------------------------------
-----------------------------------------------------------------------

local function istag(node, tag)
	return type(node) == "table" and type(node.attr) == "table" and string.lower(node.tag) == string.lower(tag)
end

local function val(s)
	return type(s) == "string" and s or assert(nil, "string value expected, got `"..type(s).."'")
end

local function numval(s)
	return assert(tonumber(val(s)), "Number expected, got "..s)
end

local function clr(dom)
	for i=#dom, 1, -1 do
		if type(dom[i]) == "string" then
			table.remove(dom, i)
		end
	end
end

local function parsedatetime(datastr)
	local Y, m, D, H, M, S
	local _ = datastr:sub(3, 3)
	if _ == "-" then
		-- parse date format as DD-mm-YYYY HH:MM:SS
		D = datastr:sub(1, 2)
		m = datastr:sub(4, 5)
		Y = datastr:sub(7, 10)
		H = datastr:sub(12, 13)
		M = datastr:sub(15, 16)
		S = datastr:sub(18, 19)
	else
		-- parse date format as YYYY-mm-DDTHH:MM:SS
		Y = datastr:sub(1, 4)
		m = datastr:sub(6, 7)
		D = datastr:sub(9, 10)
		H = datastr:sub(12, 13)
		M = datastr:sub(15, 16)
		S = datastr:sub(18, 19)
	end

	return Y.."-"..m.."-"..D.." "..H..":"..M..":"..S
end

local function parsedate(datastr)
	return parsedatetime(datastr):sub(1, string.len("YYYY-mm-DD"))
end

local function parseoutcome(dom)
	local outcome = {
		company = dom.attr.company,
		website = dom.attr.website,
		capturedatetime = parsedatetime(dom.attr.captureTime)
	}

	for i, node in ipairs(dom) do
		if istag(node, "homeodd") then
			outcome.oddhome = numval(node[1])
		elseif istag(node, "homeoddchange") then
			outcome.oddhomechg = val(node[1])
		elseif istag(node, "drawodd") then
			outcome.odddraw = numval(node[1])
		elseif istag(node, "drawoddchange") then
			outcome.odddrawchg = val(node[1])
		elseif istag(node, "awayodd") then
			outcome.oddaway = numval(node[1])
		elseif istag(node, "awayoddchange") then
			outcome.oddawaychg = val(node[1])
		end
	end

	return outcome
end

local function parsematch(dom)
	local match = {
		location = dom.attr.location,
		competition = dom.attr.competition,
		date = parsedate(dom.attr.datetime),
		team1 = dom.attr.home,
		team2 = dom.attr.away
	}
	for i, node in ipairs(dom) do
		if istag(node, "outcome") then
			clr(node)
			table.insert(match, parseoutcome(node))
		end
	end
	return match
end

local function parsefootball(dom)
	local matches = {}
	for i, node in ipairs(dom) do
		if istag(node, "match") then
			clr(node)
			table.insert(matches, parsematch(node))
		end
	end
	return matches
end

function parse(xml)
	local dom, err = lom.parse(xml)
	if not dom then
		return nil, err
	end

	clr(dom)
	-- dom - <bets>
	-- dom[1] - <football>
	return parsefootball(dom[1])
end

return _M
