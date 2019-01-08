-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2010,  AVIQ Systems AG                              --
--                                                                   --
-- Project:       LRun                                               --
-- Filename:      main.lua                                           --
-- Description:   Main interface to betbot tool                      --
--                                                                   --
-----------------------------------------------------------------------

local db          = require "lrun.model.db"
local lfs         = require "lrun.util.lfs"
local config      = require "lrun.util.config"
local log         = require "betbot.log"
local Const       = require "betbot.constants"
local simulation  = require "betbot.strategy.simulation"
local trainer     = require "betbot.strategy.algo.nnet.trainer"
local predictor   = require "betbot.strategy.algo.nnet.predictor"
local bookmaker   = require "betbot.model.bookmaker"
local competition = require "betbot.model.competition"
local matchselect = require "betbot.gui.console.selectmatch"
local commands =
{
	import    = require "betbot.command.import",
	select    = require "betbot.command.select",
	train     = require "betbot.command.train",
	predict   = require "betbot.command.predict",
	update    = require "betbot.command.update",
	simulate  = require "betbot.command.simulate",
}

module ("betbot.main", package.seeall)

_NAME = "BetBot"
_VERSION = "0.5"
_DESCRIPTION = "BetBot is a soccer bets advisor"

local appwelcome = _NAME.." ".._VERSION.." Copyright (C) 2006-2010 AVIQ Bulgaria Ltd"
local usagetext = "Usage: ".._NAME.." [OPTION]... COMMAND [ARGS]..."
local usagetexthelp = "Try ".._NAME.." --help' for more options."
local errortext = _NAME..": %s"
local helptext = [[
-c   --config CONFIG  config file path (default betbot.conf)
-q   --quiet          no output messages
-v   --verbose        verbose messages
-h,  --help           print this help.

where COMMAND can be one below:

PREDICT matchsetname team1 team2 oddhome odddraw oddaway
  Predicts match exit based on trained nnet file

UPDATE [date_from [date_to] ]
  Updates local DB, where dates must be formated as YYYY-mm-DD

SIM[ULATE]
  Perform betting simulation
  (uses selected competitions and algorithms from the config file)

TRAIN
  Train neural networks
  (uses selected competitions from the config file)

IMPORT [smarterbetting|soccerstand] [bookmakers|locations|competitions|teams|matches]
  Imports recent data from www.smarterbetting.com or www.soccerstand.com

EXPORT output_file
  Exports local DB to XML file

SELECT <query>
   Display specified matchset by query
]]

--- exit with usage information when the application arguments are wrong 
local function usage(errmsg)
    assert(type(errmsg) == "string", "expected string, got "..type(errmsg))
    io.stderr:write(string.format(usagetext, errmsg).."\n\n")
    io.stderr:write(usagetexthelp.."\n")
    os.exit(1)
end

--- exit with error message
local function exiterror(errmsg)
    assert(type(errmsg) == "string", "expected string, got "..type(errmsg))
    io.stderr:write(string.format(errortext, errmsg).."\n")
    os.exit(1)
end

-----------------------------------------------------------------------
-- Setup prorgam start ------------------------------------------------
-----------------------------------------------------------------------

--- parses program arguments
local function parseoptions(...)
	local opts = {}
	local args = {...}
	local err
	local i = 1
	while i <= #args do
		local arg = args[i]
		if not opts.command then
			if arg == "-h" or arg == "--help" then
				io.stderr:write(appwelcome.."\n")
				io.stderr:write(usagetext.."\n\n")
				io.stderr:write(helptext)
				os.exit(1)
			elseif arg == "-c" or arg == "--config" then
				i = i + 1
				opts.config = args[i]
				if not opts.config then
					exiterror(arg.." option expects parameter")
				end
			elseif arg == "-v" or arg == "--verbose" then
				opts.verbose = true
				if opts.quiet then
					exiterror(arg.." cannot be used together with -v")
				end
			elseif arg == "-q" or arg == "--quiet" then
				opts.quiet = true
				if opts.verbose then
					exiterror(arg.." cannot be used together with -q")
				end
			else
				opts.command = {string.lower(arg)}
			end
		else
			table.insert(opts.command, arg)
		end
		i = i + 1
	end
	if not opts.command then
		usage("Missing parameter COMMAND")
	end

	--- set program defaults
	opts.config = opts.config or "betbot.conf"
	return opts
end


-----------------------------------------------------------------------
-- Entry Point --------------------------------------------------------
-----------------------------------------------------------------------

function main(...)
	local args = {...}

	-- parse program options
	local opts = parseoptions(...)

	-- load configuration
	if not lfs.isfile(opts.config) then
		exiterror("Config file `"..opts.config.."' is missing")
	end
	-- load configuration and set it globaly
	if not opts.quiet then
		print(_NAME..": loading configuration")
	end
	local err
	_G._conf, err = config.load(opts.config)
	if not _G._conf then
		exiterror(err)
	end

	-- set logging verbosity
	log.setverbosity(opts.quiet, opts.verbose)

	-- initialize database
	_G._dbc = assert(db.new{
		driver = config.get(_conf, "db.driver"),
		database = config.get(_conf, "db.database")
	})

	Const.init(_dbc)

	local cmdname = table.remove(opts.command, 1):lower()
	log.info(_NAME.." started with command "..cmdname:lower().." "..table.concat(opts.command, " "))
	local ok, err
	--[[
	if cmdname == "predict" then
		if #opts.command == 0 then
			ok, err = matchselect.menu()
		elseif #opts.command == 6 then
			ok, err = predictor.predict(unpack(opts.command))
			print(unpack(ok))
		else
			err = "predict command require 0 or 6 arguments, try predict --help"
		end
	if cmdname == "simulate" or cmdname == "sim" then
		ok, err = simulation.simulate(unpack(opts.command))
		elseif cmdname == "train" then
		ok, err = trainer.train(unpack(opts.command))
		
	else--]]if cmdname == "export" then
		ok, err = exporters.smarterbetting.export(unpack(opts.command))
	elseif commands[cmdname] then
		ok, err = commands[cmdname](unpack(opts.command))
	else
		exiterror("Unknown command "..cmdname)
	end
	if not ok then
		exiterror(err)
	end
end
