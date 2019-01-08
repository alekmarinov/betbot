-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2010,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      titles.lua                                         --
-- Description:   Filter imported object titles                      --
--                                                                   --
-----------------------------------------------------------------------

local config      = require "lrun.util.config"
local table       = require "lrun.util.table"
local string      = require "lrun.util.string"
local log         = require "betbot.log" 
local lfs         = require "lrun.util.lfs"
local Bookmaker   = require "betbot.model.bookmaker"
local Location    = require "betbot.model.location"
local Competition = require "betbot.model.competition"
local Team        = require "betbot.model.team"
local Provider    = require "betbot.model.provider"
local Unicode     = require "unicode"
local utf8        = unicode.utf8 or unicode

local _G, setmetatable, assert, pairs, io =
      _G, setmetatable, assert, pairs, io

module "betbot.import.filter.titles"

_NAME = "titles"
_DESCRIPTION = "Map source titles to unified betbot representation"

local MAPFILENAMEFORMAT = "%s.%s.lua"

local sinks
sinks = {
	bookmaker = function (dbc, maps, object)
		if not Bookmaker.load(dbc, object.bookmaker) then
			local title = utf8.lower(object.bookmaker)
			title = maps.bookmaker[title]
			if not title or utf8.len(title) == 0 then
				-- skip this object, mark entry in map
				maps.bookmaker[title] = ""
				return nil
			end
			object.bookmaker = title
		end
		return object
	end,
	location = function (dbc, maps, title)
		if not Location.load(dbc, title) then
			title = utf8.lower(title)
			local mtitle = maps.location[title]
			if not mtitle or utf8.len(mtitle) == 0 then
				-- skip this object, mark entry in map
				maps.location[title] = ""
				return nil
			end
		end
		return title
	end,
	competition = function (dbc, maps, object)
		object.location = sinks.location(dbc, maps, object.location)
		local location = Location.load(dbc, object.location)
		if not location then
			-- skip competition without location
			return nil
		end
		if not Competition.load(dbc, object.competition, location) then
			local title = utf8.lower(object.competition)
			title = maps.competition[title]
			if not title or utf8.len(title) == 0 then
				-- skip this object, mark entry in map
				maps.competition[title] = ""
				return nil
			end
			object.competition = title
		end
		return object
	end,
	team = function (dbc, maps, object)
		object.location = sinks.location(dbc, maps, object.location)
		local location = Location.load(dbc, object.location)
		if not location then
			-- skip team without location
			return nil
		end
		if not Team.load(dbc, object.team, location) then
			local title = utf8.lower(object.team)
			title = maps.team[title]
			if not title or utf8.len(title) == 0 then
				-- skip this object, mark entry in map
				maps.team[title] = ""
				return nil
			end
			object.team = title
		end
		return object
	end,
	match = function (dbc, maps, object)
		local location = sinks.location(dbc, maps, object.location)
		if not location then
			-- skip match without location
			return nil
		end
		object.location = location
		if not sinks.competition(dbc, maps, object) then
			-- skip match without competition
			return nil
		end
		local teamobj = sinks.team(dbc, maps, setmetatable({team = object.team1}, {__index = object}))
		if not teamobj then
			-- skip match without team1
			return nil
		end
		object.team1 = teamobj.team
		teamobj = sinks.team(dbc, maps, setmetatable({team = object.team2}, {__index = object}))
		if not teamobj then
			-- skip match without team2
			return nil
		end
		object.team2 = teamobj.team
		return object
	end,
	odds = function (dbc, maps, object)
		local match = sinks.match(dbc, maps, object.match)
		if not match then
			-- skip odds without match
			return nil
		end
		return object
	end
}

-- load privider title mappings
local function loadmaps(providertitle)
	-- mapping tables
	local maps =
	{
		bookmaker = {},
		location = {},
		competition = {},
		team = {}
	}
	local dirmap = lfs.concatfilenames(config.get(_G._conf, "dir.map"), providertitle)
	if lfs.isdir(dirmap) then
		for name in pairs(maps) do
			local filename = lfs.concatfilenames(dirmap, string.format(MAPFILENAMEFORMAT, providertitle, name))
			if lfs.isfile(filename) then
				local file = io.open(filename, "r")
				local strteammap = file:read("*a")
				file:close()
				maps[name] = table.deserialize(strteammap)
			end
		end
	end
	return maps
end

-- save privider title mappings
local function savemaps(providertitle, maps)
	local ok, err
	local dirmap = config.get(_G._conf, "dir.map")
	if not lfs.isdir(dirmap) then
		ok, err = lfs.mkdir(dirmap)
		if not ok then
			return nil, err
		end
	end
	dirmap = lfs.concatfilenames(dirmap, providertitle)
	if not lfs.isdir(dirmap) then
		ok, err = lfs.mkdir(dirmap)
		if not ok then
			return nil, err
		end
	end
	for name, map in pairs(maps) do
		local filename = lfs.concatfilenames(dirmap, string.format(MAPFILENAMEFORMAT, providertitle, name))
		local mapstr = table.makestring(map)
		local file, err = io.open(filename, "w")
		if not file then
			return nil, err
		end
		ok, err = file:write(mapstr)
		if not ok then
			return nil, err
		end
		file:close()
	end
	return true
end

return setmetatable(_M, {__call = function (_, dbc)
	dbc = dbc or _G._dbc
	local providermaps = {}
	return function (chunk)
		if not chunk then
			-- end of stream, save maps
			for providertitle, maps in pairs(providermaps) do
				savemaps(providertitle, maps)
			end
			return nil
		end
		local provider = assert(Provider.load(dbc, chunk.provider))
		local providertitle = provider.title:lower()
		local maps = providermaps[providertitle]
		if not maps then
			-- maps not found, load existing or create new
			maps = loadmaps(providertitle)
			providermaps[providertitle] = maps
		end
		for t, v in pairs(chunk) do
			local k = t:lower()
			if k ~= "provider" then
				local ok, err = sinks[k](dbc, maps, v)
				if not ok then
					return nil, err
				end
				chunk[t] = ok
			end
		end
		return chunk
	end
end})
