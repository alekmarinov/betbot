-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2012,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      matchset.lua                                       --
-- Description:   matchset is source of matches                      --
--                                                                   --
-----------------------------------------------------------------------

local Models = {
	provider    = require "betbot.model.provider",
	bookmaker   = require "betbot.model.bookmaker",
	location    = require "betbot.model.location",
	competition = require "betbot.model.competition",
	team        = require "betbot.model.team"
}

local log         = require "betbot.log" 
local table       = require "lrun.util.table"
local string      = require "lrun.util.string"
local config      = require "lrun.util.config"
local sqlds       = require "lrun.model.datasrc.sql"

local _G, assert, type, tonumber, tostring, ipairs, pairs, unpack, setmetatable, math, string, io, os =
      _G, assert, type, tonumber, tostring, ipairs, pairs, unpack, setmetatable, math, string, io, os

local print = print

module "betbot.analysis.matchset"

_NAME = "matchset"
_DESCRIPTION = "Filtered source of matches"
__index = _M

local reserved =
{
	current_date = 1
}

function new(dbc)
	local o = {
		dbc = dbc
	}
	return setmetatable(o, _M)
end

function filterbytitles(self, name, titles)
	self.constraints = self.constraints or {}
	titles = string.explode(titles, ",")
	name = string.lower(string.trim(name))
	local models = {}
	for m in pairs(Models) do
		table.insert(models, m)
	end
	if not Models[name] then
		return nil, "name must be one of ["..table.concat(models, ",").."], but got `"..(name or "").."'"
	end
	if name == "location" then
		self.constraints.locations = self.constraints.locations or {}
		for _, title in ipairs(titles) do
			title = string.trim(title)
			local l = Models.location.load(self.dbc, title)
			if not l then
				return nil, "no such location `"..title.."'"
			end
			if not table.indexof(self.constraints.locations, l) then
				table.insert(self.constraints.locations, l)
			end
		end
	elseif name == "team" or name == "competition" then
		if not self.constraints.locations or #self.constraints.locations == 0 then
			return nil, "one or more locations must be defined before selecting "..name
		end
		local tabname
		if name == "team" then
			tabname = "teams"
		else
			tabname = "competitions"
		end
		self.constraints[tabname] = self.constraints[tabname] or {}
		for _, loc in ipairs(self.constraints.locations) do
			for _, title in ipairs(titles) do
				title = string.trim(title)
				local o = Models[name].load(self.dbc, title, loc.id)
				if o and not table.indexof(self.constraints[tabname], o) then
					table.insert(self.constraints[tabname], o)
				end
			end
		end
	else
		self.constraints[name.."s"] = self.constraints[name.."s"] or {}
		for _, title in ipairs(titles) do
			title = string.trim(title)
			local o = Models[name].load(self.dbc, title)
			if not o then
				return nil, "no such "..name.." `"..title.."'"
			end
			if not table.indexof(self.constraints[name.."s"], o) then
				table.insert(self.constraints[name.."s"], o)
			end
		end
	end
	return true
end

local function tosqlvar(name)
	local TSQLMAP =
	{
		provider = "p",
		bookmaker = "b",
		location = "l",
		competition = "c",
		match = "m",
		odds = "o"
	}
	local composite = string.explode(name, ".")
	if #composite ~= 2 then
		return nil, "name must have the form Table.attribute, but got `"..(name or "").."'"
	end
	name = composite[1]
	name = string.lower(string.trim(name))
	if not TSQLMAP[name] then
		local tabs = {}
		for t in pairs(TSQLMAP) do
			table.insert(tabs, t)
		end
		return nil, "Table must be any of ["..table.concat(tabs, ",").."], but got "..name
	end
	return TSQLMAP[name], string.trim(composite[2])
end

function filterbyoperator(self, name, operator, value)
	self.constraints = self.constraints or {}
	self.constraints.operations = self.constraints.operations or {}
	value = string.trim(value)
	local attr
	name, attr = tosqlvar(name)
	if not name then
		return nil, attr
	end

	table.insert(self.constraints.operations, {
		name = name,
		attribute = attr,
		operator = operator,
		value = value
	})
	return true
end

function filterbyconstraints(self, constraints)
	assert(type(constraints) == "string", "expected string, got "..type(constraints))

	-- Provider:football_data;Location:England;Competition:Premier League;Team:Arsenal,Liverpool;Match.date>2000-01-01
	constraints = string.explode(constraints, ";")
	local ok, err
	for _, constraint in ipairs(constraints) do
		constraint = string.trim(constraint)
		if string.len(constraint) > 0 then
			local parts = string.explode(constraint, ":")
			if #parts == 1 then
				local operator = ">="
				parts = string.explode(constraint, operator)
				if #parts == 1 then
					operator = "<="
					parts = string.explode(constraint, operator)
					if #parts == 1 then
						operator = ">"
						parts = string.explode(constraint, operator)
						if #parts == 1 then
							operator = "<"
							parts = string.explode(constraint, operator)
						end
					end
				end
				if #parts ~= 2 then
					return nil, "operator not found in constraint `"..constraint.."', supported only >=,<=,>,<,:"
				end
				ok, err = self:filterbyoperator(parts[1], operator, parts[2])
				if not ok then
					return nil, err
				end
			elseif #parts == 2 then
				ok, err = self:filterbytitles(unpack(parts))
				if not ok then
					return nil, err
				end
			else
				return nil, "No more than 2 constraint element supported divided by column (:), got "..table.getn(parts)
			end
		end
	end
	if not ok then
		return nil, "constraints not found in expression `"..constraints.."'"
	end
	return true
