-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2010,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      predictor.lua                                      --
-- Description:   NNet based match result predictor                  --
--                                                                   --
-----------------------------------------------------------------------

require "lfann"
local config     = require "lrun.util.config" 
local string     = require "lrun.util.string" 
local match      = require "betbot.model.match" 
local matchset   = require "betbot.analysis.matchset"
local log        = require "betbot.log" 
local lfs        = require "lrun.util.lfs"

module ("betbot.strategy.algo.nnet.predictor", package.seeall)

function predict(matchsetname, team1, team2, oddhome, odddraw, oddaway)
	local function normalizeodds(h, d, a)
		h = tonumber(h)
		d = tonumber(d)
		a = tonumber(a)
		local sum = h + d + a
		return {a / sum, d / sum, h / sum}
	end
	local ms = matchset.new(_dbc)
	local matchsetconstraints = config.get(_conf, "analysis.matchset."..matchsetname)
	local ok, err = ms:filterbyconstraints(matchsetconstraints)
	if not ok then
		return nil, err
	end
	local matchsrc, err = ms:source()
	if not matchsrc then
		return nil, err
	end
	local dirdata = config.get(_conf, "dir.nnet")
	local netfile = lfs.concatfilenames(dirdata, matchsetname..".net")
	log.info("Loading neural network "..netfile)
	local nnet, err = fann.Net.create_from_file(netfile)
	if not nnet then
		return nil, err
	end

	-- extract all distinct teams from the matchset
	local teammap = {}
	local teamsarray = {}
	local team1ID, team2ID
	for match in matchsrc do
		local id = tonumber(match.team1ID)
		if not teammap[id] then
			teammap[id] = true
			table.insert(teamsarray, tonumber(id))
		end
		if match.team1 == team1 then
			team1ID = id
		elseif match.team2 == team2 then
			team2ID = id
		end
	end
	if not team1ID then
		return nil, "Can't find team `"..team1.."' in match set "..matchsetname
	end
	if not team2ID then
		return nil, "Can't find team `"..team2.."' in match set "..matchsetname
	end

	local inp = normalizeodds(oddhome, odddraw, oddaway)
	for i, id in ipairs(teamsarray) do
		if id == team1ID or id == team2ID then
			table.insert(inp, 1)
		else
			table.insert(inp, 0)
		end
	end
	local out, err = nnet:run(inp)
	if not out then
		return nil, err
	end

	return out
end
