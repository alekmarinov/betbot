-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2010,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      validator.lua                                      --
-- Description:   validator sink filter                              --
--                                                                   --
-----------------------------------------------------------------------

local table, pairs, assert, type, setmetatable =
      table, pairs, assert, type, setmetatable

module "betbot.import.filter.validator"

_NAME = "validator"
_DESCRIPTION = "Validates import stream data chunk"

local function asserttype(v, tname, name)
	name = name and name.." " or ""
	assert(type(v) == tname, name..tname.." expected, got "..type(v))
	return v
end

local function stringtype(v, name)
	return asserttype(v, "string", name)
end

local function numbertype(v, name)
	return asserttype(v, "number", name)
end

local function tabletype(v, name)
	return asserttype(v, "table", name)
end

local function competitiontype(v, category)
	if category then
		category = table.concat({category, "competition"}, ".")
	else
		category = "competition"
	end

	tabletype(v, category)
	stringtype(v.location, category..".location")
	stringtype(v.competition, category..".competition")
	return v
end

local function bookmakertype(v, category)
	if category then
		category = table.concat({category, "bookmaker"}, ".")
	else
		category = "bookmaker"
	end

	tabletype(v, category)
	stringtype(v.bookmaker, category..".bookmaker")
	stringtype(v.website, category..".website")
	return v
end

local function teamtype(v, category)
	if category then
		category = table.concat({category, "team"}, ".")
	else
		category = "team"
	end

	tabletype(v, category)
	stringtype(v.location, category..".location")
	stringtype(v.team, category..".team")
	return v
end

local function matchtype(v, category)
	if category then
		category = table.concat({category, "match"}, ".")
	else
		category = "match"
	end

	tabletype(v, category)
	stringtype(v.location, category..".location")
	stringtype(v.competition, category..".competition")
	stringtype(v.team1, category..".team1")
	stringtype(v.team2, category..".team2")
	numbertype(v.goals1, category..".goals1")
	numbertype(v.goals2, category..".goals2")
	stringtype(v.date, category..".date")
	return v
end

local function oddstype(v, category)
	if category then
		category = table.concat({category, "odds"}, ".")
	else
		category = "odds"
	end

	matchtype(v.match, category)
	stringtype(v.bookmaker, category..".bookmaker")
	numbertype(v.oddhome, category..".oddhome")
	numbertype(v.odddraw, category..".odddraw")
	numbertype(v.oddaway, category..".oddaway")
	return v
end

return setmetatable(_M, {__call = function ()
	return function (chunk)
		if not chunk then
			return nil
		end
		stringtype(chunk.provider, "chunk.provider")
		for t, v in pairs(tabletype(chunk, "chunk")) do
			t = stringtype(t):lower()
			if t == "location" then
				stringtype(v, "chunk["..t.."]")
			elseif t == "competition" then
				competitiontype(v)
			elseif t == "bookmaker" then
				bookmakertype(v)
			elseif t == "team" then
				teamtype(v)
			elseif t == "match" then
				matchtype(v)
			elseif t == "odds" then
				oddstype(v)
			elseif t ~= "provider" then
				assert(nil, "chunk."..t.." is not allowed")
			end
		end
		return chunk
	end
end})