end

function limit(self, limit1, limit2)
	self.constraints.limit1 = limit1
	self.constraints.limit2 = limit2
end

function orderby(self, orderby)
	local name, attr = tosqlvar(orderby)
	if not name then
		return nil, attr
	end
	self.constraints.orderby = name.."."..attr
	return true
end

function getsql(self, iscount)
	-- return true if an array have one or more elements
	local function haselements(array)
		return array and #array > 0
	end

	--- return table with object ids
	local function objectsid(objects)
		local ids = {}
		for _, o in ipairs(objects) do
			table.insert(ids, o.id)
		end
		return ids
	end

	--- quote string
	function Q(arg)
		assert(type(arg) == "string")
		if reserved[arg] then
			return arg
		end

		return "'" .. arg:gsub("'", "''") .. "'"
	end

	local selections, joins, constraints = {}, {}, {}
	
	table.insert(joins, "LEFT JOIN Match m ON m.id = o.matchID")
	table.insert(joins, "LEFT JOIN Bookmaker b ON b.id = o.bookmakerID")
	table.insert(joins, "LEFT JOIN Team t1 ON t1.id = m.team1ID")
	table.insert(joins, "LEFT JOIN Team t2 ON t2.id = m.team2ID")
	table.insert(selections, "m.date")
	table.insert(selections, "m.goals1")
	table.insert(selections, "m.goals2")
	table.insert(selections, "o.home")
	table.insert(selections, "o.draw")
	table.insert(selections, "o.away")
	table.insert(selections, "b.title AS bookmaker")
	table.insert(selections, "b.id AS bookmakerID")
	table.insert(selections, "t1.id AS team1ID")
	table.insert(selections, "t2.id AS team2ID")
	table.insert(selections, "t1.title AS team1")
	table.insert(selections, "t2.title AS team2")

	if haselements(self.constraints.providers) then
		local providers = objectsid(self.constraints.providers)
		if #providers > 1 then
			table.insert(constraints, "p.id IN ("..table.concat(providers, ",")..")")
		else
			table.insert(constraints, "p.id = "..providers[1])
		end

		table.insert(joins, "LEFT JOIN Provider p ON p.id = o.providerID")
	end

	if haselements(self.constraints.bookmakers) then
		local bookmakers = objectsid(self.constraints.bookmakers)
		if #bookmakers > 1 then
			table.insert(constraints, "b.id IN ("..table.concat(bookmakers, ",")..")")
		else
			table.insert(constraints, "b.id = "..bookmakers[1])
		end
	end
	
	if haselements(self.constraints.locations) then
		local locations = objectsid(self.constraints.locations)
		if #locations > 1 then
			table.insert(constraints, "l.id IN ("..table.concat(locations, ",")..")")
		else
			table.insert(constraints, "l.id = "..locations[1])
		end
		table.insert(joins, "LEFT JOIN Location l ON l.id = c.locationID")
		table.insert(selections, "l.title AS location")
	end

	if haselements(self.constraints.competitions) then
		local competitions = objectsid(self.constraints.competitions)
		if #competitions > 1 then
			table.insert(constraints, "c.id IN ("..table.concat(competitions, ",")..")")
		else
			table.insert(constraints, "c.id = "..competitions[1])
		end
		table.insert(joins, "LEFT JOIN Competition c ON c.id = m.competitionID")
		table.insert(selections, "c.title AS compatition")
		table.insert(selections, "c.id AS compatitionID")
	end

	if haselements(self.constraints.teams) then
		local teams = objectsid(self.constraints.teams)
		table.insert(constraints, "t1.id IN ("..table.concat(teams, ",")..")")
		table.insert(constraints, "t2.id IN ("..table.concat(teams, ",")..")")
	end

	local select
	if iscount then
		select = "COUNT(*) AS cnt"
	else
		select = table.concat(selections, ",\n\t")
	end
	local sql = "SELECT\n\t"..select.."\nFROM Odds o\n\t"..table.concat(joins, "\n\t").."\nWHERE\n\t"..table.concat(constraints, " AND\n\t")

	if self.constraints.operations then
		for _, operation in ipairs(self.constraints.operations) do
			sql = sql.." AND\n\t"..operation.name.."."..operation.attribute.." "..operation.operator.." "..Q(operation.value)
		end
	end

	if self.constraints.orderby then
		sql = sql.."\nORDER BY "..self.constraints.orderby
	end

	if self.constraints.limit1 then
		sql = sql.."\nLIMIT "..self.constraints.limit1
	end

	if self.constraints.limit2 then
		sql = sql.." ,"..self.constraints.limit2
	end
	return sql
end

function source(self)
	return sqlds.new(self.dbc, self:getsql()):source()
end

function count(self)
	return tonumber(sqlds.new(self.dbc, self:getsql(true)):once().cnt)
end

return _M
