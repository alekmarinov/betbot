-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2012,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      nnet.lua                                           --
-- Description:   Neuron network based strategy                      --
--                                                                   --
-----------------------------------------------------------------------

local matchset  = require "betbot.analysis.matchset"
local predictor = require "betbot.nnet.predictor"
local config    = require "lrun.util.config"
local lfs       = require "lrun.util.lfs"
local log       = require "betbot.log" 

module ("betbot.strategy.nnet", package.seeall)

_NAME="nnet"

local function normalizeodds(h, d, a)
	h = tonumber(h)
	d = tonumber(d)
	a = tonumber(a)
	local sum = h + d + a
	return {math.floor(100 * h / sum) / 100, math.floor(100 * d / sum) / 100, math.floor(100 * a / sum) / 100}
end

function new(matchsetname)
	local ms = matchset.new(_G._dbc)
	local matchsetconstraints = config.get(_G._conf, "analysis.simulate.matchset."..matchsetname)
	if not matchsetconstraints then
		return nil, "matchset `analysis.simulate.matchset."..matchsetname.."' constraint required in order to perform prediction"
	end
	local results = {}
	local traindir = config.get(_G._conf, "analysis.train.test.dir")
	log.info(_NAME..": loading neural networks from "..traindir)

	local predictors = {}
	local netdirs = {}
	for dirname in lfs.dir(traindir) do
		local netfilename = lfs.concatfilenames(traindir, dirname, matchsetname)..".net"
		local prd = assert(predictor.new(_G._dbc, netfilename, matchsetconstraints))
		table.insert(predictors, prd)
		table.insert(netdirs, dirname)
	end

	return function(team1, team2, oddhome, odddraw, oddaway)
		local nodds = normalizeodds(oddhome, odddraw, oddaway)
		local cnt, sum, sum2 = 0, 0, 0
		for i, prd in ipairs(predictors) do
			local out = unpack(assert(prd:predict(team1, team2, oddhome, odddraw, oddaway)))
			log.debug(_NAME..": "..netdirs[i].."/"..matchsetname..string.format("%6.2f", out))
			sum = sum + out
			sum2 = sum2 + out*out
			cnt = cnt + 1
		end
		local avg, dev = sum/cnt, math.sqrt(sum2)/cnt
		log.debug(_NAME..": "..string.format("%.2f average, %.2f deviance", avg, dev))

		assert(nil, "fix me!!!")

-- funny but this one if good -2% after 2012
--[[
			if avg < 0.20 then
				return {"1", 1+nodds[3]}
			elseif avg > -0.35 then
				return {"2", 1+nodds[1]}
			end
			return {"X", 1+nodds[2]}
--]]

		--if dev < 0.35 then
			if avg > 0.35 then
				return {"1", 1+nodds[3]}
			elseif avg < -0.35 then
				return {"2", 1+nodds[1]}
			end
			return {"X", 1+nodds[2]}
		--[[
		else
			if avg > 0.35 then
				return {"1", 1+nodds[3]}
			elseif avg < -0.4 then
				return {"2", 1+nodds[1]}
			end
		end
		--]]
	end
end
