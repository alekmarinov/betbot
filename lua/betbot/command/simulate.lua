-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2012,  AVIQ Systems AG                              --
--                                                                   --
-- Project:       LRun                                               --
-- Filename:      simulate.lua                                         --
-- Description:   Simulate command                                     --
--                                                                   --
-----------------------------------------------------------------------

local config   = require "lrun.util.config"

local _G, table, setmetatable, print, require =
      _G, table, setmetatable, print, require

local simulator = require "betbot.simulation.simulator"

module "betbot.command.simulate"

_NAME = "simulate"
_DESCRIPTION = "Simulates different strategies"
_HELP =
[[

SYNTAX: simulate matchsetname strategy

uses analysis.simulate.dir, analysis.strategy.package
]]

return setmetatable(_M, { __call = function (this, ...)
	local query = ...
	if query == "--help" then
		-- display help
		print(_HELP)
		return true
	else
		local matchsetname, strategyname = ...
		local simdir = config.get(_G._conf, "analysis.simulate.dir")
		local package = config.get(_G._conf, "analysis.strategy.package")
		local strategy = require(package.."."..strategyname)
		local sim = simulator.new(_G._dbc, matchsetname, simdir)
		return sim:simulate(strategy)
	end
end})
