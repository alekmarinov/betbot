-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2010,  AVIQ Systems AG                              --
--                                                                   --
-- Project:       LRun                                               --
-- Filename:      predict.lua                                        --
-- Description:   Predicts match exit based on trained nnet file     --
--                                                                   --
-----------------------------------------------------------------------

require "lrun.stream.all"
local matchset  = require "betbot.analysis.matchset"
local predictor = require "betbot.nnet.predictor"
local trainer   = require "betbot.nnet.trainer"
local config    = require "lrun.util.config"
local log       = require "betbot.log"
local lfs       = require "lrun.util.lfs"

local _G, lrun, assert, print, tonumber, select, unpack, setmetatable, table, math, string, pairs, ipairs, setfenv, loadstring =
      _G, lrun, assert, print, tonumber, select, unpack, setmetatable, table, math, string, pairs, ipairs, setfenv, loadstring

module "betbot.command.predict"

_NAME = "predict"
_DESCRIPTION = "Predicts match exit based on trained nnet file"
_HELP =
[[

SYNTAX: predict matchsetname team1 team2 oddhome odddraw oddaway

EXAMPLES:

	predict England_PremierLeague "West Ham" Arsenal 4.33 3.5 1.83
]]

return setmetatable(_M, { __call = function (this, ...)
	local query = ...
	if query == "--help" then
		-- display help
		print(_HELP)
		return true
	else
		local nargs = table.getn{...}
		assert(nargs == 6, "predict requires 6 parameters, got "..nargs..". Try --help")

		local matchsetname = query
		local ms = matchset.new(_G._dbc)
		local matchsetconstraints = config.get(_G._conf, "analysis.train.matchset."..matchsetname)
		if not matchsetconstraints then
			return nil, "matchset `analysis.train.matchset."..matchsetname.."' constraint required in order to perform prediction"
		end

		local traindir = config.get(_G._conf, "analysis.train.dir")
		log.info(_NAME..": neural networks directory "..traindir)
		local cnt, sum, dev = 0, 0, 0
		for dirname in lfs.dir(traindir) do
			local netfilename = lfs.concatfilenames(traindir, dirname, matchsetname)..".net"
			local prd, err = predictor.new(_G._dbc, netfilename, matchsetconstraints)
			if prd then
				local out = unpack(assert(prd:predict(select(2, ...))))
				log.info(_NAME..": "..dirname.."/"..matchsetname..string.format("%6.2f", out))
				sum = sum + out
				dev = dev + out*out
				cnt = cnt + 1
			else
				log.error(err)
			end
		end
		log.info(_NAME..": "..string.format("%.2f average, %.2f deviance", sum/cnt, math.sqrt(dev)/cnt))
		return true
	end
end})
