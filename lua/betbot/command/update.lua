-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2010,  AVIQ Systems AG                              --
--                                                                   --
-- Project:       LRun                                               --
-- Filename:      update.lua                                         --
-- Description:   Update command                                     --
--                                                                   --
-----------------------------------------------------------------------

local config   = require "lrun.util.config"

local _G, table, setmetatable, print =
      _G, table, setmetatable, print

local importer = require "betbot.import.importer"

module "betbot.command.update"

_NAME = "update"
_DESCRIPTION = "Updates local database with providers data"
_HELP =
[[

SYNTAX: update

uses update.expression, db.sink.database
]]

return setmetatable(_M, { __call = function (this, ...)
	local query = ...
	if query == "--help" then
		-- display help
		print(_HELP)
		return true
	else
		return importer(config.get(_G._conf, "update.expression"))
	end
end})
