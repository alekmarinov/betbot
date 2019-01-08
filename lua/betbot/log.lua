-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2009,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      logging.lua                                         --
-- Description:   BetBot logging module                              --
--                                                                   --
-----------------------------------------------------------------------

local smtp = require "socket.smtp"
local config = require "lrun.util.config"

require "logging.console"
require "logging.file"
require "logging.email"

-----------------------------------------------------------------------
-- class definition ---------------------------------------------------
-----------------------------------------------------------------------
module ("betbot.log", package.seeall)

local isinit = false
local appenders = {}
local useropts = {}

local function newconsole()
	return logging.console()
end

local function newfile()
	return assert(logging.file(config.get(_conf, "log.file.name")))
end

local function newemail()
	return logging.email{
		from=config.get(_conf, "log.email.from"),
		rcpt=config.get(_conf, "log.email.rcpt"),
		headers = {
			subject = config.get(_conf, "log.email.subject")
		}
	}
end

function setlevel(appender, level)
	appenders[appender]:setLevel(level)
end

function setverbosity(isquiet, isverbose)
	useropts.isquiet = isquiet
	useropts.isverbose = isverbose
end

function log(level, message, ...)
	if not isinit then
		isinit = true

		-- create console appender
		appenders.console = newconsole()
		
		if not _conf then
			if message then				
				warn("Log: No configuration supplied")
			end
		else
			-- create file appender
			appenders.file = newfile()

			if useropts.isquiet then
				appenders.console:setLevel(logging.FATAL)
				appenders.file:setLevel(logging.FATAL)
			else
				if useropts.isverbose then
					appenders.console:setLevel(logging.DEBUG)
					appenders.file:setLevel(logging.DEBUG)
				else
					appenders.console:setLevel(string.upper(config.get(_conf, "log.console.verbosity")))
					appenders.file:setLevel(string.upper(config.get(_conf, "log.file.verbosity")))
				end
			end

			-- email appender setup
			smtp.SERVER=config.get(_conf, "log.email.smtp.host")
			smtp.PORT=config.get(_conf, "log.email.smtp.port")
			smtp.TIMEOUT=config.get(_conf, "log.email.smtp.timeout")
			appenders.email = newemail(config)
			appenders.email:setLevel(string.upper(config.get(_conf, "log.email.verbosity")))
		end
	end

	assert(table.getn({...}) == 0)
	for name, appender in pairs(appenders) do
		if message then
			appender[string.lower(level)](appender, message)
		end
	end
	return true
end

function debug(message, ...) log(logging.DEBUG, message, ...) end
function sql(message, ...) log(logging.SQL, message, ...) end
function info(message, ...) log(logging.INFO, message, ...) end
function warn(message, ...) log(logging.WARN, message, ...) end
function error(message, ...) log(logging.ERROR, message, ...) end
function fatal(message, ...) log(logging.FATAL, message, ...) end

return _M
