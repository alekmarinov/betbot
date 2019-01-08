-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2012,  AVIQ Bulgaria Ltd                       --
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

module ("betbot.nnet.trainer", package.seeall)

NEPOCHS = 100000
MAKEDESCRIPTIONFILE = true

function addsource(self, source)
	for match in source do
		local ok, err = self:addmatch(match)
		if not ok then
			return nil, err
		end
	end
	return true
end

-- match ~ {team1ID=number, team2ID=number, oddhome=number, odddraw=number, oddaway=number, goals1=number, goals2=number}
function addmatch(self, match)
	-- FIXME: validate match table
	table.insert(self.traindata, match)
	log.debug("training "..(match.team1 or match.team1ID).." vs "..(match.team2 or match.team2ID).." "..match.goals1..":"..match.goals2.." odds ("..match.home..", "..match.draw..", "..match.away..")")
	return true
end

-- test help message
function train(self, nepochs)
	local function normalizeodds(h, d, a)
		h = tonumber(h)
		d = tonumber(d)
		a = tonumber(a)
		local sum = h + d + a
		return {a / sum, d / sum, h / sum}
	end

	nepochs = nepochs or NEPOCHS

	-- extract all distinct teams from the matchset
	local teammap = {}
	local teamsarray = {}
	for _, match in ipairs(self.traindata) do
		local id = tonumber(match.team1ID)
		if not teammap[id] then
			teammap[id] = true
			table.insert(teamsarray, tonumber(id))
		end
	end

	-- creates destination directory
	if string.len(self.destdir or "") > 0 then
		lfs.mkdir(self.destdir)
	end

	-- generate training file
	log.info("Training with "..table.getn(self.traindata).." matches and "..table.getn(teamsarray).." teams")
	self.trainfilename = lfs.concatfilenames(self.destdir, self.trainsetname..".train")
	local file, err = assert(io.open(self.trainfilename, "w"))
	if not file then
		return nil, err
	end
	self.logfilename = lfs.concatfilenames(self.destdir, self.trainsetname..".log")
	local logfile, err = assert(io.open(self.logfilename, "w"))
	if not logfile then
		return nil, err
	end

	file:write(table.getn(self.traindata).." "..(3 + table.getn(teamsarray)).." 1\n") -- or 3
	for _, match in ipairs(self.traindata) do
		logfile:write((match.date and match.date..": " or "")..(match.team1 or match.team1ID).." vs "..(match.team2 or match.team2ID).." "..match.goals1..":"..match.goals2.." odds ("..match.home..", "..match.draw..", "..match.away..")\n")

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
		
		--[[if match.goals1 > match.goals2 then
			file:write("1 0 0")
		elseif match.goals1 < match.goals2 then
			file:write("0 0 1")
		else
			file:write("0 1 0")
		end
		--]]
		---[[
		if match.goals1 > match.goals2 then
			file:write(1)
		elseif match.goals1 < match.goals2 then
			file:write(-1)
		else
			file:write(0)
		end
		---]]

		-- file:write(string.format("%d %d", match.goals1, match.goals2))

		-- file:write(match.goals1 - match.goals2)
		file:write("\n")
	end
	logfile:close()
	file:close()

	-- start training
	self.netfilename = lfs.concatfilenames(self.destdir, self.trainsetname..".net")
	if lfs.exists(self.netfilename) then
		log.warn(self.netfilename.." already exists. Skipping.")
	else
		local ninp = 3 + table.getn(teamsarray)
		local net = fann.Net.create_standard{ninp, ninp, 1} -- or 3

		-- Configure the activation function
		net:set_activation_function_hidden(fann.SIGMOID_SYMMETRIC)
		net:set_activation_function_output(fann.SIGMOID_SYMMETRIC)

		-- Configure other parameters
		net:set_training_algorithm(fann.TRAIN_RPROP)

		-- Train the net from a file
		net:train_on_file(self.trainfilename, nepochs, 50, 0.01)

		-- Save the net to a file for a latter execution 
		net:save(self.netfilename)
	end

	if MAKEDESCRIPTIONFILE then
		self.descfilename = lfs.concatfilenames(self.destdir, self.trainsetname..".txt")
		local file, err = assert(io.open(self.descfilename, "w"))
		if not file then
			return nil, err
		end
		file:write(string.format("training set = %s\n", self.trainsetname))
		file:write(string.format("trained on %s\n", os.date()))
		file:write(string.format("data count = %d\n", #self.traindata))
		file:write(string.format("train file = %s\n", self.trainfilename))
		file:write(string.format("NN file = %s\n", self.netfilename))
		file:close()
	end
	return true
end

function new(trainsetname, destdir)
	return setmetatable({
		traindata = {},
		trainsetname = trainsetname,
		destdir = destdir or ""
		}, {__index=_M})
end
