-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2010,  AVIQ Systems AG                              --
--                                                                   --
-- Project:       LRun                                               --
-- Filename:      train.lua                                          --
-- Description:   Train match sets                                   --
--                                                                   --
-----------------------------------------------------------------------

require "lrun.stream.all"
local matchset = require "betbot.analysis.matchset"
local trainer  = require "betbot.nnet.trainer"
local config   = require "lrun.util.config"
local lfs      = require "lrun.util.lfs"
local log      = require "betbot.log"

local _G, lrun, print, tonumber, type, select, assert, setmetatable, os, table, string, pairs, ipairs, setfenv, loadstring =
      _G, lrun, print, tonumber, type, select, assert, setmetatable, os, table, string, pairs, ipairs, setfenv, loadstring

module "betbot.command.train"

_NAME = "train"
_DESCRIPTION = "Trains match set"
_HELP =
[[

SYNTAX: train [matchsetname] | test [matchsetname]

if matchsetname is not provided will train all existing matchsets config analysis.train.matchset.*
if matchsetname is "test" then will train all test training matchsets from config analysis.train.test.matchset.*

EXAMPLES:

	train
	train England_PremierLeague
	train test
	train test England_PremierLeague
]]

return setmetatable(_M, { __call = function (this, ...)
	local query = ...
	if query == "--help" then
		-- display help
		print(_HELP)
		return true
	else
		local confkey, dirkey
		local args = {...}
		if args[1] == "test" then
			confkey = "analysis.train.test.matchset"
			dirkey = "analysis.train.test.dir"
			table.remove(args, 1)
		else
			confkey = "analysis.train.matchset"
			dirkey = "analysis.train.dir"
		end
		local matchsetconstraints
		local matchsetname = args[1]
		if matchsetname then
			matchsetconstraints = config.get(_G._conf, confkey.."."..matchsetname)
		else
			matchsetconstraints = config.get(_G._conf, confkey)
		end
		if not matchsetconstraints then
			return nil, "Matchset "..confkey..(matchsetname and "."..matchsetname or "").." not found in configuration"
		end
		local matchsets
		if type(matchsetconstraints) == "string" then
			matchsets = {[matchsetname] = matchsetconstraints}
		else
			assert(type(matchsetconstraints) == "table", "Expected table, got "..type(matchsetconstraints))
			matchsets = matchsetconstraints
		end

		local nepochs = config.get(_G._conf, "analysis.train.epochs") 
		local traindir = lfs.concatfilenames(config.get(_G._conf, dirkey), os.date("%y-%m-%d_%H%M"))

		local matchsetnames = {}
		for matchsetname in pairs(matchsets) do
			table.insert(matchsetnames, matchsetname)
		end
		table.sort(matchsetnames)
		log.info(_NAME..": neural networks directory "..traindir)
		for _, matchsetname in ipairs(matchsetnames) do
			matchsetconstraints = config.get(_G._conf, confkey.."."..matchsetname)
			log.info(_NAME..": training matchset "..matchsetconstraints)
			local trn = trainer.new(matchsetname, traindir)
			local ms = matchset.new(_G._dbc)
			assert(ms:filterbyconstraints(matchsetconstraints))
			local matchsrc = assert(ms:source())
			assert(trn:addsource(matchsrc))
			trn:train(nepochs)
		end
		return true
	end
end})
