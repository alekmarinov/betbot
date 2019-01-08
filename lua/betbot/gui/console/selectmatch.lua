-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2009,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      selectmatch.lua                                    --
-- Description:   Select match menu                                  --
--                                                                   --
-----------------------------------------------------------------------

local Menu        = require "betbot.gui.console.menu"
local config      = require "lrun.util.config"
local string      = require "lrun.util.string"
local competition = require "betbot.model.competition"
local match       = require "betbot.model.match"
local team        = require "betbot.model.team"
local Predictor   = require "betbot.strategy.algo.nnet.predictor"

module ("betbot.gui.console.selectmatch", package.seeall)

local function about_dialog()
  io.write [[

Neural Network based prediction. 
The network model have the following input:
<norm_odd_home> <norm_odd_draw> <norm_odd_away> 0|1 0|1 0|1 ..  0|1

where

norm_odd_home = odd_away / (odd_home + odd_draw + odd_away)
norm_odd_draw = odd_draw / (odd_home + odd_draw + odd_away)
norm_odd_away = odd_home / (odd_home + odd_draw + odd_away)

and 0|1 0|1 0|1 ..  0|1 is a sequence of all teams
1 - if the team participate in the match, 0 otherwise

The normed odds represent sort of result probabilities
as predicted by the bookmaker. Norming also play a role
of odd abstraction by arbitrary bookmakers.
The network is trained with data provided by 365stats.com,
while you may try suppling odds by your bookmaker!

]]
  return "About menu"
end

local function askodd(msg)
	while true do
		io.write(msg..":") io.flush()
		local choice = tonumber(io.read("*l"))
		if not choice then
			print("Odd must be a number")
		elseif choice < 0 then
			print("Odd must be a positive")
		else
			return choice
		end
	end
end

function menu()

	local mainMenu = Menu.new "Top"
	local team1Menu = mainMenu.sub "Team 1"
	local team2Menu = mainMenu.sub "Team 2"

	local ID_EXIT

	for teamno, teammenu in ipairs{team1Menu, team2Menu} do
		-- create competitions from configuration
		local competitions = {}
		local dummy
		for location, compets in pairs(config.get(_conf, "competitions")) do
			local locMenu = teammenu.sub(location) 
			for _, compet in ipairs(string.explode(compets, ",")) do
				local compMenu = locMenu.sub(compet)
				local comp = competition.load(_dbc, compet)
				local teams = match.getteamsbycompetition(_dbc, comp)
				for i, id in ipairs(teams) do
					local tm = team.load(_dbc, id)
					compMenu.add(tm.title, tm.title.." for team "..teamno)
				end
				dummy = compMenu.super
			end
			dummy = locMenu.super
		end
		dummy = teammenu.super
	end

	mainMenu.super
		.add("Odd Home", "odd_home")
		.add("Odd Draw", "odd_draw")
		.add("Odd Away", "odd_away")
		.add("Predict", "predict")
		.sep.add("Exit", ID_EXIT)

	local home, draw, away, team1ID, team2ID, team1name, team2name
	local predictor = Predictor.new(_dbc)
	while true do
		print(string.format("selected %s-%s [%.2f/%.2f/%.2f]",
			  team1name or "?", team2name or "?", home or 0, draw or 0, away or 0))

		local selection = mainMenu.run()
		if not selection then break end

		if selection == "predict" then
			local skip
			if not team1ID then
				print("Please select Team 1")
				skip = true
			end
			if not team2ID then
				print("Please select Team 2")
				skip = true
			end
			if not home then
				print("Please select Odd Home")
				skip = true
			end
			if not draw then
				print("Please select Odd Draw")
				skip = true
			end
			if not away then
				print("Please select Odd Away")
				skip = true
			end
			if not skip then
				local result = predictor:predict(home, draw, away, team1ID, team2ID, 100)
				if not result then
					print("Sorry, I don't know!")
				else
					print(string.format("\n--> %s-%s [%.2f/%.2f/%.2f] will finish %s <<-\n",
						  team1name, team2name, home, draw, away, tostring(result)))
				end
			end
		elseif selection == "odd_home" then
			home = askodd("Type odd for home team 1")
		elseif selection == "odd_draw" then
			draw = askodd("Type odd for draw")
		elseif selection == "odd_away" then
			away = askodd("Type odd for away team 2")
		else
			local teamno = tonumber(selection:sub(selection:len()))
			local teamname = selection:sub(1, selection:len() - (" for team "..teamno):len())
			if teamno == 1 then
				team1ID = assert(team.load(_dbc, teamname), "No such team "..teamname).id
				team1name = teamname
			elseif teamno == 2 then
				team2ID = assert(team.load(_dbc, teamname), "No such team "..teamname).id
				team2name = teamname
			else
				assert(nil, "teamno can't be "..teamno)
			end
		end
	end

	return true
end

return _M
