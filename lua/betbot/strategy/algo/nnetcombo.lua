-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2009,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      nnetcombo.lua                                      --
-- Description:   Bet on higher odd when higher - draw < lower
--                using Neural Network predictor                    --
--                and lower is not higher than a limit               --
--                                                                   --
-----------------------------------------------------------------------

local lfs       = require "lrun.util.lfs"
local Predictor = require "betbot.strategy.algo.nnet.predictor"

module ("betbot.strategy.nnetcombo", package.seeall)

local predictor

-- args: trainset - 25, 50, 75 or 100 (default 100 if nil)
-- expected tables - Match_First<trainset>, Match_Last<trainset>, using Match if trainset=100
return function (home, draw, away, tid1, tid2, trainset, limit)
	limit = tonumber(limit)
	if math.min(home, away) > math.max(home, away) - draw and math.min(home, away) < limit then
		predictor = predictor or Predictor.new(_dbc)
		local result = predictor:predict(home, draw, away, tid1, tid2, trainset)
		if result then
			if result == 1 then
				return {1, away}
			elseif result == 2 then
				return {1, home}
			else
				return {"X", draw}
			end
		end
	end
end
