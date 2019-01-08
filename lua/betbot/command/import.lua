-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2010,  AVIQ Systems AG                              --
--                                                                   --
-- Project:       LRun                                               --
-- Filename:      import.lua                                         --
-- Description:   Import command                                     --
--                                                                   --
-----------------------------------------------------------------------

local table, setmetatable, print =
      table, setmetatable, print

local importer = require "betbot.import.importer"

module "betbot.command.import"

_NAME = "import"
_DESCRIPTION = importer._DESCRIPTION
_HELP = importer._HELP

return setmetatable(_M, { __call = function (this, ...)
	local expr = table.concat({...}, " ")
	if expr == "--help" then
		-- display help
		print(_HELP)
		return true
	else
		return importer(expr)
	end
end})
