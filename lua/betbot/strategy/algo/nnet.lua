-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2009,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      nnet.lua                                           --
-- Description:   Neural Network strategy                            --
--                                                                   --
-----------------------------------------------------------------------

local lfs       = require "lrun.util.lfs"
local Predictor = require "betbot.strategy.algo.nnet.predictor"

module ("betbot.strategy.nnet", package.seeall)

local predictor

-- args: trainset - 25, 50, 75 or 100 (default 100 if nil)
-- expected tables - Match_First<trainset>, Match_Last<trainset>, using Match if trainset=100
return function (home, draw, away, tid1, tid2, trainset)
	predictor = predictor or Predictor.new(_dbc)
	local result = predictor:predict(home, draw, away, tid1, tid2, trainset)
	if result then
		if result == 1 then
			return {result, away}
		elseif result == 2 then
			return {result, home}
		else
			return {result, draw}
		end
	end
end
