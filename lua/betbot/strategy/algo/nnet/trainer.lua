-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2009,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      trainer.lua                                        --
-- Description:   NNet trainer                                       --
--                                                                   --
-----------------------------------------------------------------------

require("lfann")

local lfs         = require "lrun.util.lfs"
local string      = require "lrun.util.string"
local config      = require "lrun.util.config" 
local sqlds       = require "lrun.model.datasrc.sql"
local bookmaker   = require "betbot.model.bookmaker"
local competition = require "betbot.model.competition"
local matchset    = require "betbot.analysis.matchset"
local log         = require "betbot.log" 


module ("betbot.strategy.algo.nnet.trainer", package.seeall)

NEPOCHS = 100000

local BOOKMAKER = "Bet365"

local function gentraindata(matchsetname)
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

	-- extract all distinct teams from the matchset
	local teammap = {}
	local teamsarray = {}
	local matches = {}
	for match in matchsrc do
		local id = tonumber(match.team1ID)
		if not teammap[id] then
			teammap[id] = true
			table.insert(teamsarray, tonumber(id))
		end
		table.insert(matches, match)
		log.debug(match.date.." "..match.location.."/"..match.compatition.." "..match.team1.." "..match.goals1.."-"..match.goals2.." "..match.team2.." "..match.bookmaker.."("..match.home..","..match.draw..","..match.away..")")
	end
	-- generate training file
	log.info("Generating train file for "..table.getn(matches).." matches and "..table.getn(teamsarray).." teams")
	local trainfile = lfs.concatfilenames(config.get(_conf, "dir.nnet"), matchsetname)..".train"
	local file, err = assert(io.open(trainfile, "w"))
	if not file then
		return nil, err
	end
	file:write(table.getn(matches).." "..(3 + table.getn(teamsarray)).." 3\n")
	for _, match in ipairs(matches) do
		file:write(table.concat(normalizeodds(match.home, match.draw, match.away), " "))
		for _, id in ipairs(teamsarray) do
			if id == tonumber(match.team1ID) or id == tonumber(match.team2ID) then
				file:write(" 1")
			else
				file:write(" 0")
			end
		end
		file:write("\n")
		match.goals1 = tonumber(match.goals1)
		match.goals2 = tonumber(match.goals2)
		if match.goals1 > match.goals2 then
			file:write("1 0 0")
		elseif match.goals1 < match.goals2 then
			file:write("0 0 1")
		else
			file:write("0 1 0")
		end
		file:write("\n")
	end
	file:close()
	return true
end

function trainfile(inputfile, nepochs)
	assert(inputfile, ".train file expected")
	local outputfile = lfs.stripext(inputfile)..".net"
	if lfs.exists(outputfile) then
		log.warn(outputfile.." already exists. Skipping.")
	else
		local file, err = assert(io.open(inputfile, "r"))
		if not file then
			return nil, err
		end
		local count, inp, out = file:read("*n"), file:read("*n"), file:read("*n")
		file:close()

		local net = fann.Net.create_standard{inp, inp, 3}

		-- Configure the activation function
		net:set_activation_function_hidden(fann.SIGMOID_SYMMETRIC)
		net:set_activation_function_output(fann.SIGMOID_SYMMETRIC)

		-- Configure other parameters
		net:set_training_algorithm(fann.TRAIN_RPROP)

		-- Train the net from a file
		net:train_on_file(inputfile, nepochs or NEPOCHS, 50, 0.01)

		-- Save the net to a file for a latter execution 
		net:save(outputfile)
	end
	return true
end

function train(matchsetname, nepochs)
	local ok, err = gentraindata(matchsetname)
	if not ok then
		return nil, err
	end
	local dirdata = config.get(_conf, "dir.nnet")
	for filename in lfs.dir(dirdata, "file") do
		local ext = lfs.ext(filename)
		if ext == ".train" then
			ok, err = trainfile(lfs.concatfilenames(dirdata, filename), tonumber(nepochs))
			if not ok then
				return nil, err
			end
		end
	end
	return true
end
