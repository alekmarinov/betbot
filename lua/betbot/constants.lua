-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2009,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      constants.lua                                      --
-- Description:   BetBot constants                                   --
--                                                                   --
-----------------------------------------------------------------------

local sqlds     = require "lrun.model.datasrc.sql"
local db        = require "lrun.model.db"
local log       = require "betbot.log" 
local bookmaker = require "betbot.model.bookmaker"
local team      = require "betbot.model.team"

module ("betbot.constants", package.seeall)

local ctables = {"Bookmaker", "Location", "Competition"}

function init(dbc)
	log.debug("Loading constant DB tables...")

	-- load simple tables
	for _, tab in ipairs(ctables) do
		_M[tab] = {}
		for row in assert(sqlds.new(dbc, "SELECT id, title FROM "..tab):source()) do
			_M[tab][string.upper(row.title)] = tonumber(row.id)
		end
	end
end

return _M
