-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2010, AVIQ Systems AG                          --
--                                                                   --
-- Project:       LRun                                               --
-- Filename:      TestValidator.lua                                  --
-- Description:   Tests LRun db connector                            --
--                                                                   --
-----------------------------------------------------------------------

local log             = require "betbot.log"
local filtervalidator = require "betbot.import.filter.validator"
local sinklog         = require "betbot.import.sink.log"
local sinkdb          = require "betbot.import.sink.database"

local db              = require "lrun.model.db"
local table           = require "lrun.util.table"
local stream          = require "lrun.stream.all"
local filter          = stream.sink.filter
local demux           = stream.sink.demux
local pump            = stream.pump.all
local cat             = stream.source.cat

require "luaunit"

module ("TestSink", package.seeall)

RECREATE_DB = false

local testdata1 = {
	{
		location = "England",
		provider = "sitename"
	},
	{
		competition = {
			location = "England",
			competition = "Premier Division",
		},
		provider = "sitename"
	},
	{
		bookmaker = {
			bookmaker = "bet365",
			website = "www.bet365.com"
		},
		provider = "sitename"
	},
	{
		team = {
			location = "England",
			team = "Liverpool"
		},
		provider = "sitename"
	},
	{
		match = {
			location = "England",
			competition = "Premier Division",
			team1 = "Liverpool",
			team2 = "Chelsea",
			goals1 = 1,
			goals2 = 0,
			date = "2010-09-01 20:31"
		},
		provider = "sitename"
	},
	{
		odds = {
			bookmaker = "bet365",
			match = {
				location = "England",
				competition = "Premier Division",
				team1 = "Liverpool",
				team2 = "Chelsea",
				goals1 = 1,
				goals2 = 0,
				date = "2010-09-01 20:31"
			},
			oddhome = 2.9,
			odddraw = 3.1,
			oddaway = 1.6
		},
		provider = "sitename"
	}
}

local testdata2 = {
	{
		location = "France",
		provider = "sitename"
	},
	{
		competition = {
			location = "France",
			competition = "Ligue 1",
		},
		provider = "sitename"
	},
	{
		bookmaker = {
			bookmaker = "bet365",
			website = "www.bet365.com"
		},
		provider = "sitename"
	},
	{
		team = {
			location = "France",
			team = "Lyon"
		},
		provider = "sitename"
	},
	{
		match = {
			location = "France",
			competition = "Ligue 1",
			team1 = "Lyon",
			team2 = "Auxerre",
			goals1 = 3,
			goals2 = 2,
			date = "2010-09-02 20:31"
		},
		provider = "sitename2"
	},
	{
		odds = {
			bookmaker = "bet365",
			match = {
				location = "France",
				competition = "Ligue 1",
				team1 = "Lyon",
				team2 = "Auxerre",
				goals1 = 3,
				goals2 = 2,
				date = "2010-09-02 20:31"
			},
			oddhome = 3,
			odddraw = 2,
			oddaway = 1
		},
		provider = "sitename"
	},
	{
		odds = {
			bookmaker = "sportingbet",
			match = {
				location = "France",
				competition = "Ligue 1",
				team1 = "Lyon",
				team2 = "Auxerre",
				goals1 = 3,
				goals2 = 2,
				date = "2010-09-02 20:31"
			},
			oddhome = 2.7,
			odddraw = 1.4,
			oddaway = 1.1
		},
		provider = "sitename2"
	}
}

function setUp()
	-- shut up logging
	log.info()
	--log.setlevel("console", "SILENT")

	if RECREATE_DB then
		os.remove("test.db")
		os.execute("echo .quit | sqlite3 -init ../../../../data/db/betbot_sqlite.sql test.db")
		os.execute("echo .quit | sqlite3 test.db \"INSERT INTO Provider (title) VALUES ('sitename')\"")
		os.execute("echo .quit | sqlite3 test.db \"INSERT INTO Provider (title) VALUES ('sitename2')\"")
	end

	_dbc = assert(db.new{
		driver = "sqlite",
		database = "test.db"
	})
end

function tearDown()
	assert(_dbc:close())
	collectgarbage()
end

function tablesource(t)
	local iter = table.elementiterator(t)
	return function ()
		return iter()
	end
end

function testValidator()
	ltn12.pump.all(tablesource(testdata1), filtervalidator)
end

function testLog()
	ltn12.pump.all(filter(filtervalidator, tablesource(testdata1)), sinklog("info"))
end

function testDB()
	pump(
		filter(filtervalidator, cat(tablesource(testdata1), tablesource(testdata2))),
		demux(sinklog("debug"), sinkdb(_dbc))
	)
end

LuaUnit:run("TestSink")
