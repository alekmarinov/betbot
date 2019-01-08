-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2012,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      predictor.lua                                      --
-- Description:   NNet based match exit predictor                    --
--                                                                   --
-----------------------------------------------------------------------

require "lfann"

local config      = require "lrun.util.config" 
local matchset    = require "betbot.analysis.matchset"
local log         = require "betbot.log" 

module ("betbot.nnet.predictor", package.seeall)

local function normalizeodds(h, d, a)
	h = tonumber(h)
	d = tonumber(d)
	a = tonumber(a)
	local sum = h + d + a
	return {a / sum, d / sum, h / sum}
end

function predict(self, team1, team2, oddhome, odddraw, oddaway)
	oddhome, odddraw, oddaway = tonumber(oddhome), tonumber(odddraw), tonumber(oddaway)

	-- extract all distinct teams from the matchset
	local teammap = {}
	local teamsarray = {}
	local team1ID, team2ID
	for _, match in ipairs(self.matches) do
		local id = tonumber(match.team1ID)
		if not teammap[id] then
			teammap[id] = true
			table.insert(teamsarray, tonumber(id))
		end
		if match.team1 == team1 then
			team1ID = id
		end
		if match.team2 == team2 then
			team2ID = id
		end
	end
	if not team1ID then
		return nil, "Can't find team `"..team1.."' in match set `"..self.matchsetconstraints.."'"
	end
	if not team2ID then
		return nil, "Can't find team `"..team2.."' in match set `"..self.matchsetconstraints.."'"
	end

	local inp = normalizeodds(oddhome, odddraw, oddaway)
	for i, id in ipairs(teamsarray) do
		if id == team1ID or id == team2ID then
			table.insert(inp, 1)
		else
			table.insert(inp, 0)
		end
	end
	local out, err = self.nnet:run(inp)
	if not out then
		return nil, err
	end

	return out
end

function new(dbc, nnetfile, matchsetconstraints)
	if not nnetfile then
		return nil, "required parameter nnetfile is missing"
	end
	if not matchsetconstraints then
		return nil, "required parameter matchsetconstraints is missing"
	end

	local ms = matchset.new(dbc)
	local ok, err = ms:filterbyconstraints(matchsetconstraints)
	if not ok then
		return nil, err
	end
	local matchsrc, err = ms:source()
	if not matchsrc then
		return nil, err
	end
	local o =
	{
		dbc = dbc,
		matchsetconstraints = matchsetconstraints,
		nnetfile = nnetfile,
		matches = {}
	}
	for match in matchsrc do
		table.insert(o.matches, match)
	end

	o.nnet, err = fann.Net.create_from_file(nnetfile)
	if not o.nnet then
		return nil, err
	end

	return setmetatable(o, {__index=_M})
end
