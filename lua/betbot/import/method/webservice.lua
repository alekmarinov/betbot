-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2010,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      webservice.lua                                     --
-- Description:   Web Service client interface                       --
--                                                                   --
-----------------------------------------------------------------------

require "soap.http"
local log = require "betbot.log" 

module ("betbot.import.method.webservice", package.seeall)

function call(url, baseurl, method, params)
	local wsparams = {""}
	if params then
		wsparams = {}
		for name, value in pairs(params) do
			table.insert(wsparams, {tag = "m:"..name, value})
		end
	end

	log.debug("Contacting "..url.." with method "..method)
	local ok, err, entries = soap.http.call(url, baseurl, method, {tag="body", unpack(wsparams)})
	if not ok then
		return nil, err
	end
	if not entries[1] then
		return nil, "response is empty"
	end
	return entries[1]
end
