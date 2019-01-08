-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2010,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      downloadfile.lua                                   --
-- Description:   Implements downloading method                      --
--                                                                   --
-----------------------------------------------------------------------

local http     = require "socket.http"
local table    = require "table"
local string   = require "string"
local log      = require "betbot.log" 
local lfs      = require "lrun.util.lfs"
local curl     = require "luacurl"
local http     = require "socket.http"
local io       = require "io"
local os       = require "os"

local assert, type, tonumber = assert, type, tonumber

-----------------------------------------------------------------------
-- class definition ---------------------------------------------------
-----------------------------------------------------------------------
module "betbot.import.method.download"

-----------------------------------------------------------------------
-- default attributes -------------------------------------------------
-----------------------------------------------------------------------

-- specifies downloading method (see downloadmethods)
method  = "socket"

-- connect timeout in seconds
connect_timeout = 120

-- wget settings
wget_support_connect_timeout = true

-----------------------------------------------------------------------
-- local definitions  -------------------------------------------------
-----------------------------------------------------------------------

local function Q(arg)
   assert(type(arg) == "string")

   return "\"" .. arg:gsub("\\", "\\\\"):gsub("\"", "\\\"") .. "\""
end

local downloadmethods = {
	socket = function(url, filename, progresscb, timeout)
		local result = {}

		local user_agent = "Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US; rv:1.9.2.6) Gecko/20100625 Firefox/3.6.6 ( .NET CLR 3.5.30729; .NET4.0C)"
		local sendheaders =
		{
			["user-agent"] = user_agent,
			["accept-charset"] = "ISO-8859-1,utf-8;q=0.7,*;q=0.7",
			["content-type"] = "application/x-www-form-urlencoded",
			["accept-language"] = "en-us,en;q=0.5",
			["accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
			["keep-alive"] = "115"
		}

		local ok, code, headers, err = http.request
		{
			method = "HEAD",
			url = url,
			headers = sendheaders
		}
		if tonumber(code)~= 200 then
			return nil, err or code
		end
		local file
		if filename then
			file, err = io.open(filename, "wb")
			if not file then
				return nil, err
			end
		end
		local totalsize = headers["content-length"]
		local downloadedsize = 0
		local timenow = os.time()
		local lastspeed
		ok, code, headers, err = http.request
		{
			method = "GET",
			url = url,
			sink = function(chunk)
				if chunk then
					if file then
						file:write(chunk)
					else
						table.insert(result, chunk)
					end
					if progresscb then
						downloadedsize = downloadedsize + chunk:len()
						local speed = 0
						local elapsed = os.time() - timenow
						if elapsed > 0 then
							speed = downloadedsize / elapsed
						end
						local fract = totalsize and downloadedsize/totalsize or 0
						if fract < 0.001 then
							fract = 0
						end
						lastspeed = speed
						progresscb(fract, speed)
					end
				end
				return 1
			end,
			headers = sendheaders
		}
		if tonumber(code) ~= 200 then
			return nil, err or code
		end
		if progresscb then
			progresscb(1, lastspeed)
		end
		if file then
			file:close()
			return true
		else
			return table.concat(result)
		end
	end,
	luacurl = function(url, filename, progresscb, timeout)
		local c = curl.new()
		local timenow = os.time()
		local result = {}
		if progresscb then
			c:setopt(curl.OPT_PROGRESSFUNCTION,
				function (_, dltotal, dlnow)
					local fract = dlnow/dltotal
					local speed = 0
					local elapsed = os.time() - timenow
					if elapsed > 0 then
						speed = dlnow / elapsed
					end
					if fract < 0.001 then
						fract = 0
					end
					progresscb(fract, speed)
				end)
			c:setopt(curl.OPT_NOPROGRESS, false)
		end
		c:setopt(curl.OPT_CONNECTTIMEOUT, timeout)
		c:setopt(curl.OPT_WRITEFUNCTION, function (fd, buffer)
			if fd then
				return fd:write(buffer) and string.len(buffer) or 0
			else
				table.insert(result, buffer)
				return string.len(buffer)
			end
		end)
		local ok, file, err
		if filename then
			file, err = io.open(filename, "wb")
			if file then
				c:setopt(curl.OPT_WRITEDATA, file)
			else
				err = "Unable to write in file `"..filename.."' ("..(err or "")..")"
			end
		end
		c:setopt(curl.OPT_URL, url)
		c:setopt(curl.OPT_FAILONERROR, true)
		ok, err = c:perform()
		if file then
			file:close()
		end
		if not ok then
			log.error("download: "..err)
			return nil, err
		else
			if filename then
				return true
			else
				return table.concat(result)
			end
		end
	end,
	wget = function(url, filename, progresscb, timeout)
		assert(type(filename) == "string", "filename string expected, got "..type(filename))
		local cmdtimeout
		if wget_support_connect_timeout then
			cmdtimeout = "--connect-timeout="..timeout
		else
			cmdtimeout = ""
		end
		return lfs.execute("wget --quiet "..cmdtimeout.." --output-document", filename, url)
	end,
	curl = function(url, filename, progresscb, timeout)
		assert(type(filename) == "string", "filename string expected, got "..type(filename))
		return lfs.execute("curl -f --connect-timeout "..timeout.." "..Q(url).." 2> /dev/null 1> "..Q(filename))
	end
}

-----------------------------------------------------------------------
-- public methods  ----------------------------------------------------
-----------------------------------------------------------------------

function downloadfile(url, filename, progresscb, timeout)
	assert(type(url) == "string")
	assert(type(filename) == "string" or not filename)
	assert(type(progresscb) == "function" or not progresscb)
	assert(type(timeout) == "number" or not timeout)
	timeout = timeout or connect_timeout

	local ok, err

	if filename then
		log.debug("Downloading `"..url.."' to `"..filename.."'")
		local dstdir = lfs.dirname(filename)
		if not lfs.isdir(dstdir) then
			ok, err = lfs.mkdir(dstdir)
			if not ok then
				return nil, err
			end
		end
	else
		log.debug("Downloading `"..url.."'")
	end

	ok, err = downloadmethods[method](url, filename, progresscb, timeout)

	if not ok then
		if filename then
			log.debug("Deleting `"..filename.."'")
			lfs.delete(filename)
		end
	else
		if filename then
			-- prevantive check if really ok (file size != 0)
			if lfs.filesize(filename) == 0 then
				log.debug("Downloaded file have zero size: `"..filename.."'")
				return true
			end
		end
		err = nil
	end
	return ok, err
end

function download(url, progresscb, timeout)
	return downloadfile(url, nil, progresscb, timeout)
end

return _M
